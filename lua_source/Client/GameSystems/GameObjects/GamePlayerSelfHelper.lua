local GamePlayerSelfHelper = {}

local AvatarDataTable = require("AvatarDataTable")
local GameComponentCreateHelper = require("GameComponentCreateHelper")
local GameComponentTypeDefine = require("GameComponentTypeDefine")
local HumanDataTable = require("HumanDataTable")
--local GlobalVariableSystem = require("GlobalVariableSystem_C")

GamePlayerSelfHelper.PlayerSelf = nil

GamePlayerSelfHelper.tbSavedComponents = nil
GamePlayerSelfHelper.nHubServerId = nil
GamePlayerSelfHelper.tbHubCustomData = nil
GamePlayerSelfHelper.nHubPlayerId = nil
GamePlayerSelfHelper.szName = nil
GamePlayerSelfHelper.nShipTemplateId = nil
GamePlayerSelfHelper.nHumanTemplateId = nil
GamePlayerSelfHelper.nServerInstanceId = nil
GamePlayerSelfHelper.bEnableSaveComponents = false

function GamePlayerSelfHelper:HasSavedData()
    return self.tbSavedComponents ~= nil
end

local function ResetSavedData(self)
    self.tbSavedComponents = nil
    self.nHubServerId = nil
    self.tbHubCustomData = nil
end

function GamePlayerSelfHelper:Init()
    self.bEnableSaveComponents = true
end

function GamePlayerSelfHelper:Uninit()
    self.bEnableSaveComponents = false
    if(self.tbSavedComponents) then
        for _, tbInfo in ipairs(self.tbSavedComponents) do
            tbInfo[2]:OnDestroy()
        end
    end
    ResetSavedData(self)
end

function GamePlayerSelfHelper:SetEnableSaveComponents(bEnable)
    self.bEnableSaveComponents = bEnable
end

function GamePlayerSelfHelper:DetachComponentsWithGameObject(Player)
    log("DetachComponentsWithGameObject")
    if(not self.bEnableSaveComponents) then
        log("DetachComponentsWithGameObject bEnableSaveComponents is false")
        return
    end
    if(not Player.LobbyPropertyComponent) then
        log("DetachComponentsWithGameObject no LobbyPropertyComponent")
        return
    end

    local tbSavedComponents = {}

    self.tbSavedComponents = tbSavedComponents
    self.nHubServerId = Player.nHubServerId
    self.tbHubCustomData = Player.tbHubCustomData
    self.szName = Player.szName
    local LobbyPropertyComponent = Player.LobbyPropertyComponent
    self.nShipTemplateId = LobbyPropertyComponent.nShipTemplateId
    self.nHumanTemplateId = LobbyPropertyComponent.nHumanTemplateId
    self.nServerInstanceId = Player:GetServerInstanceId()

    local tbAllComponents = Player.tbComponents
    local ETypeDef = GameComponentTypeDefine.tbEnvironmentType
    local nEType, szName
    for k, v in ipairs(tbAllComponents) do
        nEType, szName = GameComponentCreateHelper:GetComponentRegistInfo(v.szClassName)
        if(nEType == ETypeDef.All) then
            table.insert(tbSavedComponents, {k, v, szName})
        end
    end

    for i=#tbSavedComponents, 1, -1 do
        table.remove(tbAllComponents, tbSavedComponents[i][1])
    end
end

function GamePlayerSelfHelper:ReattachComponentsWithGameObject(Player)
    log("ReattachComponentsWithGameObject")
    local tbSavedComponents = self.tbSavedComponents
    if(tbSavedComponents == nil) then
        log("ReattachComponentsWithGameObject tbSavedComponents == nil")
        return false
    end

    Player.nHubServerId = self.nHubServerId
    Player.tbHubCustomData = self.tbHubCustomData

    ResetSavedData(self)

    local tbComponent, szName
    local tbAllComponents = Player.tbComponents
    for _, tbInfo in ipairs(tbSavedComponents) do
        --nIndex = tbInfo[1]
        tbComponent = tbInfo[2]
        szName = tbInfo[3]
        tbComponent.Owner = Player
        table.insert(tbAllComponents, tbComponent)
        Player[szName] = tbComponent
    end
    return true
end

function GamePlayerSelfHelper:Set(Player)
    self.PlayerSelf = Player
end

function GamePlayerSelfHelper:Get()
    return self.PlayerSelf
end

function GamePlayerSelfHelper:GetUEActor()
    local PlayerSelf = self.PlayerSelf
    if(PlayerSelf) then
        return PlayerSelf.pUEActor
    else
        return nil
    end
end

function GamePlayerSelfHelper:GetServerInstanceId()
    local PlayerSelf = self.PlayerSelf
    if(PlayerSelf) then
        return PlayerSelf:GetServerInstanceId()
    else
        return nil
    end
end

function GamePlayerSelfHelper:GetHumanTemplateId(tbHumanData)
    return AvatarDataTable:GetHumanId(tbHumanData.avatar_id)
end

function GamePlayerSelfHelper:GetShipTemplateId(tbShipData)
    return self:GetCurrentShipData(tbShipData).type_id
end

function GamePlayerSelfHelper:GetCurrentShipData(tbShipData)
    for _, ship_data in ipairs(tbShipData.ships) do
        if ship_data.instance_id == tbShipData.flag_ship_instance_id then
            return ship_data
        end
    end
    return nil
end

--注意 只能在battle中使用
function GamePlayerSelfHelper:GetGenderInBattle()
    local PlayerSelf = self.PlayerSelf
    if PlayerSelf then
        local nHumanId = PlayerSelf:GetHumanTemplateId()
        local tbHumanData = HumanDataTable:GetTemplate(nHumanId)
        local nGender = tbHumanData.nGender
        return nGender
    else
        return nil
    end
end

function GamePlayerSelfHelper:IsPlayerSelf(tbCharacter)
    return self.PlayerSelf == tbCharacter
end

function GamePlayerSelfHelper:IsNotPlayerSelf(tbCharacter)
    return self.PlayerSelf ~= tbCharacter
end

-- function GamePlayerSelfHelper:CreatePlayerSelf(bShip, tbData)
--     local tbPlayerData = tbData.data
--     local tbSceneInfo = tbPlayerData.scene
--     tbPlayerData.bShip = bShip
--     tbPlayerData.szName = tbData.name
--     tbPlayerData.nDBPlayerID = tbData.nDBPlayerID
--     local nServerInstanceId = tbData.actor_id
--     tbPlayerData.transform = tbSceneInfo.transform
--     local nTemplateId = nil

--     if(bShip) then
--         nTemplateId = self:GetShipTemplateId(tbPlayerData.ship_list)
--     else
--         nTemplateId = self:GetHumanTemplateId(tbPlayerData.avatar)
--     end

--     local SelfPlayer = GameObjectSystem:Create(
--             GameObjectTypeDef.PlayerSelf,
--             nServerInstanceId,
--             nTemplateId,
--             tbPlayerData)
--     if(SelfPlayer == nil) then
--         logerror("CreatePlayerSelf failed!!!")
--         return nil
--     end
--     log("CreatePlayerSelf, ServerInstanceID: ", nServerInstanceId, ", TemplateId: ", nTemplateId, ", Name: ", tbPlayerData.szName)

--     return SelfPlayer
-- end

return GamePlayerSelfHelper
