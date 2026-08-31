local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPRouletteLuckyItem = luaclass("UPRouletteLuckyItem", PrefabBase)
local UIToolTipHelper = require("UIToolTipHelper")
local ItemDataTable = require("ItemDataTable")
local UISetUtils = require("UISetUtils")

UPRouletteLuckyItem.nItemTemplateId = nil
UPRouletteLuckyItem.nCount = nil

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

function UPRouletteLuckyItem:OnBindEvent(EventHelper)
    local btnItem = self.pWidgetRef.btnItem
    EventHelper:RegisterCppDelegate(btnItem.OnPressed, self, OnPressed)
    EventHelper:RegisterCppDelegate(btnItem.OnReleased, self, OnReleased)
end

function UPRouletteLuckyItem:OnLoad()
end

function UPRouletteLuckyItem:OnDestroy()
end

function UPRouletteLuckyItem:SetDisplayItemData(nTemplateId, nCount)
    self.nItemTemplateId = nTemplateId
    self.nCount = nCount

    local pWidgetRef = self.pWidgetRef
    local tbItemResTemplate = ItemDataTable:GetResTemplate(nTemplateId)
    local szIconPath = tbItemResTemplate.szIconPath
    UISetUtils.SetImageBrushRes(pWidgetRef.imgItem, szIconPath:load())

    pWidgetRef.txtCount:SetText(nCount)
end

function UPRouletteLuckyItem:SetSelected(bSelected, bPlayAnimation)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.imgSelect:SetVisibility(bSelected and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Collapsed)
    if bPlayAnimation and bSelected then
        self:PlayAnimation("animGetFlash", 0, 1, EUMGSequencePlayMode.Forward)
    end
end

return UPRouletteLuckyItem