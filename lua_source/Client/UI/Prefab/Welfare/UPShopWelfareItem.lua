local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPShopWelfareItem = luaclass("UPLobbyShopItem2", ListItemBase)
local ItemDataTable = require("ItemDataTable")
local VipCardDataTable = require("VipCardDataTable")
local AwardDataTable = require("AwardDataTable")
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")
local ClientEventDef = require("ClientEventDef")
local TimeUtil = require("TimeUtil")
local WelfareHelper = require("WelfareHelper")
local UIUtils = require("UIUtils")

UPShopWelfareItem.nType = -1

local tbState = 
{
    CAN_GET = 1,
    BUY = 2, 
    ALREADY_GET = 3,
}

function UPShopWelfareItem:OnLoad()
end

local function OnBuy(self)
    self.EventHelper:FireEvent(ClientEventDef.EV_GO_TO_SHOP_ITEM)
end

local function OnGet(self)
    WelfareHelper.RequestGetVipAward(self.nType)
    UIUtils.ShowWaitingPacket()
end

function UPShopWelfareItem:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnBuy.OnClicked, self, OnBuy)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnGet.OnClicked, self, OnGet)
end

local function UpdateBtnState(self, nState)
    local pWidgetRef = self.pWidgetRef 

    pWidgetRef.bdrHasGet:SetVisibility(nState == tbState.ALREADY_GET and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
    pWidgetRef.btnBuy:SetVisibility(nState == tbState.BUY and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
    pWidgetRef.btnGet:SetVisibility(nState == tbState.CAN_GET and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
   
end

function UPShopWelfareItem:OnRefresh(tbData)
    -- logdebug("UPLobbyShopItem2 refresh item ", tbData.nItemId, tbData.nCount)

    self.nType = tbData.nCardIndex
    local pWidgetRef = self.pWidgetRef  
    pWidgetRef.txtCardName:SetText(tbData.l10nName)

    local tbItemResTemplate = ItemDataTable:GetResTemplate(tbData.nId)
    local szRes = tbItemResTemplate.szIconPath
    UISetUtils.SetImageBrushRes(pWidgetRef.resIcon, szRes:load())

    local nDay = VipCardDataTable:GetRewardDays(tbData.nCardIndex)
    local l10nDayCount = L10N:Format(UISetUtils.GetL10NTextByKey("WELFARE_CONTINUE_GET"), nDay)
    pWidgetRef.txtContinueGet:SetText(l10nDayCount)

    local nRewardId = VipCardDataTable:GetRewardItemId(tbData.nCardIndex, 1)
    local tbItems = AwardDataTable:GetAwardItem(nRewardId)
    local tbItem = tbItems[1]

    szRes = ItemDataTable:GetResTemplate(tbItem.nItemId).szIconPath
    UISetUtils.SetImageBrushRes(pWidgetRef.rewardImg, szRes:load())
    pWidgetRef.txtNumber:SetText(tbItem.nCount)

    local tbVipCardsInfos = WelfareHelper.GetAllWelfareItems()
    if tbVipCardsInfos == nil then  
        UpdateBtnState(self, tbState.BUY)
        pWidgetRef.txtLeftDays:SetVisibility(ESlateVisibility.Collapsed)
    else   
        local tbVipCard = tbVipCardsInfos[tbData.nCardIndex]
        if tbVipCard == nil then   
            UpdateBtnState(self, tbState.BUY)
            pWidgetRef.txtLeftDays:SetVisibility(ESlateVisibility.Collapsed)
        else  
            local bCanGetToday = TimeUtil.GetDayOfYearOffset(tbVipCard.receive_timestamp) >= 1 and tbVipCard.remain_times > 0
            if bCanGetToday then   
                UpdateBtnState(self, tbState.CAN_GET)
            else 
                if tbVipCard.remain_times <= 0 then  
                    UpdateBtnState(self, tbState.BUY)
                else   
                    UpdateBtnState(self, tbState.ALREADY_GET)
                end
            end

            if tbVipCard.remain_times > 0 then
                local l10nLeftCount = L10N:Format(UISetUtils.GetL10NTextByKey("MAIL_TIME_DAYS_REMAINING"), tbVipCard.remain_times)
                pWidgetRef.txtLeftDays:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
                pWidgetRef.txtLeftDays:SetText(l10nLeftCount)
            else  
                pWidgetRef.txtLeftDays:SetVisibility(ESlateVisibility.Collapsed)
            end
        end
    end
end


return UPShopWelfareItem
