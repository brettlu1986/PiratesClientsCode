-----------------------------------------------------
--File Name    : UIDialogTrade.lua
--Author       : Chang Nan
--Create Time  : 2017-03-24
--Description  : 缴纳或收取钱币弹窗
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIDef = require ("UIDef")
local UIDialogTrade = luaclass("UIDialogTrade", WndBase)

UIDialogTrade.UPDialogCommon = nil
UIDialogTrade.UPMoneyCost01 = nil
UIDialogTrade.UPMoneyCost02 = nil
local function BindTitleBarUp(self)
    local UPDialogCommon = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbDialogCommon)
    local UPMoneyCost = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbMoneyCost)
    local UP_MoneyCost_C_0 = self.PrefabHelper:BindPrefab(self.pWidgetRef.UP_MoneyCost_C_0)
    self.UPDialogCommon = UPDialogCommon
    self.UPMoneyCost01 = UPMoneyCost
    self.UPMoneyCost02 = UP_MoneyCost_C_0
    UPDialogCommon.szCurrentDialogType = UIDef.UI_DIALOG_TRADE
end

function UIDialogTrade:OnLoad()
    BindTitleBarUp(self)
end

function UIDialogTrade:OnShow()
    self.UPDialogCommon:PlayEnterAnim()
end


--设置金钱信息
local function SetMoneyInfo(self, tbCostMoneyInfo)
    local pWidgetRef = self.pWidgetRef
    local tbCostInfo01 = tbCostMoneyInfo.tbCost01
    local tbCostInfo02 = tbCostMoneyInfo.tbCost02
    if tbCostInfo01 ~= nil then
        pWidgetRef.hboxShipCost01:SetVisibility(ESlateVisibility.Visible)
        pWidgetRef.txtCost01:SetText(tbCostInfo01.szCostTxt)
        self.UPMoneyCost01:SetData(tbCostInfo01.nGold, tbCostInfo01.nSilver, tbCostMoneyInfo.bCost)
    else
        pWidgetRef.hboxShipCost01:SetVisibility(ESlateVisibility.Collapsed)
    end

    if tbCostInfo02 ~= nil then
        pWidgetRef.hboxShipCost02:SetVisibility(ESlateVisibility.Visible)
        pWidgetRef.txtCost02:SetText(tbCostInfo02.szCostTxt)
        self.UPMoneyCost02:SetData(tbCostInfo02.nGold, tbCostInfo02.nSilver, tbCostMoneyInfo.bCost)
    else
        pWidgetRef.hboxShipCost02:SetVisibility(ESlateVisibility.Collapsed)
    end
end


-- 显示交易对话框
-- szTitle          标题文本
-- szMessage        信息文本
-- bCost            true表示消耗，false表示给予
-- szCostTxt01      第一行价格标题文本
-- nGold01          第一行金币数量
-- nSilver01        第一行银币数量
-- szCostTxt02      第二行价格标题文本
-- nGold02          第二行金币数量
-- nSilver02        第二行银币数量
-- szBtnOKText      确认按钮文本
-- szBtnCancelText  取消按钮文本
-- funcOK           确认按钮点击事件
-- 如果需要只显示一行金钱信息 将szCostTxt01 = "" , nGold01 = 0, nSilver01 = 0
-- 为了排版好看所以隐藏的时候隐藏第一行
function UIDialogTrade:ShowTradeDialog(szTitle, szMessage, bCost, szCostTxt01, nGold01, nSilver01, szCostTxt02, nGold02, nSilver02, szBtnOKText, szBtnCancelText, funcOK)
    local pWidgetRef = self.pWidgetRef
    local tbCost01 = {}
    tbCost01.szCostTxt = szCostTxt01
    tbCost01.nGold = nGold01
    tbCost01.nSilver = nSilver01
    if tbCost01.szCostTxt == "" then
        tbCost01 = nil
    end
    local tbCost02 = {}    
    tbCost02.szCostTxt = szCostTxt02
    tbCost02.nGold = nGold02
    tbCost02.nSilver = nSilver02
    if tbCost02.szCostTxt == "" then
        tbCost02 = nil
    end
    local tbTradeInfo = {}
    tbTradeInfo.szMessage = szMessage
    tbTradeInfo.tbCost01 = tbCost01
    tbTradeInfo.tbCost02 = tbCost02
    tbTradeInfo.bCost = bCost
    local tbCommonBtnData = {}
    tbCommonBtnData.szBtnOKText = szBtnOKText
    tbCommonBtnData.szBtnCancelText = szBtnCancelText
    tbCommonBtnData.funOK = funcOK
    self.UPDialogCommon:ShowCommonButton()
    self.UPDialogCommon:SetDialogCommonData(szTitle, tbCommonBtnData)
    pWidgetRef.rtxtDesc:SetText(tbTradeInfo.szMessage) 
    SetMoneyInfo(self , tbTradeInfo)
    
end


function UIDialogTrade:CloseDialog()
    if self.UPDialogCommon.pWidgetRef ~= nil then
        self.UPDialogCommon:PlayHideAnim()
    end
end


return UIDialogTrade