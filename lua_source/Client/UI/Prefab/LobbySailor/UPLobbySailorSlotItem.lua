
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPLobbySailorSlotItem = luaclass("UPLobbySailorSlotItem", PrefabBase)
-- local ItemSystem = require("ItemSystem")
-- local SailorCategoryDef = require("SailorCategoryDef")
-- local UIResourceDef = require("UIResourceDef")
-- local UISetUtils = require("UISetUtils")
local LobbySailorHelper = require("LobbySailorHelper")
local LuaDelegate = require("LuaDelegate")

UPLobbySailorSlotItem.nSailorId = nil
UPLobbySailorSlotItem.bUnlocked = false
UPLobbySailorSlotItem.nSailorCategory = -1
UPLobbySailorSlotItem.nSlotIndex = nil
UPLobbySailorSlotItem.bSelected = false
UPLobbySailorSlotItem.OnItemSelected = nil

-- local SAILOR_BG_COLOR = {
--     [SailorCategoryDef.Cannon]      = KMUMGLibrary.GetLinearColor(1         , 0.521569  , 0.509804  , 1),
--     [SailorCategoryDef.Deck]        = KMUMGLibrary.GetLinearColor(0.686275  , 1         , 0.654902  , 1),
--     [SailorCategoryDef.Logistics]   = KMUMGLibrary.GetLinearColor(0.439216  , 0.486275  , 1         , 1)
-- }

local function OnClickedBtnSailor(self)
    if self.bUnlocked then
        self:Select()
    end
end

-- 选中Slot
function UPLobbySailorSlotItem:Select()
    if not self.bSelected then
        self.bSelected = true
        local pWidgetRef = self.pWidgetRef
        pWidgetRef.imgSelected:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.OnItemSelected:Fire(self)
        pWidgetRef.imgFxSelectedTrail:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self:PlayAnimation("animSelected", 0 , 1, EUMGSequencePlayMode.Forward, 1)
    end
end

-- 取消选中Slot
function UPLobbySailorSlotItem:Unselect()
    if self.bSelected then
        self.bSelected = false
        local pWidgetRef = self.pWidgetRef
        pWidgetRef.imgSelected:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.imgFxSelectedTrail:SetVisibility(ESlateVisibility.Collapsed)
        self:StopAnimation("animSelected")
    end
end

function UPLobbySailorSlotItem:OnLoad()
    self.OnItemSelected = LuaDelegate()
end

function UPLobbySailorSlotItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSailor.OnClicked, self, OnClickedBtnSailor)
end

-- 设置槽位基本信息
function UPLobbySailorSlotItem:SetSlotInfo(nSailorCategory, nSlotIndex)
    self.nSailorCategory = nSailorCategory
    self.nSlotIndex = nSlotIndex
end

-- 设置槽位上水手
function UPLobbySailorSlotItem:SetSailorId(nSailorId, bWithAnim)
    self.nSailorId = nSailorId
    if nSailorId then
        self.pWidgetRef.imgIcon:SetVisibility(ESlateVisibility.HitTestInvisible)
        -- self:PlayAnimation("animAddItem", 0 , 1, EUMGSequencePlayMode.Forward, 1)
        LobbySailorHelper.RefreshSailorItemResState(self.pWidgetRef.imgIcon, self.pWidgetRef.imgPattern, true, nSailorId)
    else
        self.pWidgetRef.imgIcon:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.imgPattern:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UPLobbySailorSlotItem:PlaySlotAddItem()
    self.pWidgetRef.imgFxSelectedTrail:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation("animAddItem", 0 , 1, EUMGSequencePlayMode.Forward, 1)
end

function UPLobbySailorSlotItem:PlayUnlockAnim()
    self.pWidgetRef.imgFxSelectedTrail:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation("animUnlock", 0 , 1, EUMGSequencePlayMode.Forward, 1)
end

function UPLobbySailorSlotItem:Unlock()
    self.bUnlocked = true
    self:StopAnimation("animSelected")
end

function UPLobbySailorSlotItem:SetEquippingData(tbData)
    self:Unlock()
    self:SetSailorId(tbData.nSailorId)
end

-- 获取当前槽位序号
function UPLobbySailorSlotItem:GetSlotIndex()
    return self.nSlotIndex
end

-- 获取当前槽位分类
function UPLobbySailorSlotItem:GetSailorCategory()
    return self.nSailorCategory
end

-- 获取槽位上的水手Item
function UPLobbySailorSlotItem:GetSailorId()
    return self.nSailorId
end

-- 是否为空的解锁槽位
function UPLobbySailorSlotItem:IsEmptyUnlockedSlot()
    return (self.nSailorId == nil) and self.bUnlocked
end

return UPLobbySailorSlotItem