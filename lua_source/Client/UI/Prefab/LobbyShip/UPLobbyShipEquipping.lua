-----------------------------------------------------
--File Name    : UPLobbyShipEquipping.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-20
--Description  : 船战备舰船上阵页面
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPLobbyShipEquipping = luaclass("UPLobbyShipEquipping", PrefabBase)

local L10N = require("L10N")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local ItemSystem = require("ItemSystem")
local ClientEventDef = require("ClientEventDef")
local ShipSlotDataTable = require("ShipSlotDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local SelfListHelperNew = require("SelfListHelperNew")

-- 最大上阵个数
local MAX_EQUIPPED_COUNT = 4
UPLobbyShipEquipping.tbShipEquippingItem = nil
UPLobbyShipEquipping.nCurrentSlotIndex = -1
UPLobbyShipEquipping.bShipListVisible = false

local function GetPreparationComponent()
    return GamePlayerSelfHelper:Get().ShipPreparationComponent
end

local function SetShipListVisible(self, bVisible, bWithAnim)
    self.bShipListVisible = bVisible
    if bVisible then
        local tbShipList = GetPreparationComponent():GetUnequippedShipTemplates()
        if #tbShipList > 0 then
            self.ListHelper:SetData(tbShipList)
            self.ListHelper:ScrollToTopLeft(false)
            self.pWidgetRef.vboxEmpty:SetVisibility(ESlateVisibility.Collapsed)
            self.pWidgetRef.listShip:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        else
            self.pWidgetRef.vboxEmpty:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            self.pWidgetRef.listShip:SetVisibility(ESlateVisibility.Collapsed)
        end
        if bWithAnim then
            self:PlayAnimation("animShowShipList", 0, 1, EUMGSequencePlayMode.Forward, 1, function()
                --引导需要知道动画结束
            end)
        else
            self.pWidgetRef.cvsShipList:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        end
    else
        if bWithAnim then
            self:PlayAnimation("animHideShipList", 0, 1, EUMGSequencePlayMode.Forward, 1)
        else
            self.pWidgetRef.cvsShipList:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
end

local function RequestUnequipShip(self, nShipSlotId)
    GetPreparationComponent():RequestUnequipShip(nShipSlotId)
end

local function RequestUnlockShipSlot(self, nShipSlotId)
    if nShipSlotId > 1 and (not self.tbShipEquippingItem[nShipSlotId - 1]:IsUnlocked()) then
        UIUtils.ShowToastWithKey("LOBBY_SHIP_UNLOCK_SLOT_TIPS")
    else
        local nPrice = ShipSlotDataTable:GetTemplate(nShipSlotId).nPrice
        local l10nTitle = UISetUtils.GetL10NTextByKey("LOBBY_SHIP_UNLOCK_SLOT_DILOG_TITLE")
        local l10nMessage = UISetUtils.GetL10NTextByKey("LOBBY_SHIP_UNLOCK_SLOT_DILOG_MESSAGE")
        l10nMessage = L10N:Format(l10nMessage, nPrice)
        UIUtils.ShowChoiceDialog(l10nTitle, l10nMessage, function()
            GetPreparationComponent():RequestUnlockShipSlot(nShipSlotId)
        end)
    end
end

local function OnListSelectedChanged(self, nIndex)
    SetShipListVisible(self, false, true)
    local tbSelectedData = self.ListHelper:GetSelectedData()
    GetPreparationComponent():RequestEquipShip(self.nCurrentSlotIndex, tbSelectedData.nId)
end

-- 点击退出列表按钮
local function OnClickedBtnCloseList(self)
    SetShipListVisible(self, false, true)
end

-- 收到装备舰船结果
local function OnReceiveEquipShipResult(self, nSlotId, nTemplateId)
    self.tbShipEquippingItem[nSlotId]:SetShipItemId(nTemplateId)
end

-- 收到卸载舰船结果
local function OnReceiveUnequipShipResult(self, nSlotId)
    self.tbShipEquippingItem[nSlotId]:SetShipItemId(nil)
end

local function OnReceiveUnlockShipSlotResult(self, nSlotId)
    self.tbShipEquippingItem[nSlotId]:Unlock()
end

local function OnAddItem(self, Item)
    local nItemTemplateId = Item:GetTemplateId()
    for _, v in pairs(self.tbShipEquippingItem) do
        if v:GetShipTemplateId() == nItemTemplateId then
            v:UnlockShip()
        end
    end
end

local function OnItemChangeExpiredAt(self, nItemInstanceId, bPermanent)
    if not bPermanent then
        return
    end
    local Item = ItemSystem:GetItem(nItemInstanceId)
    OnAddItem(self, Item)
end

local function OnReceiveShipSkinChanged(self, nTemplateId, nShipSkinId)
    for _, v in pairs(self.tbShipEquippingItem) do
        if v:GetShipTemplateId() == nTemplateId then
            v:UpdateShipSkin(nShipSkinId)
        end
    end
    if self.bShipListVisible then
        SetShipListVisible(self, true, false)
    end
end

function UPLobbyShipEquipping:OnLoad()
    self.tbShipEquippingItem = {}

    local tbUnlockedShipSlots = GetPreparationComponent():GetUnlockedShipSlots()
    local tbEquippedShipIds = GetPreparationComponent():GetEquippedShipIds()
    for i = 1, MAX_EQUIPPED_COUNT do
        local tbShipEquippingItem = self.PrefabHelper:BindPrefab(self.pWidgetRef["pbShipEquippingItem_"..i])
        tbShipEquippingItem:SetSlotInfo(tbUnlockedShipSlots[i], tbEquippedShipIds[i])
        tbShipEquippingItem:SetOnClickedEquipCallback(function()
            self.nCurrentSlotIndex = i
            SetShipListVisible(self, true, true)
        end)
        tbShipEquippingItem:SetOnClickedUnequipCallback(function()
            RequestUnequipShip(self, i)
        end)
        tbShipEquippingItem:SetOnClickedUnlockCallback(function()
            RequestUnlockShipSlot(self, i)
        end)
        self.tbShipEquippingItem[i] = tbShipEquippingItem
    end

    self.ListHelper = SelfListHelperNew()
    self.ListHelper:Init(self, self.pWidgetRef.listShip)
    self.ListHelper.OnSelectedChangedDelegate:Bind(OnListSelectedChanged, self)
    self.ListHelper.tbExtraDatas.fnShipExpired = function()
        SetShipListVisible(self, true, false)
    end
end

function UPLobbyShipEquipping:OnUnload()
    self.ListHelper:Uninit()
    self.ListHelper = nil
end

function UPLobbyShipEquipping:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnCloseList.OnClicked, self, OnClickedBtnCloseList)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnCloseListArea.OnClicked, self, OnClickedBtnCloseList)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_EQUIP_SHIP_RESULT, self, OnReceiveEquipShipResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_UNEQUIP_SHIP_RESULT, self, OnReceiveUnequipShipResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_UNLOCK_SHIP_SLOT_RESULT, self, OnReceiveUnlockShipSlotResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SHIP_SKIN_CHANGED, self, OnReceiveShipSkinChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_ADD_LOBBY_ITEM, self, OnAddItem)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHANGE_LOBBY_ITEM_EXPIRED_AT, self, OnItemChangeExpiredAt)
end

function UPLobbyShipEquipping:Deactivate()
    SetShipListVisible(self, false, false)
end

return UPLobbyShipEquipping