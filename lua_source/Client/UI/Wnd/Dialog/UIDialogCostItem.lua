-----------------------------------------------------
--File Name    : UIDialogCostItem.lua
--Author       : Chang Nan
--Create Time  : 2017-03-24
--Description  : 消耗道具弹窗
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIDef = require ("UIDef")
local UIDialogCostItem = luaclass("UIDialogCostItem", WndBase)
local UISetUtils = require("UISetUtils")

local L10N_COST_TEXT = UISetUtils.GetL10NTextByKey("UIDIALOGCOSTITEM_L10N_COST_TEXT")

UIDialogCostItem.UPDialogCommon = nil
UIDialogCostItem.UPBackPackListItem = nil
UIDialogCostItem.UPMoneyCost = nil

local function BindDialogCommon(self)
    local UPDialogCommon = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbDialogCommon)
    local UPBackPackListItem = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbBackPackListItem)
    local UPMoneyCost = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbMoneyCost)
    UPDialogCommon.szCurrentDialogType = UIDef.UI_DIALOG_COST_ITEM
    self.UPDialogCommon = UPDialogCommon
    self.UPBackPackListItem = UPBackPackListItem
    self.UPMoneyCost = UPMoneyCost


end

function UIDialogCostItem:OnLoad()
    BindDialogCommon(self)
end

function UIDialogCostItem:OnShow()
    self.UPDialogCommon:PlayEnterAnim()
end




--设置材料数量，金钱数量等消耗信息
local function SetCostMoneyInfo(self, tbCostMoneyInfo)
    local pWidgetRef = self.pWidgetRef
    self.UPBackPackListItem:RefreshMultiCost(tbCostMoneyInfo.nCostFomulationId, tbCostMoneyInfo.nCostMultiple)
    pWidgetRef.txtCost:SetText(tbCostMoneyInfo.szCostTxt or L10N_COST_TEXT)
    self.UPMoneyCost:SetData(tbCostMoneyInfo.nGold, tbCostMoneyInfo.nSilver, true)
end



-- 显示材料消耗消息框
--     szCostTxt   --金钱前方的文字
--     nCostFomulationId  --配方ID
--     nCostMultiple --消耗倍数
--     nGold  --花费的金币数量
--     nSilver  --花费的银币数量
--     szBtnConfirmTxt  --确认按钮上的文字
--     funConfirm --确认按钮的点击事件
--     bWithoutCancel --是否需要取消按钮，为true表示不需要取消按钮
------------------------------------------
function UIDialogCostItem:ShowCostItemDialog(szTitle, szCost, nFomulationId, nMultiple, nGold, nSilver, szBtnConfirmTxt, funConfirm, bWithoutCancel, sztip)
    local tbCostMoneyInfo = {}
    tbCostMoneyInfo.szCostTxt = szCost
    tbCostMoneyInfo.nCostFomulationId = nFomulationId
    tbCostMoneyInfo.nCostMultiple = nMultiple
    tbCostMoneyInfo.nGold = nGold
    tbCostMoneyInfo.nSilver = nSilver

    local tbCommonData = {}
    tbCommonData.szBtnConfirmTxt = szBtnConfirmTxt
    tbCommonData.funOK = funConfirm

    SetCostMoneyInfo(self,tbCostMoneyInfo)
    if bWithoutCancel == true then
        self.UPDialogCommon:HideLeftButton()
    else
        self.UPDialogCommon:ShowCommonButton()
    end

    if sztip then
        self.pWidgetRef.txtDurability:SetVisibility(ESlateVisibility.Visible)
        self.pWidgetRef.txtDurability:SetText(sztip)
    else
        self.pWidgetRef.txtDurability:SetVisibility(ESlateVisibility.Collapsed)
    end
    self.UPDialogCommon:SetDialogCommonData(szTitle, tbCommonData)
    self.UPBackPackListItem:SetItemHorizontalAlignment(EHorizontalAlignment.HAlign_Center)
end

function UIDialogCostItem:CloseDialog()
    if self.UPDialogCommon.pWidgetRef ~= nil then
        self.UPDialogCommon:PlayHideAnim()
    end
end

---------------------------
------------对":"的理解
--语句1
--self.UPBackPackListItem:SetItemHorizontalAlignment()

--语句2
--self.UPBackPackListItem.SetItemHorizontalAlignment(self.UPBackPackListItem)

--语句3
--UPBackPackListItem = require("UPBackPackListItem")
--UPBackPackListItem.SetItemHorizontalAlignment(UPBackPackListItem)

--以上三段语句为等价关系

--------------


return UIDialogCostItem
