
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbySailorSummoning = luaclass("UILobbySailorSummoning", WndBase)

local L10N = require("L10N")
local UIDef = require("UIDef")
local UIManager = require("UIManager")
local UISetUtils = require("UISetUtils")
local Proto = require("ClientProtoNames")
local CurrencyIni = require("CurrencyIni")
local UIResourceDef = require("UIResourceDef")
local ClientEventDef = require("ClientEventDef")
local CurrencySystem = require("CurrencySystem")
local SailorRedDotDef = require("SailorRedDotDef")
local UILobbySailorDef = require("UILobbySailorDef")
local CostCurrencyHelper = require("CostCurrencyHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local SailorSummonDataTable = require("SailorSummonDataTable")

local MAX_SUMMON_BUTTON_COUNT = 4
-- local SailorComponentCache = nil

local GetTextByKey = UISetUtils.GetTextByKey
local TIMEFORMAT = {
    GetTextByKey("COMMON_TIME_HOUR"),
    GetTextByKey("COMMON_TIME_MINUTE"),
    GetTextByKey("COMMON_TIME_SECOND")
}

local SAILOR_SUMMON_TIPS_POSTFIX = {
    [1] = GetTextByKey("SAILOR_SUMMON_TIPS_POSTFIX_GROUP_1"),
    [2] = GetTextByKey("SAILOR_SUMMON_TIPS_POSTFIX_GROUP_2"),
}

local UNEXCHANGED_ID = CurrencyIni.tbExchange.nUnchangedId

local szSummonIn = "animLobbySailorSummoningIn"
local szAnimHideBtns = "animHideButton"
local szAnimWidFrameBtns = "animHidden"

UILobbySailorSummoning.pbWindowFrame = nil

local function BackToPre(self)
    self.EventHelper:FireEvent(ClientEventDef.EV_LOBBYSAILOR_TO_PRE)
end

local function GetSailorComponent()
    -- if SailorComponentCache ==  nil then
    --     SailorComponentCache = GamePlayerSelfHelper:Get().SailorComponent
    -- end
    return GamePlayerSelfHelper:Get().SailorComponent
end

local function PlayUEAnim(self, szAnimName, fnCallback)
    local ueSummonSailor = self.pWidgetRef.ueSummonSailor
    self:PlayAnimationWithUserWidget(ueSummonSailor, szAnimName, 0, 1, EUMGSequencePlayMode.Forward, 1, fnCallback)
end

local function StopUEAnim(self, szAnimName)
    local ueSummonSailor = self.pWidgetRef.ueSummonSailor
    self:StopAnimationWithUserWidget(ueSummonSailor, szAnimName)
end

local function UpdateSummonEnable(self, nSummonId, bFree)
    local pWidgetRef = self.pWidgetRef

    local tbTemplate = SailorSummonDataTable:GetTemplate(nSummonId)
    local nCurrencyId = tbTemplate.nCurrencyId
    local szCurrencySmallIcon = CurrencySystem:GetCurrencySmallIcon(nCurrencyId)
    UISetUtils.SetImageBrushRes(pWidgetRef["imgSummonIcon_"..nSummonId], szCurrencySmallIcon:load())

    if bFree then
        pWidgetRef["btnSummon_"..nSummonId]:SetIsEnabled(true)
        pWidgetRef["btnSummon_"..nSummonId]:HideTipIcon(false)
        pWidgetRef["txtSummonPrice_"..nSummonId]:SetText(UISetUtils.GetL10NTextByKey("SAILOR_SUMMON_FREE"))
        pWidgetRef["txtSummonPrice_"..nSummonId]:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.SLATE_COLOR)
    else
        pWidgetRef["btnSummon_"..nSummonId]:HideTipIcon(true)
        local nCurrencyPrice = tbTemplate.nPrice
        pWidgetRef["txtSummonPrice_"..nSummonId]:SetText(nCurrencyPrice)
        pWidgetRef["btnSummon_"..nSummonId]:SetIsEnabled(true)
        pWidgetRef["txtSummonPrice_"..nSummonId]:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.SLATE_COLOR)
    end
end

local function ShowPriceFree(self, nSummonId)
    log("[Summon]ShowPriceFree", nSummonId)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef["bdrTime0"..nSummonId]:SetVisibility(ESlateVisibility.Collapsed)
    UpdateSummonEnable(self, nSummonId, true)
end

local function ShowPriceCannotFree(self, nSummonId)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef["bdrTime0"..nSummonId]:SetVisibility(ESlateVisibility.Collapsed)
    UpdateSummonEnable(self, nSummonId, false)
end

local function ShowTimer(self, nSummonId, nRemainSeconds)
    log("[Summon]ShowTimer", nSummonId, nRemainSeconds)
    if nRemainSeconds <= 0 then
        error("Count down seconds less than 0!".. nRemainSeconds)
    end
    local PRECISION = 3
    local pCountDownWidget = self.pWidgetRef["kmtimerCountDown"..nSummonId]
    pCountDownWidget:SetPrecision(PRECISION)
    pCountDownWidget:StartTimer(nRemainSeconds, 1, TIMEFORMAT, EMinTimeUnit.Second)
    UpdateSummonEnable(self, nSummonId, false)
end

local function ShowPriceCountDownFree(self, nSummonId, nNextFreeTime)
    log("[Summon]ShowPriceCountDownFree", nSummonId, nNextFreeTime)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef["bdrTime0"..nSummonId]:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    local now = GlobalVariableSystem:GetServerTimeUtc()
    local nRemainSeconds = nNextFreeTime - now
    if nRemainSeconds <= 0 then
        error("Count down seconds less than 0!" .. nRemainSeconds..", nNextFreeTime:"..nNextFreeTime..", now"..now)
    end
    ShowTimer(self, nSummonId, nRemainSeconds)
end

local function RefreshSummonPriceData(self)
    local SailorComponent = GetSailorComponent()
    for i=1,MAX_SUMMON_BUTTON_COUNT do
        local bCanFree, bIsFree, nNextFreeTime = SailorComponent:GetFreeSummonData(i)
        log("[Summon]RefreshSummonPriceData", i, bCanFree, bIsFree, nNextFreeTime)
        if not bCanFree then
            ShowPriceCannotFree(self, i)
        else
            if bIsFree then
                ShowPriceFree(self, i)
            else
                ShowPriceCountDownFree(self, i, nNextFreeTime)
            end
        end
    end
end

local function RefreshSummonHighAwardCount(self)
    for nSummonGroupId, l10nPostfix  in pairs(SAILOR_SUMMON_TIPS_POSTFIX) do
        local l10nTips = nil
        local nNextCount = GetSailorComponent():GetNextHighGradeAwardCount(nSummonGroupId)
        if nNextCount > 1 then
            l10nTips = L10N:Format(UISetUtils.GetL10NTextByKey("SAILOR_SUMMON_TIPS_COMMON_FORMAT"), nNextCount, l10nPostfix)
        else
            l10nTips = L10N:Format(UISetUtils.GetL10NTextByKey("SAILOR_SUMMON_TIPS_NEXT_FORMAT"), l10nPostfix)
        end
        self.pWidgetRef["txtSummonTips_" .. nSummonGroupId]:SetText(l10nTips)
    end
end

local function RequestSailorSummon(nSummonId, bIsFree, bAutoExchange)
    UIManager:OpenWnd(UIDef.UI_FULLSCREEN_MASK)
    local SailorComponent = GetSailorComponent()
    SailorComponent:RequestSailorSummon(nSummonId, bIsFree, bAutoExchange)
end

local function OnClickedBtnSummon(self, nSummonId)
    local SailorComponent = GetSailorComponent()
    local tbTemplate = SailorSummonDataTable:GetTemplate(nSummonId)
    local nCurrencyId = tbTemplate.nCurrencyId
    local _, bIsFree, _ = SailorComponent:GetFreeSummonData(nSummonId)
    if bIsFree then
        RequestSailorSummon(nSummonId, bIsFree, false)
        return
    end

    local nCurrencyPrice = tbTemplate.nPrice

    local firstRequest = function ()
        RequestSailorSummon(nSummonId, bIsFree, false)
    end

    local secondRequest = nil
    if nCurrencyId == UNEXCHANGED_ID then
        secondRequest = function ()
            RequestSailorSummon(nSummonId, bIsFree, true)
        end
    end
    CostCurrencyHelper:SetData(nCurrencyId, nCurrencyPrice, firstRequest, secondRequest, UISetUtils.GetL10NTextByKey("SAILOR_SUMMON_FAILED"))
    CostCurrencyHelper:FirstRequest()
end

local function ShowFinalResut(self, tbResults)
    UIManager:CloseWnd(UIDef.UI_FULLSCREEN_MASK)
    local tbItemDatas = {}
    for i, v in ipairs(tbResults) do
        tbItemDatas[i] = {
            nItemTemplateId = v.template_id,
            nCount = v.count
        }
    end
    PlayUEAnim(self, "animReset")
    UIManager:OpenWnd(UIDef.UI_LOBBY_AWARD_ITEM, {["tbItemDatas"] = tbItemDatas})
    self:PlayAnimation(szAnimHideBtns, 0, 1, EUMGSequencePlayMode.Reverse, 1)
    self.pbWindowFrame:PlayAnimation(szAnimWidFrameBtns, 0, 1, EUMGSequencePlayMode.Reverse, 1)
end

local function OnNotEnoughCurrency(self, bAutoExchange)
    if not bAutoExchange then
        CostCurrencyHelper:FirstCostFailed()
    else
        CostCurrencyHelper:SecondCostFailed()
    end
end

local function OnReceiveSailorSummonResult(self, bSummonSucceeded, tbResults, nReturnCode, bAutoExchange)
    if not bSummonSucceeded then
        UIManager:CloseWnd(UIDef.UI_FULLSCREEN_MASK)
        if nReturnCode == Proto.ReturnCode.MONEY_IS_NOT_ENOUGH then
            OnNotEnoughCurrency(self, bAutoExchange)
        end
        return
    end
    local pIcon = UIResourceDef.SAILOR_FRAGMENT_SUMMON_ICON:load()
    if #tbResults == 1 then
        UISetUtils.SetImageBrushRes(self.pWidgetRef.ueSummonSailor.imgItemCenter, pIcon, true)
        self.pWidgetRef.ueSummonSailor["txtItemCountCenter"]:SetText(tbResults[1].count)
        PlayUEAnim(self, "animBuyOne", function()
            ShowFinalResut(self, tbResults)
        end)
    else
        for i,v in ipairs(tbResults) do
            UISetUtils.SetImageBrushRes(self.pWidgetRef.ueSummonSailor["imgItem0"..i], pIcon, true)
            self.pWidgetRef.ueSummonSailor["txtItemCount0"..i]:SetText(tbResults[i].count)
        end
        PlayUEAnim(self, "animBuyFive", function()
            ShowFinalResut(self, tbResults)
        end)
    end
    self:PlayAnimation(szAnimHideBtns, 0, 1, EUMGSequencePlayMode.Forward, 1)
    self.pbWindowFrame:PlayAnimation(szAnimWidFrameBtns, 0, 1, EUMGSequencePlayMode.Forward, 1)
    RefreshSummonPriceData(self)
    RefreshSummonHighAwardCount(self)
end

local function OnCurrencyCountSync(self)
    RefreshSummonPriceData(self)
end

local function OnRedDotVisibleChanged(self, bVisible, nSailorRedDotDef)
    if nSailorRedDotDef == SailorRedDotDef.SUMMONING then
        RefreshSummonPriceData(self)
    end
end

local function OnClickedFullscreenMask(self)
    StopUEAnim(self, "animBuyOne")
    StopUEAnim(self, "animBuyFive")
end

function UILobbySailorSummoning:OnLoad()
    UILobbySailorSummoning.super.OnLoad(self)

    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetBackDelegate(BackToPre, self)

    --self.pCurrencyBar = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbLobbyCurrencyBar)
    self.pbWindowFrame:SetSpecialCurrency(UILobbySailorDef.CURRENCY_ID)

    RefreshSummonPriceData(self)
    RefreshSummonHighAwardCount(self)
end

function UILobbySailorSummoning:OnShow()
    UILobbySailorSummoning.super.OnShow(self)
    PlayUEAnim(self, "animFirstAppear", function()
        --引导需要知道此动画播放结束
    end)
    self:PlayAnimation(szSummonIn, 0, 1, EUMGSequencePlayMode.Forward, 1, function()
    end)
end

function UILobbySailorSummoning:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    --EventHelper:RegisterCppDelegate(pWidgetRef.btnBack.OnClicked, self, BackToPre)
    for i=1,MAX_SUMMON_BUTTON_COUNT do
        EventHelper:RegisterCppDelegateFunc(pWidgetRef["btnSummon_"..i].OnClicked, function()
            OnClickedBtnSummon(self, i)
        end)
    end
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_SUMMON_RESULT, self, OnReceiveSailorSummonResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_CURRENCY_COUNT_SYNC, self, OnCurrencyCountSync)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SAILOR_RED_DOT_VISIBLE_CHANGED, self, OnRedDotVisibleChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_CLICK_FULLSCREEN_MASK, self, OnClickedFullscreenMask)
end

function UILobbySailorSummoning:OnHide()
    UIManager:CloseWnd(UIDef.UI_FULLSCREEN_MASK)
end

return UILobbySailorSummoning
