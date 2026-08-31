local luaclass = require("luaclass")
local Prefabbase = require("Prefabbase")
local UPPartnerSummoning = luaclass("UPPartnerSummoning", Prefabbase)

local UIDef = require("UIDef")
local UIUtils = require("UIUtils")
local UIManager = require("UIManager")
local UISetUtils = require("UISetUtils")
local ClientEventDef = require("ClientEventDef")
local UIResourceDef = require("UIResourceDef")
local CurrencySystem = require("CurrencySystem")
local PartnerPoolDataTable = require("PartnerPoolDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local SUMMON_TYPE_TEN   = 10    -- 招募十次
local SUMMON_TYPE_ONE   = 1     -- 招募一次
local GLASS_INDEX_A     = 1     -- 绿色，默认左侧
local GLASS_INDEX_B     = 2     -- 橙色，默认中间
local GLASS_INDEX_C     = 3     -- 紫色，默认右侧
local DEFAULT_INDEX     = GLASS_INDEX_A
local POOL_ID_MAP = {           -- 因为动画是死的，所以各瓶子默认位置
    [GLASS_INDEX_A] = 1,
    [GLASS_INDEX_B] = 2,
    [GLASS_INDEX_C] = 3
}

UPPartnerSummoning.nIndex = DEFAULT_INDEX
UPPartnerSummoning.bInAppearAnim = false

local function PlayUEAnim(self, szAnimName, bLoop, fnCallback)
    local ueSummonPartner = self.pWidgetRef.ueSummonPartner
    local nLoopNum = bLoop and 0 or 1
    self:PlayAnimationWithUserWidget(ueSummonPartner, szAnimName, 0, nLoopNum, EUMGSequencePlayMode.Forward, 1, fnCallback)
end

local function StopUEAnim(self, szAnimName)
    local ueSummonPartner = self.pWidgetRef.ueSummonPartner
    if ueSummonPartner[szAnimName] then
        ueSummonPartner:StopAnimation(ueSummonPartner[szAnimName])
    end
end

local function UpdatePoolInfo(self)
    local nPoolId = POOL_ID_MAP[self.nIndex]
    local tbTemplate = PartnerPoolDataTable:GetTemplate(nPoolId)
    if tbTemplate.bDisabled then
        self.pWidgetRef.txtDiabled:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.pWidgetRef.cvsBtn:SetVisibility(ESlateVisibility.Collapsed)
    else
        self.pWidgetRef.txtDiabled:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.cvsBtn:SetVisibility(ESlateVisibility.SelfHitTestInvisible)

        local nCurrencyId = tbTemplate.nCurrencyId
        -- 刷新货币图标
        local szCurrencySmallIcon = CurrencySystem:GetCurrencySmallIcon(nCurrencyId)
        local pCurrencyIcon = szCurrencySmallIcon:load()
        UISetUtils.SetImageBrushRes(self.pWidgetRef.imgCurrencyOne, pCurrencyIcon)
        UISetUtils.SetImageBrushRes(self.pWidgetRef.imgCurrencyTen, pCurrencyIcon)
        -- 刷新货币价格
        self.pWidgetRef.txtCurrencyOne:SetText(tbTemplate.nOneTimeCount)
        self.pWidgetRef.txtCurrencyTen:SetText(tbTemplate.nTenTimesCount)
        -- 刷新是否可以招募相关表现
        local nCurrencyCount = CurrencySystem:GetCurrencyCount(nCurrencyId)
        local bEnoughOne = nCurrencyCount >= tbTemplate.nOneTimeCount
        local bEnoughTen = nCurrencyCount >= tbTemplate.nTenTimesCount
        self.pWidgetRef.txtCurrencyOne:SetColorAndOpacity(bEnoughOne and UIResourceDef.COLOR.WHITE.SLATE_COLOR or UIResourceDef.COLOR.RED.SLATE_COLOR)
        self.pWidgetRef.txtCurrencyTen:SetColorAndOpacity(bEnoughTen and UIResourceDef.COLOR.WHITE.SLATE_COLOR or UIResourceDef.COLOR.RED.SLATE_COLOR)
        self.pWidgetRef.btnSummonOne:SetIsEnabled(bEnoughOne)
        self.pWidgetRef.btnSummonTen:SetIsEnabled(bEnoughTen)
    end
end

local function SelectPool(self, nIndex)
    self.nIndex = nIndex
    if nIndex == GLASS_INDEX_A then
        StopUEAnim(self, "animGlassA_Wait")
        PlayUEAnim(self, "animGlassA_Selection", true)
    else
        StopUEAnim(self, "animGlassA_Selection")
        PlayUEAnim(self, "animGlassA_Wait", true)
    end
    if nIndex == GLASS_INDEX_B then
        StopUEAnim(self, "animGlassB_Wait")
        PlayUEAnim(self, "animGlassB_Selection", true)
    else
        StopUEAnim(self, "animGlassB_Selection")
        PlayUEAnim(self, "animGlassB_Wait", true)
    end
    if nIndex == GLASS_INDEX_C then
        StopUEAnim(self, "animGlassC_Wait")
        PlayUEAnim(self, "animGlassC_Selection", true)
    else
        StopUEAnim(self, "animGlassC_Selection")
        PlayUEAnim(self, "animGlassC_Wait", true)
    end
    UpdatePoolInfo(self)
end

local function ResetSummonAnim(self)
    local nIndex = self.nIndex
    local pAnim = self.pWidgetRef.ueSummonPartner["animBuy0"..nIndex]
    self.pWidgetRef.ueSummonPartner:PlayAnimation(pAnim, pAnim:GetEndTime(), 1, EUMGSequencePlayMode.Reverse, 1)
    self:PlayAnimation("animReset", 0, 1, EUMGSequencePlayMode.Forward, 1)
    SelectPool(self, nIndex)
end

local function ShowSummonResult(self)
    if self.tbSummonResults then
        UIManager:OpenWnd(UIDef.UI_FULLSCREEN_MASK)

        StopUEAnim(self, "animGlassA_Wait")
        StopUEAnim(self, "animGlassB_Wait")
        StopUEAnim(self, "animGlassC_Wait")
        StopUEAnim(self, "animGlassA_Selection")
        StopUEAnim(self, "animGlassB_Selection")
        StopUEAnim(self, "animGlassC_Selection")

        local szAnimName = "animBuy0"..self.nIndex
        PlayUEAnim(self, szAnimName)
        self:PlayAnimationWithUserWidget(self.pWidgetRef.ueSummonPartner, szAnimName, 0, 1, EUMGSequencePlayMode.Forward, 1, function()
            local tbOpenArgs = {}
            tbOpenArgs.tbSummonResults = self.tbSummonResults
            tbOpenArgs.nPoolId = POOL_ID_MAP[self.nIndex]
            UIManager:OpenWnd(UIDef.UI_PARTNER_SUMMON_RESULT, tbOpenArgs)
            self.tbSummonResults = nil
            UIManager:CloseWnd(UIDef.UI_FULLSCREEN_MASK)
        end)
    end
end

local function OnReceiveSummonPartnerResult(self, tbSummonResults)
    self:PlayAnimation("animHideButton", 0, 1, EUMGSequencePlayMode.Forward, 1)

    self.tbSummonResults = tbSummonResults
    if not self.bInAppearAnim then
        ShowSummonResult(self)
    end
end

local function RequestSummonPartner(self)
    UIManager:OpenWnd(UIDef.UI_FULLSCREEN_MASK)
    GamePlayerSelfHelper:Get().PartnerComponent:RequestSummonPartner(POOL_ID_MAP[self.nIndex], self.nSummonType)
end

local function OnClickedBtnSummonTen(self)
    self.nSummonType = SUMMON_TYPE_TEN
    RequestSummonPartner(self)
end

local function OnClickedBtnSummonOne(self)
    self.nSummonType = SUMMON_TYPE_ONE
    RequestSummonPartner(self)
end

local function OnDisableClickedSummon(self)
    UIUtils.ShowToastWithKey("PARTNER_SUMMON_FAILED_MONEY")
end

local function OnClickedBtnLeft(self)
    local nIndex = self.nIndex
    PlayUEAnim(self, "animChangeR0"..nIndex, false, function()
        -- 为引导抛出动画结束的事件
    end)
    nIndex = nIndex - 1
    if nIndex < GLASS_INDEX_A  then
        nIndex = GLASS_INDEX_C
    end
    SelectPool(self, nIndex)
end

local function OnClickedBtnRight(self)
    local nIndex = self.nIndex
    PlayUEAnim(self, "animChangeF0"..nIndex)
    nIndex = nIndex + 1
    if nIndex > GLASS_INDEX_C  then
        nIndex = GLASS_INDEX_A
    end
    SelectPool(self, nIndex)
end

local function OnSummonAgain(self)
    ResetSummonAnim(self)
    RequestSummonPartner(self)
end

function UPPartnerSummoning:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSummonTen.OnClicked, self, OnClickedBtnSummonTen)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSummonOne.OnClicked, self, OnClickedBtnSummonOne)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSummonTen.OnDisableClicked, self, OnDisableClickedSummon)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSummonOne.OnDisableClicked, self, OnDisableClickedSummon)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnLeft.OnClicked, self, OnClickedBtnLeft)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnRight.OnClicked, self, OnClickedBtnRight)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SUMMON_PARTNER_RESULT, self, OnReceiveSummonPartnerResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_PARTNER_SUNMMON_RESULT_CLOSED, self, ResetSummonAnim)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_PARTNER_SUNMMON_AGAIN, self, OnSummonAgain)
end

function UPPartnerSummoning:Activate()
    self.bInAppearAnim = true
    self:PlayAnimation("animShow", 0, 1, EUMGSequencePlayMode.Forward, 1)
    PlayUEAnim(self, "animFirstAppear0".. DEFAULT_INDEX, false, function()
        self.bInAppearAnim = false
        ShowSummonResult(self)
    end)
    SelectPool(self, DEFAULT_INDEX)
end

function UPPartnerSummoning:OnHide()
    UIManager:CloseWnd(UIDef.UI_FULLSCREEN_MASK)
end

return UPPartnerSummoning