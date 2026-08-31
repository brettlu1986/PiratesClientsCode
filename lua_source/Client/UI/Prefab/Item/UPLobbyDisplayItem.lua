local luaclass          = require ("luaclass")
local PrefabBase        = require("PrefabBase")
local UPLobbyDisplayItem    = luaclass("UPLobbyDisplayItem", PrefabBase)

local LobbyItemUiHelper = require("LobbyItemUiHelper")
local ItemDataTable = require("ItemDataTable")
local UIToolTipHelper = require("UIToolTipHelper")
local UIResourceDef = require("UIResourceDef")
local ItemCategoryDef = require("ItemCategoryDef")
local ItemSystem = require("ItemSystem")
local HomelandSystem = require("HomelandSystem")
local ClientEventDef = require("ClientEventDef")
local UIDef = require("UIDef")

UPLobbyDisplayItem.nItemTemplateId = nil
UPLobbyDisplayItem.nCount = 0

local function OnPressed(self)
    local tbTipData = {}
    local nItemTemplateId = self.nItemTemplateId
    local pWidgetRef = self.pWidgetRef.btnItem
    local nCount = self.nCount
    tbTipData.tbResTemplate = ItemDataTable:GetResTemplate(nItemTemplateId)
    tbTipData.tbTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    tbTipData.nCount = nCount
    UIToolTipHelper:ShowTipInAutoLayout(UIToolTipHelper.TipType.ITEM_TIP,tbTipData,pWidgetRef)
end

local function OnReleased(self)
    UIToolTipHelper:HideTip()
end

local function OnAutoReleased(self, szWndName)
    if szWndName ~= UIDef.UI_TOOL_TIP then
        OnReleased(self)
    end
end

local function SetCountColor(self, color)
    self.pWidgetRef.txtCount:SetColorAndOpacity(color)
end

function UPLobbyDisplayItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnPressed, self, OnPressed)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnReleased, self, OnReleased)
    EventHelper:RegisterEvent(ClientEventDef.EV_OPEN_UI, self, OnAutoReleased)
    EventHelper:RegisterEvent(ClientEventDef.EV_PRE_CLOSE_UI, self, OnAutoReleased)
end

function UPLobbyDisplayItem:SetVisible(bVisible)
    self.pWidgetRef:SetVisibility(bVisible and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
end

local function GetItemCount(tbItemTemplate)
    local nCategory = tbItemTemplate.nCategory
    local nItemTemplateId = tbItemTemplate.nId
    if nCategory == ItemCategoryDef.DECORATIVE_BUILDING then
        local HomelandItemSystem = HomelandSystem:GetSubSystem("HomelandItemSystem")
        return HomelandItemSystem:GetAvailableItemCount(nItemTemplateId)
    end
    return ItemSystem:GetItemCount(nItemTemplateId)
end

function UPLobbyDisplayItem:SetItemIcon(nItemTemplateId)
    LobbyItemUiHelper.SetIconImage(self.pWidgetRef, nItemTemplateId)
end

function UPLobbyDisplayItem:SetDisplayItemData(nItemTemplateId, nCount, bCanClick, bIsCost, nMultiple)
    self:SetVisible(true)
    self.nItemTemplateId = nItemTemplateId

    local pWidgetRef = self.pWidgetRef

    local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)

    local nGrade = tbItemTemplate.nGrade
    local nCategory = tbItemTemplate.nCategory
    LobbyItemUiHelper.SetGradeColorImage(pWidgetRef, tbItemTemplate.nGrade)
    self:SetItemIcon(nItemTemplateId)
    LobbyItemUiHelper.SetGradeImage(pWidgetRef, nCategory, nGrade)

    LobbyItemUiHelper.SetSelected(pWidgetRef, false)
    self.nCount = nCount
    if nCount == nil or nCount == 0 then
        LobbyItemUiHelper.SetCount(pWidgetRef, "")
    else
        LobbyItemUiHelper.SetCount(pWidgetRef, nCount)
    end
    SetCountColor(self, UIResourceDef.COLOR.WHITE.SLATE_COLOR)

    if bIsCost then
        local nItemCount = GetItemCount(tbItemTemplate)
        if nItemCount < nCount then
            SetCountColor(self, UIResourceDef.COLOR.RED.SLATE_COLOR)
        end
    end

    LobbyItemUiHelper.SetButtonCanClick(pWidgetRef, bCanClick)

    LobbyItemUiHelper.ShowTryTxt(pWidgetRef, nItemTemplateId)

    LobbyItemUiHelper.ShowMultiple(pWidgetRef, nMultiple)
end

-- function UPLobbyDisplayItem:SetItemGlow(bIsGlow)
--     local pWidgetRef = self.pWidgetRef
--     local visible = bIsGlow and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Hidden
--     pWidgetRef.imgGetGlow:SetVisibility(visible)
--     pWidgetRef.imgGetGlow2:SetVisibility(visible)
-- end

return UPLobbyDisplayItem
