local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local ConsumableItemComponentClient = luaclass("ConsumableItemComponentClient", GameComponentBaseClass)
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local UITextDef = require("UITextDef")
local L10N = require("L10N")
local UIUtils = require("UIUtils")
local SelfEventHelperClass = require("SelfEventHelper")
-- local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")

local function ToastTargetTypeWrong(l10nTextBody, nItemInstanceId)
    local tbItem = BattleItemSystemHelper:GetItem(nItemInstanceId, true)
    local l10nName = L10N.NullString
    if tbItem then
        l10nName = tbItem:GetTemplate().l10nName
    end
    UIUtils.ShowToast(L10N:Format(l10nTextBody, l10nName))
end

function ConsumableItemComponentClient:ConsumeItemStart(nCode, nInstanceId, nHpPercentageCap)
    local ReturnCode = ProtoDC.d2c_ConsumeItemStart_ReturnCode
    if nCode == ReturnCode.HP_LIMIT then
        UIUtils.ShowToast(L10N:Format(UITextDef.CONSUMABLE_HP_LIMIT, nHpPercentageCap))
        return
    end

    if nCode == ReturnCode.SHIP_CAN_NOT_USE then
        ToastTargetTypeWrong(UITextDef.CONSUMABLE_SHIP_CAN_NOT_USE, nInstanceId)
        return
    end

    if nCode == ReturnCode.HUMAN_CAN_NOT_USE then
        ToastTargetTypeWrong(UITextDef.CONSUMABLE_HUMAN_CAN_NOT_USE, nInstanceId)
        return
    end

    -- if nCode == ReturnCode.CRAWL_CAN_NOT_USE then
    --     UIUtils.ShowToast(L10N:Format(UITextDef.CONSUMABLE_CRAWL_CAN_NOT_USE))
    --     return
    -- end

    if nCode == ReturnCode.PLAYER_IN_DYING then
        UIUtils.ShowToast(UITextDef.FAILED_WITH_PLAYER_IN_DYING)
        return
    end

    if nCode == ReturnCode.PLAYER_DIED then
        log("Consumable used failed. Player has died. Consumable item id:", nInstanceId)
        return
    end

    if nCode ~= ReturnCode.OK then
        logwarning("ConsumableItemComponentClient:ConsumeItemStart failed. InstanceId:", nCode, "ErrorCode:", nCode)
        return
    end

    local tbItem = BattleItemSystemHelper:GetItem(nInstanceId, true)
    if not tbItem then
        logwarning("ConsumableItemComponentClient:ConsumeItemStart failed. Item not found. InstanceId:", nInstanceId)
        return
    end

    local nItemCategory = tbItem:GetCategory()
    if nItemCategory ~= BattleItemCategoryDef.HUMAN_CONSUMABLE then
        logwarning("ConsumableItemComponentClient:ConsumeItemStar failed. Not consumable item. nInstanceId:", nInstanceId)
        return
    end

    self:RegisterInterruptEvent()
    EventManager:OnFireEvent(ClientEventDef.EV_CONSUMABLE_START_USE, nInstanceId)
end

function ConsumableItemComponentClient:ConsumeItemInterrupt(nInstanceId)
    self:UnregisterInterruptEvent()
    EventManager:OnFireEvent(ClientEventDef.EV_CONSUMABLE_USE_INTERRUPTED, nInstanceId)
end

function ConsumableItemComponentClient:ConsumeItemSuccess(nInstanceId)
    self:UnregisterInterruptEvent()
    EventManager:OnFireEvent(ClientEventDef.EV_CONSUMABLE_USE_SUCCESS, nInstanceId)
end

function ConsumableItemComponentClient:ConsumeItemEnd(nInstanceId)
    EventManager:OnFireEvent(ClientEventDef.EV_CONSUMABLE_USE_END, nInstanceId)
end

function ConsumableItemComponentClient:OnCreate(Owner, tbParams)
    local bRet = ConsumableItemComponentClient.super.OnCreate(self, Owner, tbParams)
    self.EventHelper = SelfEventHelperClass()
    return bRet
end

-- local function SendInterruptMessageToServer()
--     NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_ConsumeItemInterrupt)
-- end

function ConsumableItemComponentClient:RegisterInterruptEvent()
end

function ConsumableItemComponentClient:UnregisterInterruptEvent()
end

function ConsumableItemComponentClient:OnActorDestroyed(pUEActor)
    self.EventHelper:UnregisterAll()
    ConsumableItemComponentClient.super.OnActorDestroyed(self, pUEActor)
end

return ConsumableItemComponentClient
