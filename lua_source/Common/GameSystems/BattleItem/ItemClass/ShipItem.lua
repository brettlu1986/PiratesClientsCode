-----------------------------------------------------
--File Name    : ShipItem.lua
--Author       : Xu Weihua
--Create Time  : 2018-09-07
--Description  : Ship as an item.
-----------------------------------------------------

local luaclass = require("luaclass")
local EquipmentItemBase = require("EquipmentItemBase")
local ShipItem = luaclass("ShipItem", EquipmentItemBase)

local EventManager = require("EventManager")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local CommonEventDef    = require("CommonEventDef")
local BattlePrepareSystem = require("BattlePrepareSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemSourceDef = require("BattleItemSourceDef")

local function GetShipId(self)
    local tbTemplate = self:GetTemplate()
    return tbTemplate.nShipId
end

local function AddBuildShipRecord(self, bIsInitOrBuild)
    local nGrade = self:GetGrade()

    local tbPlayer = self:GetOwnerCharacter()
    local nCharacterInstanceId = tbPlayer:GetServerInstanceId()

    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()

    local nLastBuildGrade = BattleItemSystemServer:GetShipBuiltGrade(nCharacterInstanceId)
    if nLastBuildGrade == nil or nGrade > nLastBuildGrade then
        log("[BuildingLevel]Add Build Ship Record", nCharacterInstanceId, tbPlayer:GetName(), nGrade)
        BattleItemSystemServer:SetShipBuiltGrade(nCharacterInstanceId, nGrade)
    end
end

function ShipItem:OnCreate()
end

function ShipItem:AfterAddedToCharacterOnServer(nBattleItemSource, bSyncToClient)
    local bIsInitOrBuild = (nBattleItemSource == BattleItemSourceDef.INIT or nBattleItemSource == BattleItemSourceDef.BUILD)
    AddBuildShipRecord(self, bIsInitOrBuild)

    local tbPlayer = self:GetOwnerCharacter()
    tbPlayer.ShipBattlePropertyComponent:ResetShipHpAndEpWhenShipChange(bIsInitOrBuild)
end

function ShipItem:OnEquipOnServer()
    local tbPlayer = self:GetOwnerCharacter()
    local nShipId = GetShipId(self)
    EventManager:OnFireEvent(CommonEventDef.EV_ON_PLAYER_SHIP_TO_CHANGE_SERVER, tbPlayer, nShipId)
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    BattleItemSystemServer:OnPlayerShipToChange(tbPlayer, nShipId)

    -- Change the ship id for the Player.
    if tbPlayer:GetObjectType() == GameObjectTypeDef.PlayerSelf then -- 只有玩家需要设置这段数据，npc不需要
        BattlePrepareSystem:SetShipTemplateId(tbPlayer:GetPlayerId(), nShipId)
    end
    tbPlayer.ShipBattlePropertyComponent:SetShipTemplateId(nShipId)

    -- Change the appearance if the player is in ship mode.
    if tbPlayer:IsShip() and tbPlayer:GetModelActor() and tbPlayer:GetTemplateId() ~= nShipId then
        BattleGameModeSystem:GetGameMode():ChangeToShip(tbPlayer, nShipId)
    end

    BattleItemSystemServer:OnPlayerShipChanged(tbPlayer, nShipId)
    -- Notify observers that the player has changed it's ship.
    EventManager:OnFireEvent(CommonEventDef.EV_ON_PLAYER_SHIP_CHANGED_SERVER, tbPlayer, nShipId)
end

function ShipItem:OnUnequipOnServer()
end

function ShipItem:OnEquipOnClient()
    -- Notify observers that the player has changed it's ship.
    local tbPlayer = self:GetOwnerCharacter()
    local nShipId = GetShipId(self)

    local BattleItemSystemClient = BattleItemSystemHelper:GetBattleItemSystemClient()

    local nGrade = self:GetGrade()
    local nLastBuildGrade = BattleItemSystemClient:GetShipBuiltGrade()
    if nLastBuildGrade == nil or nGrade > nLastBuildGrade then
        log("[BuildingLevel]Add Build Ship Record", nGrade)
        BattleItemSystemClient:SetShipBuiltGrade(nGrade)
    end

    local ClientEventDef = require("ClientEventDef")
    EventManager:OnFireEvent(ClientEventDef.EV_ON_PLAYER_SHIP_CHANGED_CLIENT, tbPlayer, nShipId)
end


function ShipItem:OnUnequipOnClient()
end


function ShipItem:GetProtoData()
    local tbData = ShipItem.super.GetProtoData(self)
    --tbData.durability = self.nDurability
    return tbData
end

function ShipItem:InitWithProtoData(tbPlayer, tbItemProtoData)
    ShipItem.super.InitWithProtoData(self, tbPlayer, tbItemProtoData)
    --self.nDurability = tbItemProtoData.durability
end


function ShipItem:OnDestroy(...)
end

return ShipItem