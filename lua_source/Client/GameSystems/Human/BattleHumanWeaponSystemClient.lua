-----------------------------------------------------
--File Name    : BattleHumanWeaponSystemClient.lua
--Author       : WuJizhou
--Create Time  : 9/18/2018, 11:18:33 AM
--Description  : BattleHumanWeaponSystemClient
-----------------------------------------------------
local BattleHumanWeaponSystemClient = {}

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local Proto = require("DungeonCommonProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemSystemClient = require("BattleItemSystemClient")

BattleHumanWeaponSystemClient.tbShortcutItems = {}

local TEMPLATE_ID_KEY = 1

local function ProcessOnAdded(self, tbItem, nCategory)
    local tbThrownItem = self.tbShortcutItems[nCategory]
    if tbThrownItem == nil then
        tbThrownItem = {}
        self.tbShortcutItems[nCategory] = tbThrownItem
        tbThrownItem[TEMPLATE_ID_KEY] = tbItem:GetTemplateId()
    end
end

local function ProcessOnRemoved(self, nInstanceId, nItemTemplateId)
    local nDeleteCategory = nil
    for k, v in pairs(self.tbShortcutItems) do
        if v[TEMPLATE_ID_KEY] == nItemTemplateId then
            local nItemCategory = BattleItemDataTable:GetTemplate(nItemTemplateId).nCategory
            local nId = BattleItemSystemClient:GetUnequippedLeastStackCountInstanceId(nItemTemplateId)
            if nId ~= nil then
                break
            end

            local tbItems = BattleItemSystemClient:GetUnequippedItemsByCategory(nItemCategory)
            if #tbItems > 0 then
                local tbItem = tbItems[1]
                v[TEMPLATE_ID_KEY] = tbItem:GetTemplateId()
            else
                nDeleteCategory = nItemCategory
            end
        end
    end
    if nDeleteCategory ~= nil then
        self.tbShortcutItems[nDeleteCategory] = nil
    end
end

local function ProcessForThrownItemOnStackCountChanged(self)
end

local function OnItemAdded(self, tbItem)
    local nCategory = tbItem:GetCategory()
    ProcessOnAdded(self, tbItem, nCategory)
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_NOTIFY_REFRESH_HUMAN_UI_ON_ITEM_ADDED, tbItem)
end

local function OnItemRemoved(self, nInstanceId)
    ProcessOnRemoved(self, nInstanceId)
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_NOTIFY_REFRESH_HUMAN_UI_ON_ITEM_REMOVED, nInstanceId)
end

local function OnItemStackCountChanged(self)
    ProcessForThrownItemOnStackCountChanged(self)
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_NOTIFY_REFRESH_HUMAN_UI_ON_ITEM_STACK_COUNT_CHANGED)
end

local function ChangeWeaponFireTypeInternal(nWeaponInstanceId)
    local tbWeapon = BattleItemSystemClient:GetItem(nWeaponInstanceId)
    tbWeapon:ChangeFireType()
    return tbWeapon
end

local function OnFinishExchange(self, Item1, Item2)
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_NOTIFY_REFRESH_HUMAN_UI_ON_ITEM_EXCHANGE)
end


-------------public-------------

function BattleHumanWeaponSystemClient:SetShortcutItemTemplateId(nItemTemplateId)

    local nCategory =  BattleItemDataTable:GetTemplate(nItemTemplateId).nCategory
    local tb = self.tbShortcutItems[nCategory]
    if tb == nil then
        tb = {}
        self.tbShortcutItems[nCategory] = tb
    end
    tb[TEMPLATE_ID_KEY] = nItemTemplateId
end



function BattleHumanWeaponSystemClient:GetShortcutItemTemplateId(nCategory)
    assert(not GlobalVariableSystem:IsServerLogic())
    local tbPair = self.tbShortcutItems[nCategory]
    if tbPair == nil then
        return nil
    else
        return tbPair[TEMPLATE_ID_KEY]
    end
end

function BattleHumanWeaponSystemClient:RequestServerToChangeWeaponFireType(nWeaponInstanceId)
    assert(not GlobalVariableSystem:IsServerLogic())
    local c2d_ChangeHumanWeaponFireType = {
        weapon_instance_id = nWeaponInstanceId
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_ChangeHumanWeaponFireType, c2d_ChangeHumanWeaponFireType)
end

function BattleHumanWeaponSystemClient:OnChangeWeaponFireTypeReceived(nWeaponInstanceId)
    assert(not GlobalVariableSystem:IsServerLogic())
    ChangeWeaponFireTypeInternal(nWeaponInstanceId)
end

function BattleHumanWeaponSystemClient:RequestServerToHoldThrownItem(nItemInstanceId)
    assert(not GlobalVariableSystem:IsServerLogic())
    local c2d_HoldThrownItem = {
        item_instance_id = nItemInstanceId
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HoldThrownItem, c2d_HoldThrownItem)
end

function BattleHumanWeaponSystemClient:RequestServerToUnholdThrownItem(nItemInstanceId)
    assert(not GlobalVariableSystem:IsServerLogic())
    local c2d_UnholdThrownItem = {
        item_instance_id = nItemInstanceId
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_UnholdThrownItem, c2d_UnholdThrownItem)
end

function BattleHumanWeaponSystemClient:RequestServerToChangeThrowType(nNewType)
    assert(not GlobalVariableSystem:IsServerLogic())
    local c2d_ChangeHumanThrowType = {
        throw_type = nNewType
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_ChangeHumanThrowType, c2d_ChangeHumanThrowType)
end

function BattleHumanWeaponSystemClient:RequsetCancelThrowExplosive()
    assert(not GlobalVariableSystem:IsServerLogic())
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_CancelThrowExplosive, {})
end


-----------life cycle---------

function BattleHumanWeaponSystemClient:Init()

    EventManager:BindEventMethod(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT, self, OnItemAdded)
    EventManager:BindEventMethod(ClientEventDef.EV_BATTLE_ITEM_REMOVE_CLIENT, self,OnItemRemoved)
    EventManager:BindEventMethod(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT, self, OnItemStackCountChanged)
    EventManager:BindEventMethod(ClientEventDef.EV_BATTLE_ITEM_EXCHANGE_STORAGE_LOCATION_CLIENT, self, OnFinishExchange)

    return true
end

function BattleHumanWeaponSystemClient:Uninit()
    EventManager:UnBindEventMethod(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT, self, OnItemAdded)
    EventManager:UnBindEventMethod(ClientEventDef.EV_BATTLE_ITEM_REMOVE_CLIENT, self, OnItemRemoved)
    EventManager:UnBindEventMethod(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT, self, OnItemStackCountChanged)
    EventManager:UnBindEventMethod(ClientEventDef.EV_BATTLE_ITEM_EXCHANGE_STORAGE_LOCATION_CLIENT, self, OnFinishExchange)
end

return BattleHumanWeaponSystemClient