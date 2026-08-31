-----------------------------------------------------
--File Name    : UIDialogGoodsFull.lua
--Author       : Chang Nan
--Create Time  : 2017-05-25
--Description  : 背包不足时显示无法拾取的道具
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIDef = require ("UIDef")
local UIDialogGoodsFull = luaclass("UIDialogGoodsFull", WndBase)
local UISetUtils = require("UISetUtils")


local TITLE_TEXT = UISetUtils.GetL10NTextByKey("UIDIALOGGOODSFULL_TITLE_TEXT")
local ITEM_ICON_COUNT = 4


UIDialogGoodsFull.UPDialogCommon = nil
UIDialogGoodsFull.tbItemIconPrefabList = nil
UIDialogGoodsFull.tbItemIconWidgetList = nil

local function BindPrefabs(self)
    self.tbItemIconPrefabList = {}
    self.tbItemIconWidgetList = {}
    local UPDialogCommon = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbDialogCommon)
    self.UPDialogCommon = UPDialogCommon
    UPDialogCommon.szCurrentDialogType = UIDef.UI_DIALOG_GOODS_FULL
    self.UPDialogCommon:HideCommonButton()

    for i = 1, ITEM_ICON_COUNT do
        local prefab = self.PrefabHelper:BindPrefab(self.pWidgetRef["pbBackPackItem0"..i])
        prefab:SetIsShowItemMark(false)
        prefab:SetIsShowTipButton(false)
        self.tbItemIconPrefabList[i] = prefab
        self.tbItemIconWidgetList[i] = self.pWidgetRef["pbBackPackItem0"..i]
    end



end

function UIDialogGoodsFull:OnLoad()
    BindPrefabs(self)
end

function UIDialogGoodsFull:OnShow()
    self.UPDialogCommon:PlayEnterAnim()
end


function UIDialogGoodsFull:ShowGoodsFullDialog(tbAwardList)
    local szTitle = TITLE_TEXT
    self.UPDialogCommon:SetDialogCommonData(szTitle,{szBtnOKText = "", szBtnCancelText = ""})
    for _,v in pairs(self.tbItemIconWidgetList) do
        v:SetVisibility(ESlateVisibility.Collapsed)
    end

    local nItemCount = #tbAwardList
    for i = 1, nItemCount do
        self.tbItemIconWidgetList[i]:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        local tbTemplate = tbAwardList[i].tbTemplate
        local nCount = tbAwardList[i].nCount
        self.tbItemIconPrefabList[i]:RefreshItemDisplay(tbTemplate, nCount)
    end


end

--事件绑定
function UIDialogGoodsFull:OnBindEvent()
    local Helper = self.EventHelper
    local pWidgetRef = self.pWidgetRef
    Helper:RegisterCppDelegate(pWidgetRef.btnClose.OnClicked, self, self.CloseDialog)
end


function UIDialogGoodsFull:CloseDialog()
    if self.UPDialogCommon.pWidgetRef ~= nil then
        self.UPDialogCommon:PlayHideAnim()
    end
end


return UIDialogGoodsFull
