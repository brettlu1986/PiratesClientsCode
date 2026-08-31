-----------------------------------------------------
--File Name    : UPSailorSlotItem.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-20
--Description  : 水手装备页面中左侧槽位Item
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSailorSlotItem = luaclass("UPSailorSlotItem", PrefabBase)

local L10N = require("L10N")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local ItemSystem = require("ItemSystem")
local LuaDelegate = require("LuaDelegate")
local UIResourceDef = require("UIResourceDef")
local SailorCategoryDef = require("SailorCategoryDef")
local SailorSlotDataTable = require("SailorSlotDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

UPSailorSlotItem.nSailorId = nil
UPSailorSlotItem.nSailorCategory = -1
UPSailorSlotItem.bUnlocked = false
UPSailorSlotItem.bAllowPurchase = false
UPSailorSlotItem.bSelected = false
UPSailorSlotItem.OnItemSelected = nil

local SAILOR_BG_COLOR = {
    [SailorCategoryDef.Cannon]      = KMUMGLibrary.GetLinearColor(1         , 0.521569  , 0.509804  , 1),
    [SailorCategoryDef.Deck]        = KMUMGLibrary.GetLinearColor(0.686275  , 1         , 0.654902  , 1),
    [SailorCategoryDef.Logistics]   = KMUMGLibrary.GetLinearColor(0.439216  , 0.486275  , 1         , 1)
    -- [SailorCategoryDef.Cannon] = KMUMGLibrary.GetLinearColorFromHex("FF8582FF"),
    -- [SailorCategoryDef.Deck] = KMUMGLibrary.GetLinearColorFromHex("AFFFA7FF"),
    -- [SailorCategoryDef.Logistics] = KMUMGLibrary.GetLinearColorFromHex("707CFFFF")
}

local function ShowPurchaseDialog(self)
    local tbPrice = SailorSlotDataTable:GetSlotPrice(self.nSailorCategory, self.nSlotIndex)
    local l10nTitle = UISetUtils.GetL10NTextByKey("SAILOR_SLOT_PURCHASE_TITLE")
    local l10nMessage = L10N:Format(UISetUtils.GetL10NTextByKey("SAILOR_SLOT_PURCHASE_MESSAGE"), tbPrice.nPrice)
    UIUtils.ShowChoiceDialog(l10nTitle, l10nMessage, function()
        GamePlayerSelfHelper:Get().SailorComponent:RequestUnlockSailorSlot(self.nSailorCategory, self.nSlotIndex)
    end)
end

local function OnClickedBtnSailor(self)
    if self.bUnlocked then
        self:Select()
    elseif self.bAllowPurchase then
        ShowPurchaseDialog(self)
    else
        local nGrade = SailorSlotDataTable:GetSlotUnlockGrade(self.nSailorCategory, self.nSlotIndex)
        local l10nMessage = L10N:Format(UISetUtils.GetL10NTextByKey("SAILOR_SLOT_AUTO_UNLOCK_TIPS"), nGrade)
        UIUtils.ShowToast(l10nMessage)
    end
end

function UPSailorSlotItem:OnLoad()
    self.OnItemSelected = LuaDelegate()
end

function UPSailorSlotItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSailor.OnClicked, self, OnClickedBtnSailor)
end

-- 设置槽位基本信息
function UPSailorSlotItem:SetSlotInfo(nSailorCategory, nSlotIndex)
    self.nSailorCategory = nSailorCategory
    self.nSlotIndex = nSlotIndex
end

-- 设置槽位上水手
function UPSailorSlotItem:SetSailorId(nSailorId, bWithAnim)
    self.nSailorId = nSailorId
    if nSailorId then
        local tbTemplate = ItemSystem:GetItemTemplate(nSailorId)
        local tbResTemplate = ItemSystem:GetItemResTemplate(nSailorId)
        self.pWidgetRef.imgIcon:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.pWidgetRef.imgGrade:SetVisibility(ESlateVisibility.HitTestInvisible)
        UISetUtils.SetImageBrushRes(self.pWidgetRef.imgIcon, tbResTemplate.szIconPath:load())
        UISetUtils.SetImageBrushRes(self.pWidgetRef.imgGrade, UIResourceDef.SAILOR_GRADE_ICONS[tbTemplate.nGrade + 1]:load())
        if bWithAnim then
            self:PlayAnimation("animAddItem", 0, 1, EUMGSequencePlayMode.Forward, 1)
        end
    else
        self.pWidgetRef.imgIcon:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.imgGrade:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UPSailorSlotItem:SetEquippingData(tbData)
    if tbData and tbData.bUnlocked then
        self:Unlock()
        self:SetSailorId(tbData.nSailorId)
    end
end

-- 获取当前槽位分类
function UPSailorSlotItem:GetSailorCategory()
    return self.nSailorCategory
end

-- 获取当前槽位序号
function UPSailorSlotItem:GetSlotIndex()
    return self.nSlotIndex
end

-- 获取槽位上的水手ITem
function UPSailorSlotItem:GetSailorId()
    return self.nSailorId
end

-- 是否为空的解锁槽位
function UPSailorSlotItem:IsEmptyUnlockedSlot()
    return (self.nSailorId == nil) and self.bUnlocked
end

-- 选中Slot
function UPSailorSlotItem:Select()
    if not self.bSelected then
        self.bSelected = true
        local pWidgetRef = self.pWidgetRef
        pWidgetRef.imgSelected:SetVisibility(ESlateVisibility.HitTestInvisible)
        -- pWidgetRef:PlayAnimation(pWidgetRef.animSelected, 0, 0, EUMGSequencePlayMode.PingPong, 1)
        self.OnItemSelected:Fire(self)
    end
end

-- 取消选中Slot
function UPSailorSlotItem:Unselect()
    if self.bSelected then
        self.bSelected = false
        local pWidgetRef = self.pWidgetRef
        pWidgetRef.imgSelected:SetVisibility(ESlateVisibility.Collapsed)
        -- pWidgetRef:StopAnimation(pWidgetRef.animSelected)
    end
end

-- 解锁Slot
function UPSailorSlotItem:Unlock()
    self.bUnlocked = true
    self.pWidgetRef.imgLock:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.txtOpenGrade:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.imgPurchase:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.imgBg:SetColorAndOpacity(SAILOR_BG_COLOR[self.nSailorCategory])
end

-- 设置Slot为等级解锁样式
function UPSailorSlotItem:SetUnlockTipsByGrade(nUnlockGrade)
    self.bAllowPurchase = true
    self.pWidgetRef.imgLock:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.imgPurchase:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.txtOpenGrade:SetVisibility(ESlateVisibility.HitTestInvisible)
    self.pWidgetRef.imgBg:SetColorAndOpacity(SAILOR_BG_COLOR[self.nSailorCategory])
    self.pWidgetRef.txtOpenGrade:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("SAILOR_SLOT_LEVEL_TIPS"), nUnlockGrade))
end

-- 设置Slot为金币解锁样式
function UPSailorSlotItem:SetUnlockTipsByCoin()
    self.bAllowPurchase = true
    self.pWidgetRef.imgLock:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.txtOpenGrade:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.imgPurchase:SetVisibility(ESlateVisibility.HitTestInvisible)
    self.pWidgetRef.imgBg:SetColorAndOpacity(SAILOR_BG_COLOR[self.nSailorCategory])
end

return UPSailorSlotItem