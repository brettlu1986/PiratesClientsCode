local luaclass          = require ("luaclass")
local ListItemBase      = require("ListItemBase")
local UPLobbyItemSub    = luaclass("UPLobbyItemSub", ListItemBase)

local LobbyItemUiHelper = require("LobbyItemUiHelper")
local ItemDataTable = require("ItemDataTable")
local UIToolTipHelper = require("UIToolTipHelper")

UPLobbyItemSub.nItemTemplateId = nil
UPLobbyItemSub.nCount = 0
UPLobbyItemSub.bAsync = nil
UPLobbyItemSub.tbData = nil

local function OnPressed(self)
    local tbTipData = {}
    local nItemTemplateId = self.nItemTemplateId
    local pWidgetRef = self.pWidgetRef.btnItem
    local nCount = self.nCount
    tbTipData.tbResTemplate = ItemDataTable:GetResTemplate(nItemTemplateId)
    tbTipData.tbTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    tbTipData.nCount = nCount
    UIToolTipHelper:ShowTipInAutoLayout(UIToolTipHelper.TipType.ITEM_TIP,tbTipData,pWidgetRef)
    local OnItemPressedDelegate = self.OnItemPressedDelegate
    if OnItemPressedDelegate then
        OnItemPressedDelegate:Fire(nItemTemplateId, self.tbData)
     end    
end

local function OnReleased(self)
    UIToolTipHelper:HideTip()
end

function UPLobbyItemSub:SetItemIcon(nItemTemplateId)
    if self.bAsync then
        LobbyItemUiHelper.SetAsyncIconImage(self.pWidgetRef, nItemTemplateId)
    else
        LobbyItemUiHelper.SetIconImage(self.pWidgetRef, nItemTemplateId)
    end
end

function UPLobbyItemSub:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnPressed, self, OnPressed)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnReleased, self, OnReleased)
end

function UPLobbyItemSub:SetVisible(bVisible)
    self.pWidgetRef:SetVisibility(bVisible and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
end

function UPLobbyItemSub:OnRefresh(tbData)
    self.tbData = tbData
    self:SetVisible(true)
    self.nItemTemplateId = tbData.nItemTemplateId
    self.OnItemPressedDelegate = tbData.OnItemPressedDelegate

    local pWidgetRef = self.pWidgetRef

    local tbItemTemplate = ItemDataTable:GetTemplate(tbData.nItemTemplateId)

    local nGrade = tbItemTemplate.nGrade
    local nCategory = tbItemTemplate.nCategory
    self.bAsync = tbData.bAsync
    LobbyItemUiHelper.SetGradeColorImage(pWidgetRef, tbItemTemplate.nGrade)
    self:SetItemIcon(tbData.nItemTemplateId)
    LobbyItemUiHelper.SetGradeImage(pWidgetRef, nCategory, nGrade)

    LobbyItemUiHelper.SetSelected(pWidgetRef, false)
    self.nCount = tbData.nCount
    if tbData.nCount == nil or tbData.nCount == 0 then
        LobbyItemUiHelper.SetCount(pWidgetRef, "")
    else
        LobbyItemUiHelper.SetCount(pWidgetRef, tbData.nCount)
    end

    LobbyItemUiHelper.SetButtonCanClick(pWidgetRef, tbData.bCanClick)

    LobbyItemUiHelper.ShowTryTxt(pWidgetRef, self.nItemTemplateId)

    if self.ListHelper then
        LobbyItemUiHelper.SetSelected(pWidgetRef, self.ListHelper.nSelectedIdx == self.tbData.nIndex)
    end
end

return UPLobbyItemSub
