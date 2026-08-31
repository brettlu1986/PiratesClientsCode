-----------------------------------------------------
--File Name    : LobbyOldSystem.lua
--Author       : Ran Jie
--Create Time  : 2019-07-02
--Description  : 大厅
-----------------------------------------------------
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local ItemSystem = require("ItemSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local AvatarDataTable = require("AvatarDataTable")
local SelfAnimationHelper = require("SelfAnimationHelper")
local TeamSystem = require("TeamSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local LobbyOldSystem = {}

local LobbyPlayerPositionDef =
{
    SINGLE_SELF = 0,
    POS_1 = 1,
    POS_2 = 2,
    POS_3 = 3,
    POS_4 = 4,

    MAX_POS = 5,
}

local LOBBY_PLAYER_POS_TAG =
{
    [LobbyPlayerPositionDef.SINGLE_SELF] = "LobbyCenter",
    [LobbyPlayerPositionDef.POS_1] = "LobbyPos1",
    [LobbyPlayerPositionDef.POS_2] = "LobbyPos2",
    [LobbyPlayerPositionDef.POS_3] = "LobbyPos3",
    [LobbyPlayerPositionDef.POS_4] = "LobbyPos4",
}

local tbTempRotation = Rotator()

LobbyOldSystem.tbTeamPlayers = {}
LobbyOldSystem.tbPlayerPos = {}

local function PlayShowAnimation(nAvatarId, pUEActor, bUseRandomPose)
    local tbAvatar = AvatarDataTable:GetTemplate(nAvatarId)
    --logdebug("LobbyOldSystem:PlayShowAnimation, nAvatarId,ShowAnimation=", nAvatarId)
    if tbAvatar and tbAvatar.szShowAnimation then
        pUEActor:ActivateRandomStandPose(bUseRandomPose)
        if not bUseRandomPose then
            SelfAnimationHelper:PlayActorAnimation(pUEActor, nAvatarId, tbAvatar.szShowAnimation)
        end
    end
end

local function _UpdateFashionCallback(self, nAvatarId, pHumanActor)
    EngineExtActorShell.SetActorSkeletalMeshLightChannel(pHumanActor, false, true, false)
end

local function OnSelfFashionChanged(self)
    local tbFashionItems = ItemSystem:GetEquippedFashionItems()
    local tbFashionIds = {}
    if tbFashionItems then
        for _, tbFashionItem in ipairs(tbFashionItems) do
            table.insert(tbFashionIds, tbFashionItem:GetTemplateId())
        end
    end
    local tbSelfObj = GamePlayerSelfHelper:Get()
    local LobbyPropertyComponent = tbSelfObj.LobbyPropertyComponent

    --logdebug("OnSelfFashionChanged,tbFashionIds,pSelfHumanActor=",tbFashionIds,pSelfHumanActor)
    if tbFashionIds and tbSelfObj.pUEActor and LobbyPropertyComponent then
        tbSelfObj.HumanAvatarComponent:ApplyBasicFashionItem(tbFashionIds)
    end
end

local function UpdateOtherPlayerFashion(self, nPlayerId, nAvatarId, tbFashionIds)
    local PlayerOther = self:GetTeamMemberPlayer(nPlayerId)
    if PlayerOther and tbFashionIds then
        PlayerOther.HumanAvatarComponent:ApplyBasicFashionItem(tbFashionIds)
    end
end

local function OnOtherPlayerSummaryChanged(self, tbSummary)
    UpdateOtherPlayerFashion(self, tbSummary.id, tbSummary.avatar_id, tbSummary.fashion)
end


local function FindEmptyPos(self, nPlayerId)
    local nSelfPlayerId = GamePlayerSelfHelper:Get():GetPlayerId()
    if nSelfPlayerId == nPlayerId then
        if TeamSystem:IsInTeam() then
            return LobbyPlayerPositionDef.POS_1
        else
            return LobbyPlayerPositionDef.SINGLE_SELF
        end
    elseif TeamSystem:IsTeamLeader(nPlayerId) then
        return LobbyPlayerPositionDef.POS_2
    else
        local nLeaderId = TeamSystem:GetTeamLeader()
        local nOtherPosIndex = LobbyPlayerPositionDef.POS_2
        if not TeamSystem:IsTeamLeader(nSelfPlayerId) and not self.tbTeamPlayers[nLeaderId] then
            nOtherPosIndex = LobbyPlayerPositionDef.POS_3
        end
        for i = nOtherPosIndex, LobbyPlayerPositionDef.MAX_POS - 1 do
            local bFind = false
            for k, v in pairs(self.tbPlayerPos) do
                if i == v then
                    bFind = true
                    break
                end
            end
            if not bFind then
                return i
            end
        end
    end
end

local function GetPosLocationAndRotation(nPosIndex)
    if not nPosIndex then
        return
    end
    local pPosActor = ExtendBlueprintFunctions.GetWorldActorByName(GWorld, LOBBY_PLAYER_POS_TAG[nPosIndex])
    if not pPosActor then
        return
    end
    local location = pPosActor:K2_GetActorLocation()
    local rotation = pPosActor:K2_GetActorRotation()
    return location, rotation
end

local function CreateTeamMemberPlayerObj(self, nPlayerId, nAvatarId, szName, tbFashionIds, tbAppearance)
    local nPosIndex = FindEmptyPos(self, nPlayerId)
    log("CreateTeamMemberPlayerObj,nPlayerId,nPosIndex=",nPlayerId,nPosIndex)
    local pLocation, pRotation = GetPosLocationAndRotation(nPosIndex)
    local X, Y, Z, Yaw = 0, 0, 0, 0
    if pLocation then
        X = pLocation.X
        Y = pLocation.Y
        Z = pLocation.Z
    end
    if pRotation then
        Yaw = pRotation.Yaw
    end
    local tbProtoData = {}
    local tbActorInfo = {}
    tbActorInfo.actor_id = nPlayerId
    tbActorInfo.template_id = nAvatarId
    tbActorInfo.human_move_data = {transform = {x = X, y = Y, z = Z, yaw = Yaw}}
    tbProtoData.actor = tbActorInfo
    local tbPlayerInfo = {}
    tbPlayerInfo.name = szName
    tbPlayerInfo.player_id = nPlayerId
    tbProtoData.player = tbPlayerInfo
    tbProtoData.human_fashion_ids = tbFashionIds
    tbProtoData.appearance = tbAppearance
    local tbPlayer = GameObjectSystem:CreatePlayerOtherInHub(tbProtoData, false)
    PlayShowAnimation(nAvatarId, tbPlayer.pUEActor, true)
    tbPlayer.pUEActor.CharacterMovement:SetComponentTickEnabled(false)
    self.tbPlayerPos[nPlayerId] = nPosIndex
    return tbPlayer
end

local function DestroyTeamMemberPlayerObj(self, nPlayerId)
    log("DestroyTeamMemberPlayerObj,nPlayerId=",nPlayerId)
    GameObjectSystem:DestroyPlayerOtherInHub(nPlayerId)
    self.tbPlayerPos[nPlayerId] = nil
end

local function OnPlayerSelfReady(self)
    local tbSelfObj = GamePlayerSelfHelper:Get()
    local nPlayerId = tbSelfObj:GetPlayerId()
    tbSelfObj.pUEActor.bUseControllerRotationYaw = false
    tbSelfObj.pUEActor.PlayerInputComponent:SetMoveEnabled(false)
    self.tbTeamPlayers[nPlayerId] = tbSelfObj
    self:MovePlayerTo(nPlayerId, LobbyPlayerPositionDef.SINGLE_SELF)
    OnSelfFashionChanged(self)
    local LobbyPropertyComponent = tbSelfObj.LobbyPropertyComponent
    if LobbyPropertyComponent then
        --logdebug("OnPlayerSelfReady,",LobbyPropertyComponent.nAvatarTemplateId)
        PlayShowAnimation(LobbyPropertyComponent.nAvatarTemplateId, tbSelfObj.pUEActor, true)
    end
    self:RefreshTeammate()
end

function LobbyOldSystem:Init()
    self.tbTeamPlayers = {}
    self.tbPlayerPos = {}
    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper
    if not GlobalVariableSystem.bEnterLobby3D then
        EventHelper:RegisterEvent(ClientEventDef.EV_EQUIP_LOBBY_FASHION, self, OnSelfFashionChanged)
        EventHelper:RegisterEvent(ClientEventDef.EV_UNEQUIP_LOBBY_FASHION, self, OnSelfFashionChanged)
        EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_MEMBER_SUMMARY_CHANGED, self, OnOtherPlayerSummaryChanged)
        EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_READY, self, OnPlayerSelfReady)
    end
    
    return true
end

function LobbyOldSystem:Uninit()
    self.EventHelper:UnregisterAll()
end

---------------------------------------------------------------------
function LobbyOldSystem:GetCenterPosition()
    local pLocation, pRotation = GetPosLocationAndRotation(LobbyPlayerPositionDef.SINGLE_SELF)
    return pLocation, pRotation
end

function LobbyOldSystem:AddTeammate(tbMemberData)
    local tbPlayer = CreateTeamMemberPlayerObj(self, tbMemberData.nPlayerId, tbMemberData.nAvatarId, tbMemberData.szName, tbMemberData.tbFashionIds, tbMemberData.tbAppearance)
    self.tbTeamPlayers[tbMemberData.nPlayerId] = tbPlayer
end

function LobbyOldSystem:RemoveTeammate(nPlayerId)
    DestroyTeamMemberPlayerObj(self, nPlayerId)
    self.tbTeamPlayers[nPlayerId] = nil
end

function LobbyOldSystem:RefreshTeammate()
    local tbTeamMemberUpdate = {}
    local nSelfPlayerId = GamePlayerSelfHelper:Get():GetPlayerId()
    log("LobbyOldSystem:RefreshTeammate,selfplayerid=",nSelfPlayerId,GamePlayerSelfHelper:Get():GetName())
    local tbTeamMemberIds = TeamSystem:GetTeamMemberIds()
    for k, v in ipairs(tbTeamMemberIds)do
        local tbMemberData = TeamSystem:GetTeamMemberData(v)
        local nPlayerId = tbMemberData.nPlayerId
        local nAvatarId = tbMemberData.nAvatarId
        local tbPlayer = self.tbTeamPlayers[nPlayerId]
        if nPlayerId ~= nSelfPlayerId then
            if not tbPlayer then
                self:AddTeammate(tbMemberData)
            end
            UpdateOtherPlayerFashion(self, nPlayerId, nAvatarId, tbMemberData.tbFashionIds)
        else
            self:MovePlayerTo(nPlayerId, LobbyPlayerPositionDef.POS_1)
        end
        tbTeamMemberUpdate[nPlayerId] = true
    end
    local tbRemovePlayerIds = {}
    for k, v in pairs(self.tbTeamPlayers) do
        if k ~= nSelfPlayerId and not tbTeamMemberUpdate[k] then
            table.insert(tbRemovePlayerIds, k)
        end
    end
    for k, v in ipairs(tbRemovePlayerIds)do
        self:RemoveTeammate(v)
    end
end

function LobbyOldSystem:DismissTeam()
    local nSelfPlayerId = GamePlayerSelfHelper:Get():GetPlayerId()
    local tbRemove = {}
    for k, v in pairs(self.tbTeamPlayers) do
        if k ~= nSelfPlayerId then
            table.insert(tbRemove, k)
        end
    end
    for k, v in ipairs(tbRemove)do
        self:RemoveTeammate(v)
    end
    self:MovePlayerTo(nSelfPlayerId, LobbyPlayerPositionDef.SINGLE_SELF)
end


function LobbyOldSystem:GetTeamMemberActor(nPlayerId)
    local tbPlayer = self.tbTeamPlayers[nPlayerId]
    if tbPlayer then
        return tbPlayer.pUEActor
    end
end

function LobbyOldSystem:GetTeamMemberPlayer(nPlayerId)
    return self.tbTeamPlayers[nPlayerId]
end

function LobbyOldSystem:MovePlayerTo(nPlayerId, nPosIndex)
    if self.tbPlayerPos[nPlayerId] == nPosIndex then
        return
    end
    self.tbPlayerPos[nPlayerId] = nPosIndex
    local pHumanActor = self:GetTeamMemberActor(nPlayerId)
    if not pHumanActor then
        return
    end
    local pLocation, pRotation = GetPosLocationAndRotation(nPosIndex)
    if pLocation and pRotation then
        pHumanActor:K2_SetActorLocation(pLocation)
        pHumanActor:K2_SetActorRotation(pRotation)
    end
end

function LobbyOldSystem:RotatePlayer(nPlayerId, nYawDelta)
    local pHumanActor = self:GetTeamMemberActor(nPlayerId)
    if pHumanActor then
        local tbRotation = pHumanActor:K2_GetActorRotation()
        tbTempRotation.Pitch = tbRotation.Pitch
        tbTempRotation.Roll = tbRotation.Roll
        tbTempRotation.Yaw = tbRotation.Yaw + nYawDelta
        pHumanActor:K2_SetActorRotation(tbTempRotation)
    end
end

function LobbyOldSystem:GetPlayerPos(nPlayerId)
    return self.tbPlayerPos[nPlayerId]
end

return LobbyOldSystem