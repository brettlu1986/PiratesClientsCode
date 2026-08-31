local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local ItemPacketProcessor = luaclass("ItemPacketProcessor", NetMessageProcessorBase)

local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local ItemSystem = require("ItemSystem")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
-- local UIManager = require("UIManager")
-- local UIDef = require("UIDef")
local UIUtils = require("UIUtils")
local ItemDataTable = require("ItemDataTable")
local L10N = require("L10N")
local UITextDef = require("UITextDef")
local ItemCategoryDef = require("ItemCategoryDef")
local LobbyChatSystem = require("LobbyChatSystem")
-- local GlobalVariableSystem = require("GlobalVariableSystem_C")
local SelfEventHelper = require("SelfEventHelper")
-- local HomelandSystem = require("HomelandSystem")

-- ItemPacketProcessor.tbAwardDatas = nil
-- ItemPacketProcessor.tbHomelandAwardData = nil

ItemPacketProcessor.bNotInDungeon = nil
ItemPacketProcessor.tbHoldLimitToastDataCache = nil
ItemPacketProcessor.EventHelper = nil

local function GetFailedToast(nReturnCode)
    local ReturnCode = Proto.ReturnCode
    if nReturnCode == ReturnCode.ITEM_CANNOT_USE then
        return UITextDef.LOBBY_ITEM_FAILED_CANNOT_USE
    elseif nReturnCode == ReturnCode.ITEM_NOT_FOUND then
        return UITextDef.LOBBY_ITEM_FAILED_NOT_FOUND
    elseif nReturnCode == ReturnCode.ITEM_CANNOT_SELL then
        return UITextDef.LOBBY_ITEM_FAILED_CANNOT_SELL
    elseif nReturnCode == ReturnCode.ITEM_NOT_IN_BACKPACK then
        return UITextDef.LOBBY_ITEM_FAILED_NOT_IN_BACKPACK
    elseif nReturnCode == ReturnCode.ITEM_NOT_ENOUGH then
        return UITextDef.LOBBY_ITEM_FAILED_NOT_ENOUGH
    elseif nReturnCode == ReturnCode.ITEM_EXPIRED then
        return UITextDef.LOBBY_ITEM_FAILED_EXPIRED
    elseif nReturnCode == ReturnCode.ITEM_LEVEL_LIMITED then
        return UITextDef.LOBBY_ITEM_FAILED_LEVEL_LIMITED
    elseif nReturnCode == ReturnCode.ITEM_GENDER_NOT_MATCH then
        return UITextDef.LOBBY_ITEM_FAILED_GENDER_NOT_MATCH
    elseif nReturnCode == ReturnCode.WEAR_EXPIRED then
        return UITextDef.LOBBY_ITEM_FAILED_EXPIRED
    elseif nReturnCode == ReturnCode.ITEM_USE_TOO_MUCH then
        return UITextDef.LOBBY_ITEM_USE_TOO_MUCH
    elseif nReturnCode == Proto.ReturnCode.NAME_UNAVAILABLE then
        return UITextDef.NAME_UNAVAILABLE
    elseif nReturnCode == Proto.ReturnCode.INTIMACY_POINT_MAX_LIMIT then
        return UITextDef.LOBBY_ITEM_USE_INTIMACY_MAX
    elseif nReturnCode == Proto.ReturnCode.DECORATION_REPEATED then  
        return UITextDef.LOBBY_DECORATION_EQUIP_SAME
    elseif nReturnCode == Proto.ReturnCode.DECORATION_NOT_DRESSED then  
        return UITextDef.LOBBY_DECORATION_NOT_EQUIP
    elseif nReturnCode == Proto.ReturnCode.DECORATION_NOT_FOUND then 
        return UITextDef.LOBBY_DECORATION_NOT_FOUND
    else
        return nil
    end
end

-- local function ShowAward(tbAwardDatas)
--     LobbyChatSystem:OnAwardNotification(tbAwardDatas)
--     local szWndName = UIDef.UI_LOBBY_AWARD_ITEM
--     if UIManager:IsWndOpen(szWndName) then
--         local tbWnd = UIManager:GetWnd(szWndName)
--         for _, v in ipairs(tbAwardDatas) do
--             tbWnd:AddAwardData(v)
--         end
--     else
--         local tbItemDatas = tbAwardDatas[1]
--         table.remove(tbAwardDatas, 1)
--         local tbItemQueue = nil
--         if #tbAwardDatas > 0 then
--             tbItemQueue = tbAwardDatas
--         end
--         UIManager:OpenWnd(UIDef.UI_LOBBY_AWARD_ITEM,{tbItemDatas = tbItemDatas, tbItemQueue = tbItemQueue})
--     end
-- end

-- local function AddAward(self, tbItemDatas)
--     if self.tbAwardDatas == nil then
--         self.tbAwardDatas = {}
--     end
--     table.insert(self.tbAwardDatas, tbItemDatas)
-- end

-- local function OnEnterLobby(self)
--     if self.tbAwardDatas ~= nil and #self.tbAwardDatas > 0 then
--         ShowAward(self.tbAwardDatas)
--         self.tbAwardDatas = nil
--     end
-- end

-- local function AddHomelandAward(self, tbItemDatas)
--     if self.tbHomelandAwardData == nil then
--         self.tbHomelandAwardData = {}
--     end
--     for _, v in ipairs(tbItemDatas) do
--         table.insert(self.tbHomelandAwardData, v)
--     end
-- end

-- local function OnEnterHomeland(self)
--     if self.tbHomelandAwardData ~= nil then
--         local tbAwardDatas = {}
--         table.insert(tbAwardDatas, self.tbHomelandAwardData)
--         ShowAward(tbAwardDatas)
--         self.tbHomelandAwardData = nil
--     end
-- end

-- 获取新道具
function ItemPacketProcessor:OnAddItem(tbPacket)
    local tbItemDatas = tbPacket.item
    local tbItems = ItemSystem:OnAddItem(tbItemDatas)
    for _, Item in ipairs(tbItems) do
        EventManager:OnFireEvent(ClientEventDef.EV_ADD_LOBBY_ITEM, Item)
    end
end

-- 同步Item堆叠数量,数量0表示删除
function ItemPacketProcessor:OnSyncItemStackCount(tbPacket)
    local nInstanceId = tbPacket.instance_id
    local nStackCount = tbPacket.stack_count
    if nStackCount > 0 then
        local Item = ItemSystem:GetItem(nInstanceId)
        if not Item then
            logerror("OnSyncItemStackCount cannot find item!", nInstanceId, nStackCount)
            return
        end
        local nOldCount = Item:GetStackCount()
        if nOldCount == nStackCount then
            return
        end
        ItemSystem:OnSyncItemStackCount(nInstanceId, nStackCount, tbPacket.create_time)
        local bAdd = nOldCount < nStackCount
        EventManager:OnFireEvent(ClientEventDef.EV_CHANGE_LOBBY_ITEM_STACK_COUNT, nInstanceId, nStackCount, bAdd)
    else
        local nTemplateId = ItemSystem:OnRemoveItem(nInstanceId)
        LobbyChatSystem:OnRemoveItem(nTemplateId)
        EventManager:OnFireEvent(ClientEventDef.EV_REMOVE_LOBBY_ITEM, nInstanceId, nTemplateId)
    end
end

-- 同步Item过期时间
function ItemPacketProcessor:OnSyncItemExpiredAt(tbPacket)
    local nInstanceId = tbPacket.instance_id
    ItemSystem:OnSyncItemExpiredAt(nInstanceId, tbPacket.expired_at)
    EventManager:OnFireEvent(ClientEventDef.EV_CHANGE_LOBBY_ITEM_EXPIRED_AT, nInstanceId, tbPacket.expired_at == 0)
end

-- 出售道具
function ItemPacketProcessor:OnSellItem(tbPacket)
    local nReturnCode = tbPacket.return_code
    if nReturnCode == Proto.ReturnCode.OK then
        EventManager:OnFireEvent(ClientEventDef.EV_SELL_LOBBY_ITEM_SUCCESS)
    else
        local l10nToast = GetFailedToast(nReturnCode)
        if l10nToast ~= nil then
            UIUtils.ShowToast(l10nToast)
        else
            UIUtils.ShowToast(L10N:Format(UITextDef.LOBBY_ITEM_SELL_FAILED, nReturnCode))
        end
        EventManager:OnFireEvent(ClientEventDef.EV_SELL_LOBBY_ITEM_FAIL)
    end
end

-- 使用道具
function ItemPacketProcessor:OnUseItem(tbPacket)
    local nReturnCode = tbPacket.return_code
    if nReturnCode == Proto.ReturnCode.OK then
        -- UIUtils.ShowToast(UITextDef.LOBBY_ITEM_USE_SUCCESS)
        EventManager:OnFireEvent(ClientEventDef.EV_USE_LOBBY_ITEM_SUCCESS)
    else
        local l10nToast = GetFailedToast(nReturnCode)
        if l10nToast ~= nil then
            UIUtils.ShowToast(l10nToast)
        else
            UIUtils.ShowToast(L10N:Format(UITextDef.LOBBY_ITEM_USE_FAILED, nReturnCode))
        end
        EventManager:OnFireEvent(ClientEventDef.EV_USE_LOBBY_ITEM_FAIL)
    end
end

-- 收到获得道具的同步
-- function ItemPacketProcessor:OnAwardNotification(tbPacket)
--     local nSourceType = tbPacket.source_type
--     local AwardSourceType = Proto.AwardSourceType
--     if nSourceType == AwardSourceType.SUMMON_PARTNER
--         or nSourceType == AwardSourceType.ITEM_UNLOCK_CARD
--         or nSourceType == AwardSourceType.SUMMON_SAILOR
--         or nSourceType == AwardSourceType.ACCOUNT_REGULAR_AWARD
--         or nSourceType == AwardSourceType.UNLOCK_SHIP
--         or nSourceType == AwardSourceType.NEW_PLAYER then
--         return
--     end
--     local tbAddedItemDatas = tbPacket.award_addition
--     local tbItemDatas = {}
--     for _, v in ipairs(tbAddedItemDatas) do
--         local nCount = v.count
--         if nCount > 0 then
--             local tbItemData = {}
--             tbItemData.nItemTemplateId = v.template_id
--             tbItemData.nCount = nCount
--             table.insert(tbItemDatas, tbItemData)
--         end
--     end
--     if #tbItemDatas == 0 then
--         return
--     end

--     local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
--     if bIsInDungeon then
--         AddAward(self, tbItemDatas)
--     else
--         if nSourceType == AwardSourceType.RESEARCH and not HomelandSystem:IsInHomeland() then
--             AddHomelandAward(self, tbItemDatas)
--         else
--             local tbAwardDatas = {}
--             table.insert(tbAwardDatas, tbItemDatas)
--             ShowAward(tbAwardDatas)
--         end
--     end
-- end

local function OnEnterBattle(self)
    self.bNotInDungeon = false
end

local function ShowItemReachHoldLimitToast(self, tbData)
    local nTemplateId = tbData.template_id
    local tbTemplate = ItemDataTable:GetTemplate(nTemplateId)
    if tbTemplate.nCategory ~= ItemCategoryDef.PARTNER then
        UIUtils.ShowToast(L10N:Format(UITextDef.LOBBY_ITEM_HOLD_LIMIT, tbTemplate.l10nName))
    end
end

local function VerfiyShowItemsReachHoldLimitToast(self)
    local tbHoldLimitToastDataCache = self.tbHoldLimitToastDataCache
    if self.tbHoldLimitToastDataCache and #self.tbHoldLimitToastDataCache > 0 then
        for _, v in ipairs(tbHoldLimitToastDataCache) do
            ShowItemReachHoldLimitToast(self, v)
        end
    end
    self.tbHoldLimitToastDataCache = nil
end

local function OnNotInBattle(self)
    self.bNotInDungeon = true
    VerfiyShowItemsReachHoldLimitToast(self)
end

local function AddItemReachHoldLimitToastData(self, tbData)
    if self.tbHoldLimitToastDataCache == nil then
        self.tbHoldLimitToastDataCache = {}
    end
    table.insert(self.tbHoldLimitToastDataCache, tbData)
end

-- 收到道具达到上限被卖掉的同步
function ItemPacketProcessor:OnReachHoldLimitToast(tbPacket)
    local tbHoldLimitItems = tbPacket.hold_limit_item
    if tbHoldLimitItems ~= nil then
        for _, v in ipairs(tbHoldLimitItems) do
            if self.bNotInDungeon then
                ShowItemReachHoldLimitToast(self, v)
            else
                AddItemReachHoldLimitToastData(self, v)
            end
        end
    end
end

-- 同步外装和饰品的变化
function ItemPacketProcessor:OnSyncWear(tbPacket)
    ItemSystem:OnSyncWear(tbPacket.take_off_instance_id, tbPacket.put_on_instance_id)
end

-- 穿上外装或者饰品的回包
function ItemPacketProcessor:OnPutOnWear(tbPacket)
    local nReturnCode = tbPacket.return_code
    if nReturnCode ~= Proto.ReturnCode.OK then
        local l10nToast = GetFailedToast(nReturnCode)
        if l10nToast ~= nil then
            UIUtils.ShowToast(l10nToast)
        else
            UIUtils.ShowToast(L10N:Format(UITextDef.LOBBY_ITEM_USE_FAILED, nReturnCode))
        end
    end
end

-- 脱下外装或者饰品的回包
function ItemPacketProcessor:OnTakeOffWear(tbPacket)
    local nReturnCode = tbPacket.return_code
    if nReturnCode ~= Proto.ReturnCode.OK then
        local l10nToast = GetFailedToast(nReturnCode)
        if l10nToast ~= nil then
            UIUtils.ShowToast(l10nToast)
        else
            UIUtils.ShowToast(L10N:Format(UITextDef.LOBBY_ITEM_USE_FAILED, nReturnCode))
        end
    end
end

function ItemPacketProcessor:OnFitFashion(tbPacket)
    ItemSystem:OnFitFashion(tbPacket.take_off_instance_id, tbPacket.put_on_instance_id)
end

function ItemPacketProcessor:OnHumanFashionFlagModified(tbPacket)
    local nReturnCode = tbPacket.return_code
    if nReturnCode ~= Proto.ReturnCode.OK then
        local l10nToast = GetFailedToast(nReturnCode)
        if l10nToast ~= nil then
            UIUtils.ShowToast(l10nToast)
        else
            UIUtils.ShowToast(L10N:Format(UITextDef.LOBBY_ITEM_USE_FAILED, nReturnCode))
        end
    else
        ItemSystem:OnHumanFashionFlagModified(tbPacket.flag)
    end
end

------------------------------
--新版本 穿上饰品
function ItemPacketProcessor:OnPutOnDecoration(tbPacket)
    local nReturnCode = tbPacket.return_code
    if nReturnCode ~= Proto.ReturnCode.OK then
        local l10nToast = GetFailedToast(nReturnCode)
        if l10nToast ~= nil then
            UIUtils.ShowToast(l10nToast)
        else
            UIUtils.ShowToast(L10N:Format(UITextDef.LOBBY_ITEM_USE_FAILED, nReturnCode))
        end
    end
end

--新版本 同步饰品穿戴状态，复用原来的接口 不需要加新的
function ItemPacketProcessor:OnSyncDecoration(tbPacket)
    ItemSystem:OnSyncWear(tbPacket.take_off_instance_id, tbPacket.put_on_instance_id)
end

function ItemPacketProcessor:OnTakeOffDecoration(tbPacket)
    local nReturnCode = tbPacket.return_code
    if nReturnCode ~= Proto.ReturnCode.OK then
        local l10nToast = GetFailedToast(nReturnCode)
        if l10nToast ~= nil then
            UIUtils.ShowToast(l10nToast)
        else
            UIUtils.ShowToast(L10N:Format(UITextDef.LOBBY_ITEM_USE_FAILED, nReturnCode))
        end
    end
end

function ItemPacketProcessor:OnGetDecoration(tbPacket)
    if tbPacket.instance_id and tbPacket.instance_id > 0 then
        ItemSystem:OnSyncWear(nil, tbPacket.instance_id)
    end
end

function ItemPacketProcessor:UpgradeDecoration(tbPacket)
    local nReturnCode = tbPacket.return_code
    self.EventHelper:FireEvent(ClientEventDef.EV_UPGRADE_DECORATION_FINISH)
    if nReturnCode ~= Proto.ReturnCode.OK then
        local l10nToast = GetFailedToast(nReturnCode)
        if l10nToast ~= nil then
            UIUtils.ShowToast(l10nToast)
        else
            UIUtils.ShowToast(L10N:Format(UITextDef.LOBBY_ITEM_USE_FAILED, nReturnCode))
        end
    end
end
-------------

function ItemPacketProcessor:GetRenameTimes(tbPacket)
    self.EventHelper:FireEvent(ClientEventDef.EV_SHOW_RENAME_PLAYER,  tbPacket.last_use_time, tbPacket.rename_times)
end

function ItemPacketProcessor:SyncVipAwardDetails(tbPacket)
    self.EventHelper:FireEvent(ClientEventDef.EV_REFRESH_WELFARE_DATA,  tbPacket.vip_award)
end

function ItemPacketProcessor:GetVipAward(tbPacket)
    local nReturnCode = tbPacket.return_code
    UIUtils.HideWaitingPacket()
    if nReturnCode == Proto.ReturnCode.OK then
        self.EventHelper:FireEvent(ClientEventDef.EV_REFRESH_VIP_CARD_ITEM,  tbPacket.vip_award)
    else
        local l10nToast = GetFailedToast(nReturnCode)
        if l10nToast ~= nil then
            UIUtils.ShowToast(l10nToast)
        else
            UIUtils.ShowToast(L10N:Format(UITextDef.WELFARE_GET_FAIL, nReturnCode))
        end
    end
end

-- 注册处理包
function ItemPacketProcessor:RegisterPackets()
    local HubServerProxy = NetworkManager:GetHubServerProxy()
    self:SetBinder(HubServerProxy)
    self:BindMethod(Proto.s2c_AddItem, self, self.OnAddItem)
    self:BindMethod(Proto.s2c_SyncItemStackCount, self, self.OnSyncItemStackCount)
    self:BindMethod(Proto.s2c_SyncItemExpiredAt, self, self.OnSyncItemExpiredAt)
    self:BindMethod(Proto.s2c_SellItem, self, self.OnSellItem)
    self:BindMethod(Proto.s2c_UseItem, self, self.OnUseItem)
    -- self:BindMethod(Proto.s2c_AwardNotification, self, self.OnAwardNotification)
    self:BindMethod(Proto.s2c_ReachHoldLimitToast, self, self.OnReachHoldLimitToast)

    self:BindMethod(Proto.s2c_syncWear, self, self.OnSyncWear)
    self:BindMethod(Proto.s2c_putOnWear, self, self.OnPutOnWear)
    self:BindMethod(Proto.s2c_takeOffWear, self, self.OnTakeOffWear)
    self:BindMethod(Proto.s2c_fitFashion, self, self.OnFitFashion)
    self:BindMethod(Proto.s2c_dryFashionFlag, self, self.OnHumanFashionFlagModified)

    --改名卡改名
    self:BindMethod(Proto.s2c_GetRenameTimes, self, self.GetRenameTimes)
    --vip卡
    self:BindMethod(Proto.s2c_SyncVipAwardDetails, self, self.SyncVipAwardDetails)
    self:BindMethod(Proto.s2c_GetVipAward, self, self.GetVipAward)
    --decoration
    self:BindMethod(Proto.s2c_PutOnDecoration, self, self.OnPutOnDecoration)
    self:BindMethod(Proto.s2c_SyncDecoration, self, self.OnSyncDecoration)
    self:BindMethod(Proto.s2c_TakeOffDecoration, self, self.OnTakeOffDecoration)
    self:BindMethod(Proto.s2c_GetDecoration, self, self.OnGetDecoration)
    self:BindMethod(Proto.s2c_UpgradeDecoration, self, self.UpgradeDecoration)

end

-- 初始化
function ItemPacketProcessor:Init()
    ItemPacketProcessor.super.Init(self)

    self:RegisterPackets()

    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE, self, OnEnterBattle)
    EventHelper:RegisterEvent(ClientEventDef.EV_HOMELAND_READY, self, OnNotInBattle)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_READY, self, OnNotInBattle)

    return true
end

-- 结束
function ItemPacketProcessor:Uninit()
    if self.EventHelper ~= nil then
        self.EventHelper:UnregisterAll()
        self.EventHelper = nil
    end
    ItemPacketProcessor.super.Uninit(self)
end

return ItemPacketProcessor
