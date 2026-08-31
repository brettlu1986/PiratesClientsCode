-----------------------------------------------------
--File Name    : LobbyMain.lua
--Author       : Ran Jie
--Create Time  : 2019-07-02
--Description  : 大厅
-----------------------------------------------------
local luaclass = require("luaclass")
local LobbySubBase = require("LobbySubBase")
local LobbyMain = luaclass("LobbyMain", LobbySubBase)

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ClientEventDef = require("ClientEventDef")
local ItemSystem = require("ItemSystem")
-- local HumanAvatarHelper = require("HumanAvatarHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local AvatarDataTable = require("AvatarDataTable")
local SelfAnimationHelper = require("SelfAnimationHelper")
local TeamSystem = require("TeamSystem")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local UIUtils = require("UIUtils")
local ActorLocationHelper = require("ActorLocationHelper")
local DelayTimer = require("DelayTimer")

local CAMERA_BLEND_TIME = 0.5
local CAMERA_BLEND_EXPONENT = 5
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
    [LobbyPlayerPositionDef.SINGLE_SELF] = "LobbyPos4",--"LobbyCenter",
    [LobbyPlayerPositionDef.POS_1] = "LobbyPos4",
    [LobbyPlayerPositionDef.POS_2] = "LobbyPos3",
    [LobbyPlayerPositionDef.POS_3] = "LobbyPos1",
    [LobbyPlayerPositionDef.POS_4] = "LobbyPos2",
}

local tbTempRotation = Rotator()

LobbyMain.tbTeamPlayers = nil
LobbyMain.tbPlayerPos = nil
LobbyMain.nTeamMemberCount = nil
LobbyMain.tbBlendTimerHandle = nil
LobbyMain.bIsPlayerActorReady = nil

local function PlayShowAnimation(nAvatarId, pUEActor, bUseRandomPose)
    local tbAvatar = AvatarDataTable:GetTemplate(nAvatarId)
    --logdebug("LobbyMain:PlayShowAnimation, nAvatarId,ShowAnimation=", nAvatarId)
    if tbAvatar and tbAvatar.szShowAnimation then
        pUEActor:ActivateRandomStandPose(bUseRandomPose)
        if not bUseRandomPose then
            SelfAnimationHelper:PlayActorAnimation(pUEActor, nAvatarId, tbAvatar.szShowAnimation)
        end
    end
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

    if tbFashionIds and tbSelfObj.pUEActor and LobbyPropertyComponent then
        tbSelfObj.HumanAvatarComponent:ApplyBasicFashionItem(tbFashionIds)
        -- HumanAvatarHelper.UpdatePlayerFashionIgnoreArmor(tbSelfObj, {1,2,3,4,5}, tbFashionIds, function() UpdateFashionCallback(self, LobbyPropertyComponent.nAvatarTemplateId, tbSelfObj.pUEActor) end)
    end
end

local function UpdateOtherPlayerFashion(self, nPlayerId, nAvatarId, tbFashionIds)
    local PlayerOther = self:GetTeamMemberPlayer(nPlayerId)
    if PlayerOther and tbFashionIds then
        -- local pHumanActor = PlayerOther.pUEActor
        PlayerOther.HumanAvatarComponent:ApplyBasicFashionItem(tbFashionIds)
        -- HumanAvatarHelper.UpdatePlayerFashionIgnoreArmor(PlayerOther, {1,2,3,4,5}, tbFashionIds, function() UpdateFashionCallback(self, nAvatarId, pHumanActor) end)
    end
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

local function CreateTeamMemberPlayerObj(self, nPlayerId, nAvatarId, szName, tbFashionIds, tbAppearance)
    if self.Owner:GetActiveSub() ~= self then
        return
    end
    local nPosIndex = FindEmptyPos(self, nPlayerId)
    log("CreateTeamMemberPlayerObj,nPlayerId,nPosIndex=",nPlayerId,nPosIndex)
    local szTag = LOBBY_PLAYER_POS_TAG[nPosIndex]
    local pLocation, pRotation = self.SubLevelLoadHelper:GetLocationAndRotationByTag(self.nSubType, UIDef.UI_LOBBY_MAIN, szTag)
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
    -- local nHeightOffset = tbPlayer.pUEActor.CapsuleComponent:GetScaledCapsuleHalfHeight()
    -- logdebug("X, Y, Z,nHeightOffset=",X, Y, Z,nHeightOffset)
    -- tbPlayer:SetLocation(X, Y, Z + nHeightOffset)
    ActorLocationHelper:SetHumanLocationBasedOnFoot(tbPlayer.pUEActor, pLocation)
    ExtendBlueprintFunctions.UpdateSkeletalComponentAnim(tbPlayer.pUEActor.Mesh)
    self:SetActorSkeletalMeshLightChannel(UIDef.UI_LOBBY_MAIN, tbPlayer.pUEActor)
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
    self:SetActorSkeletalMeshLightChannel(UIDef.UI_LOBBY_MAIN, tbSelfObj.pUEActor)
    self.tbTeamPlayers[nPlayerId] = tbSelfObj
    self:MovePlayerTo(nPlayerId, LobbyPlayerPositionDef.SINGLE_SELF)
    OnSelfFashionChanged(self)
    local LobbyPropertyComponent = tbSelfObj.LobbyPropertyComponent
    if LobbyPropertyComponent then
        --logdebug("OnPlayerSelfReady,",LobbyPropertyComponent.nAvatarTemplateId)
        PlayShowAnimation(LobbyPropertyComponent.nAvatarTemplateId, tbSelfObj.pUEActor, true)
    end
    ExtendBlueprintFunctions.UpdateSkeletalComponentAnim(tbSelfObj.pUEActor.Mesh)
    self:RefreshTeammate()
end

local function OnRecvTeamMemberSummaries(self, tbSummariesArray)
    log("LobbyMain:OnRecvPlayerSummaries",GamePlayerSelfHelper:Get():GetName(), #tbSummariesArray)
    for k, v in ipairs(tbSummariesArray)do
        local tbMemberData = TeamSystem:GetTeamMemberData(v.id)
        local nPlayerId = v.id
        local nAvatarId = v.avatar_id
        local tbPlayer = self.tbTeamPlayers[nPlayerId]
        if tbPlayer then
            UpdateOtherPlayerFashion(self, nPlayerId, nAvatarId, v.fashion)
        else
            self:AddTeammate(tbMemberData)
        end
    end
    self.EventHelper:FireEvent(ClientEventDef.EV_LOBBY_MAIN_PLAYER_SUMMARY_CHANGE, tbSummariesArray)
end

local function BindEvent(self)
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_EQUIP_LOBBY_FASHION, self, OnSelfFashionChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_UNEQUIP_LOBBY_FASHION, self, OnSelfFashionChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_MEMBER_SUMMARY_CHANGED, self, OnRecvTeamMemberSummaries)
end

local function SetHumanActorVisible(pActor, bHidden)
    pActor:SetActorHiddenInGame(bHidden)
    local ChildActors = pActor:GetAttachedActors()
    for i,v in ipairs(ChildActors) do
        v:SetActorHiddenInGame(bHidden)
    end
end

--------------override-----------------------
function LobbyMain:Init(Owner, nSubType)
    LobbyMain.super.Init(self, Owner, nSubType)
    self.tbTeamPlayers = {}
    self.tbPlayerPos = {}
    self.nTeamMemberCount = 0
    return true
end

function LobbyMain:Uninit()
    LobbyMain.super.Uninit(self)
    if self.tbBlendTimerHandle then
        DelayTimer:ClearTimer(self.tbBlendTimerHandle)
        self.tbBlendTimerHandle = nil
    end
    self.tbTeamPlayers = nil
    self.tbPlayerPos = nil
    self.bIsPlayerActorReady = false
end

function LobbyMain:Activate(tbParam)
    LobbyMain.super.Activate(self, tbParam)
    BindEvent(self)
    
    self:SetShouldBeVisible(UIDef.UI_LOBBY_MAIN, true)
    --self:SetCamera(UIDef.UI_LOBBY_MAIN, 1)
    self:PlayBGMusic(UIDef.UI_LOBBY_MAIN)
    OnPlayerSelfReady(self)
    for k, v in pairs(self.tbTeamPlayers) do
        SetHumanActorVisible(v.pUEActor, false)
    end
    self.nTeamMemberCount = TeamSystem:GetTeamMemberCount()
    if self.nTeamMemberCount == 2 then
        self:SetCamera(UIDef.UI_LOBBY_MAIN, 3)
    elseif self.nTeamMemberCount > 2 then
        self:SetCamera(UIDef.UI_LOBBY_MAIN, 1)
    else
        self:SetCamera(UIDef.UI_LOBBY_MAIN, 2)
    end
    UIManager:OpenWnd(UIDef.UI_LOBBY_MAIN)
    if tbParam and tbParam.tbUINames then
        for i, v in ipairs(tbParam.tbUINames) do
            UIManager:OpenWnd(v, tbParam)
        end
    end
end

function LobbyMain:Deactivate()
    UIManager:CloseWnd(UIDef.UI_LOBBY_MAIN)
    UIManager:CloseWnd(UIDef.UI_LOBBY_TEAM)
    UIManager:CloseWnd(UIDef.UI_LOBBY_TEAM_LIST)
    UIUtils.DestroyAllCommonBtnList()
    if self.tbBlendTimerHandle then
        DelayTimer:ClearTimer(self.tbBlendTimerHandle)
        self.tbBlendTimerHandle = nil
    end
    self.bIsPlayerActorReady = false
    for k, v in pairs(self.tbTeamPlayers) do
        SetHumanActorVisible(v.pUEActor, true)
    end
    LobbyMain.super.Deactivate(self)
end

function LobbyMain:SetCameraWithBlend(szWndName, nCameraIndex, nBlendTime, pBlendFunction, nBlendExp)
    if self.tbBlendTimerHandle then
        DelayTimer:ClearTimer(self.tbBlendTimerHandle)
        self.tbBlendTimerHandle = nil
    end
    LobbyMain.super.SetCameraWithBlend(self, szWndName, nCameraIndex, nBlendTime, pBlendFunction, nBlendExp)
    if nBlendTime == 0 then
        self.bIsPlayerActorReady = true
        self.EventHelper:FireEvent(ClientEventDef.EV_LOBBYMAIN_BLEND_CAMERA_END)
    else
        self.tbBlendTimerHandle = DelayTimer:DelayRun(function()
            self.bIsPlayerActorReady = true
            self.tbBlendTimerHandle = nil
            self.EventHelper:FireEvent(ClientEventDef.EV_LOBBYMAIN_BLEND_CAMERA_END)
        end, nBlendTime, "LobbyMain:SetCameraWithBlend")
    end
    
    
end
-------------------------------外部接口--------------------------------------
function LobbyMain:GetCenterPosition()
    local szTag = LOBBY_PLAYER_POS_TAG[LobbyPlayerPositionDef.SINGLE_SELF]
    local pLocation, pRotation = self.SubLevelLoadHelper:GetLocationAndRotationByTag(self.nSubType, UIDef.UI_LOBBY_MAIN, szTag)
    return pLocation, pRotation
end

function LobbyMain:AddTeammate(tbMemberData)
    local tbSummary = tbMemberData.tbSummary
    local tbPlayer = CreateTeamMemberPlayerObj(self, tbSummary.id, tbSummary.avatar_id, tbSummary.name, tbSummary.fashion, tbSummary.appearance)
    self.tbTeamPlayers[tbSummary.id] = tbPlayer
    self.nTeamMemberCount = TeamSystem:GetTeamMemberCount()
    if self.Owner:GetActiveSub() == self then
        if self.nTeamMemberCount == 2 then
            self:SetCameraWithBlend(UIDef.UI_LOBBY_MAIN, 3, CAMERA_BLEND_TIME, EViewTargetBlendFunction.VTBlend_EaseOut, CAMERA_BLEND_EXPONENT)
        elseif self.nTeamMemberCount > 2 then
            self:SetCameraWithBlend(UIDef.UI_LOBBY_MAIN, 1, CAMERA_BLEND_TIME, EViewTargetBlendFunction.VTBlend_EaseOut, CAMERA_BLEND_EXPONENT)
        end
    end
    
end

function LobbyMain:RemoveTeammate(nPlayerId)
    DestroyTeamMemberPlayerObj(self, nPlayerId)
    self.tbTeamPlayers[nPlayerId] = nil
    self.nTeamMemberCount = TeamSystem:GetTeamMemberCount()
end

function LobbyMain:RefreshTeammate()
    self.bIsPlayerActorReady = false
    local tbTeamMemberUpdate = {}
    local nSelfPlayerId = GamePlayerSelfHelper:Get():GetPlayerId()
    log("LobbyMain:RefreshTeammate,selfplayerid=",nSelfPlayerId,GamePlayerSelfHelper:Get():GetName())
    local tbTeamMemberIds = TeamSystem:GetTeamMemberIds()
    local tbTeamMemberSummariesArray = {}
    for k, v in ipairs(tbTeamMemberIds)do
        local tbMemberData = TeamSystem:GetTeamMemberData(v)
        local tbSummary = tbMemberData.tbSummary
        local nPlayerId = tbMemberData.nPlayerId
        if nPlayerId == nSelfPlayerId then
            self:MovePlayerTo(nPlayerId, LobbyPlayerPositionDef.POS_1)
        elseif tbSummary then
            table.insert(tbTeamMemberSummariesArray, tbSummary)
        end
        tbTeamMemberUpdate[nPlayerId] = true
    end
    OnRecvTeamMemberSummaries(self, tbTeamMemberSummariesArray)

    local tbRemovePlayerIds = {}
    for k, v in pairs(self.tbTeamPlayers) do
        if k ~= nSelfPlayerId and not tbTeamMemberUpdate[k] then
            table.insert(tbRemovePlayerIds, k)
        end
    end
    for k, v in ipairs(tbRemovePlayerIds)do
        self:RemoveTeammate(v)
    end
    if #tbTeamMemberIds > 0 and self.Owner:GetActiveSub() == self then
        UIManager:OpenWnd(UIDef.UI_LOBBY_TEAM)
    end
end

function LobbyMain:DismissTeam()
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
    if self.Owner:GetActiveSub() == self then
        self:SetCameraWithBlend(UIDef.UI_LOBBY_MAIN, 2, CAMERA_BLEND_TIME, EViewTargetBlendFunction.VTBlend_EaseOut, CAMERA_BLEND_EXPONENT)
    end
    self.nTeamMemberCount = 0
    UIManager:CloseWnd(UIDef.UI_LOBBY_TEAM)
end


function LobbyMain:GetTeamMemberActor(nPlayerId)
    local tbPlayer = self.tbTeamPlayers[nPlayerId]
    if tbPlayer then
        return tbPlayer.pUEActor
    end
end

function LobbyMain:GetTeamMemberPlayer(nPlayerId)
    return self.tbTeamPlayers[nPlayerId]
end

function LobbyMain:MovePlayerTo(nPlayerId, nPosIndex)
    if self.Owner:GetActiveSub() ~= self then
        return
    end
    if self.tbPlayerPos[nPlayerId] == nPosIndex then
        return
    end
    self.tbPlayerPos[nPlayerId] = nPosIndex
    local pHumanActor = self:GetTeamMemberActor(nPlayerId)
    if not pHumanActor then
        return
    end
    local szTag = LOBBY_PLAYER_POS_TAG[nPosIndex]
    local pLocation, pRotation = self.SubLevelLoadHelper:GetLocationAndRotationByTag(self.nSubType, UIDef.UI_LOBBY_MAIN, szTag)
    if pLocation and pRotation then
        --pHumanActor:K2_SetActorLocation(pLocation)
        ActorLocationHelper:SetHumanLocationBasedOnFoot(pHumanActor, pLocation)
        pHumanActor:K2_SetActorRotation(pRotation)
    end
end

function LobbyMain:RotatePlayer(nPlayerId, nYawDelta)
    local pHumanActor = self:GetTeamMemberActor(nPlayerId)
    if pHumanActor then
        local tbRotation = pHumanActor:K2_GetActorRotation()
        tbTempRotation.Pitch = tbRotation.Pitch
        tbTempRotation.Roll = tbRotation.Roll
        tbTempRotation.Yaw = tbRotation.Yaw + nYawDelta
        pHumanActor:K2_SetActorRotation(tbTempRotation)
    end
end

function LobbyMain:GetPlayerPos(nPlayerId)
    return self.tbPlayerPos[nPlayerId]
end

function LobbyMain:IsSelfOrTeamMember(pUEActor)
    if not pUEActor or not isvalidhandle(pUEActor) then
        return false
    end
    for k, v in pairs(self.tbTeamPlayers) do
        if v.pUEActor == pUEActor then
            return true
        end
    end
    return false
end

function LobbyMain:IsPlayerActorReady()
    return self.bIsPlayerActorReady
end

return LobbyMain