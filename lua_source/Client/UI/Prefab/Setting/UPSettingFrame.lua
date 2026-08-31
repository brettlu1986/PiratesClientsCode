local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSettingFrame = luaclass("UPSettingFrame", PrefabBase)
local SettingSystemNew = require("SettingSystemNew")
local SettingClassType    = require("SettingClassType")
local SettingKeyDef       = require("SettingKeyDef")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local UITextDef = require("UITextDef")
local MathUtil = require("MathUtil")
local L10N = require("L10N")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local UIResourceDef = require("UIResourceDef")

local LocalKeys  = SettingKeyDef.LocalKeys
local MAX_QUALITY = 3
local MAX_FPS = 2
local MAX_STYLE = 4
local MAX_AUTO = 1
local MAX_SAWTOOTH = 1
local CUTOUT_SPACER_VALUE_NOTCH_SCREEN_RECOMMAND = 100
local CUTOUT_SPACER_VALUE_ROUNDED_SCREEN_RECOMMAND = 60
local SHOW_CUTOUT_TIPS_TIME_INTERVAL = 3
local UNDETERMINED, UNCHECKED, CHECKED = -1, 0, 1 

local SETTING_LEVELS = {
    UISetUtils.GetL10NTextByKey("UI_SETTING_FRAME_0"),
    UISetUtils.GetL10NTextByKey("UI_SETTING_FRAME_1"),
    UISetUtils.GetL10NTextByKey("UI_SETTING_FRAME_2"),
    UISetUtils.GetL10NTextByKey("UI_SETTING_FRAME_3"),
}

local SETTING_OPEN = {
    UISetUtils.GetL10NTextByKey("UI_SETTING_CLOSE"),
    UISetUtils.GetL10NTextByKey("UI_SETTING_OPEN"),
}

local SLATE_COLOR_DARK_GRAY5 = UIResourceDef.COLOR.GREY1.SLATE_COLOR
local SLATE_COLOR_WHITE = UIResourceDef.COLOR.WHITE.SLATE_COLOR

UPSettingFrame.tbInstance = nil
UPSettingFrame.nLastShowCutoutTipsTime = 0
UPSettingFrame.bSupportStyle = nil
UPSettingFrame.pbQualitys = nil
UPSettingFrame.pbFPSs = nil
UPSettingFrame.pbAutoAdaptives = nil

local function RefreshQuality(self)
    local nMaxValue = self.tbInstance:GetMaxValue(LocalKeys.FRAME_QUALITY)
    local nCurValue = self.tbInstance:Get(LocalKeys.FRAME_QUALITY)

    log("RefreshQuality:", nCurValue, nMaxValue)
    for i = 0, MAX_QUALITY do
        if i > nMaxValue then
            self.pbQualitys[i]:SetSelect(UNDETERMINED)
            -- pWidgetRef["txtQuality"..i]:SetColorAndOpacity(SLATE_COLOR_DARK_GRAY5)
            -- pWidgetRef["cbQuality"..i]:SetCheckedState(UNDETERMINED)
        else
            self.pbQualitys[i]:SetSelect(nCurValue == i and CHECKED or UNCHECKED)
            -- pWidgetRef["txtQuality"..i]:SetColorAndOpacity(SLATE_COLOR_WHITE)
            -- pWidgetRef["cbQuality"..i]:SetCheckedState(nCurValue == i and CHECKED or UNCHECKED)
        end
    end
end

local function RefreshFPS(self)
    local nMaxValue = self.tbInstance:GetMaxValue(LocalKeys.FPS_QUALITY)
    local nCurValue = self.tbInstance:Get(LocalKeys.FPS_QUALITY)

    for i = 0, MAX_FPS do
        if i > nMaxValue then
            self.pbFPSs[i]:SetSelect(UNDETERMINED)
            -- pWidgetRef["txtFPS"..i]:SetColorAndOpacity(SLATE_COLOR_DARK_GRAY5)
            -- pWidgetRef["cbFPS"..i]:SetCheckedState(UNDETERMINED)
        else
            self.pbFPSs[i]:SetSelect(nCurValue == i and CHECKED or UNCHECKED)
            -- pWidgetRef["txtFPS"..i]:SetColorAndOpacity(SLATE_COLOR_WHITE)
            -- pWidgetRef["cbFPS"..i]:SetCheckedState(nCurValue == i and CHECKED or UNCHECKED)
        end
    end
end

local function RefreshStyle(self)
    local pWidgetRef = self.pWidgetRef
    local nMaxValue = self.tbInstance:GetMaxValue(LocalKeys.FRAME_STYLE)
    local nCurValue = self.tbInstance:Get(LocalKeys.FRAME_STYLE)
    
    local nQualityMaxValue = self.tbInstance:GetMaxValue(LocalKeys.FRAME_QUALITY)
    if nQualityMaxValue <= 0 then
        log("quality is low")
        nMaxValue = -1
        self.bSupportStyle = false
    else
        self.bSupportStyle = true
    end
    
    for i = 0, MAX_STYLE do
        if i > nMaxValue then
            pWidgetRef["txtStyle"..i]:SetColorAndOpacity(SLATE_COLOR_DARK_GRAY5)
            pWidgetRef["imgStyle"..i]:SetVisibility(ESlateVisibility.Collapsed)
            -- pWidgetRef["cbStyle"..i]:SetCheckedState(UNDETERMINED)
        else
            pWidgetRef["txtStyle"..i]:SetColorAndOpacity(SLATE_COLOR_WHITE)
            pWidgetRef["imgStyle"..i]:SetVisibility(nCurValue == i and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed)
            -- pWidgetRef["cbStyle"..i]:SetCheckedState(nCurValue == i and CHECKED or UNCHECKED)
        end
    end
end

-- local function RefreshSawtooth(self)
--     local pWidgetRef = self.pWidgetRef
--     local nCurValue = 0
--     for i = 0, MAX_SAWTOOTH do
--         pWidgetRef["cbSawtooth"..i]:SetCheckedState(nCurValue == i and CHECKED or UNCHECKED)
--     end
-- end

local function RefreshBrightness(self)
    local pWidgetRef = self.pWidgetRef
    local nCurValue = self.tbInstance:Get(LocalKeys.FRAME_BRIGHTNESS)
    local nMaxValue = self.tbInstance:GetMaxValue(LocalKeys.FRAME_BRIGHTNESS)
    local nMinValue = self.tbInstance:GetMinValue(LocalKeys.FRAME_BRIGHTNESS)
    nCurValue = nCurValue - nMinValue
    nMaxValue = nMaxValue - nMinValue
    local nRate = nCurValue / nMaxValue
    pWidgetRef.sdBrightness:SetValue(nRate)
    pWidgetRef.proBrightness:SetPercent(nRate)
    nRate = nRate * 100
    nRate = math.floor(nRate)
    nRate = nRate + nMinValue
    pWidgetRef.txtBrightness:SetText(nRate.."%")
end

local function RefreshAutoAdaptive(self)
    local nMaxValue = self.tbInstance:GetMaxValue(LocalKeys.AUTO_ADAPTIVE)
    local nCurValue = self.tbInstance:Get(LocalKeys.AUTO_ADAPTIVE)

    for i = 0, MAX_AUTO do
        if i > nMaxValue then
            self.pbAutoAdaptives[i]:SetSelect(UNDETERMINED)
            -- pWidgetRef["txtAutoAdaptive"..i]:SetColorAndOpacity(SLATE_COLOR_DARK_GRAY5)
            -- pWidgetRef["cbAutoAdaptive"..i]:SetCheckedState(UNDETERMINED)
        else
            self.pbAutoAdaptives[i]:SetSelect(nCurValue == i and CHECKED or UNCHECKED)
            -- pWidgetRef["txtAutoAdaptive"..i]:SetColorAndOpacity(SLATE_COLOR_WHITE)
            -- pWidgetRef["cbAutoAdaptive"..i]:SetCheckedState(nCurValue == i and CHECKED or UNCHECKED)
        end
    end
end

local function RefreshCutoutSpacerWidthUI(self, nValue)
    nValue = nValue or self.tbInstance:Get(LocalKeys.CUTOUT_SPACER_WIDTH)
    local nMaxValue = self.tbInstance:GetMaxValue(LocalKeys.CUTOUT_SPACER_WIDTH)
    local nPercent = nValue / nMaxValue
    self.pWidgetRef.pgbCutoutSpacerBg:SetPercent(nPercent)
    self.pWidgetRef.sldrCutoutSpacerBg:SetValue(nPercent)

    local l10nFormat = UISetUtils.GetL10NTextByKey("SETTING_CUTOUT_SPACER_VALUE")
    local l10nValueText = L10N:Format(l10nFormat, nValue)
    self.pWidgetRef.txtCutoutSpacerWidth:SetText(l10nValueText)
end

local function RefreshUI(self)
    RefreshQuality(self)
    RefreshFPS(self)
    RefreshStyle(self)
    -- RefreshSawtooth(self)
    RefreshBrightness(self)
    RefreshAutoAdaptive(self)
    RefreshCutoutSpacerWidthUI(self)
end

local function ChangeValue(self, nIndex, bActivate, nKey, szWidgetName, szPrefabName)
    local nCurValue = self.tbInstance:Get(nKey)
    if nCurValue == nIndex then
        if not bActivate then
            -- if szWidgetName ~= nil then
                -- self.pWidgetRef[szWidgetName..nIndex]:SetCheckedState(CHECKED)
            if szPrefabName ~= nil then
                self[szPrefabName][nIndex]:SetSelect(CHECKED)
            end
        end
    else
        local nMaxValue = self.tbInstance:GetMaxValue(nKey)
        if nIndex > nMaxValue then
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("SETTING_MACHINE_UNSUPPORT"))
            -- if szWidgetName ~= nil then
                -- self.pWidgetRef[szWidgetName..nIndex]:SetCheckedState(UNDETERMINED)
            if szPrefabName ~= nil then
                self[szPrefabName][nIndex]:SetSelect(UNDETERMINED)
            end
        else
            self.tbInstance:Set(nKey, nIndex)
            SettingSystemNew:SaveLocalData()
            return true
        end
    end
    return false
end

local function OnClickedQuality(self, nIndex)
    if ChangeValue(self, nIndex, true, LocalKeys.FRAME_QUALITY, nil, "pbQualitys") then
        RefreshQuality(self)
        local nCurValue = self.tbInstance:Get(LocalKeys.FRAME_QUALITY)
        if nCurValue == 0 then
            if ChangeValue(self, 0, true, LocalKeys.FRAME_STYLE, "cbStyle") then
                RefreshStyle(self)
            end        
        end
    end
end

local function OnClickedFPS(self, nIndex)
    if ChangeValue(self, nIndex, true, LocalKeys.FPS_QUALITY, nil, "pbFPSs") then
        RefreshFPS(self)
    end
end

local function OnClickedStyle(self, nIndex)
    if not self.bSupportStyle or self.tbInstance:Get(LocalKeys.FRAME_QUALITY) == 0  then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("SETTING_STYLE_NOSUPPORT"))
        -- self.pWidgetRef["cbStyle"..nIndex]:SetCheckedState(UNDETERMINED)
        return
    end
    if ChangeValue(self, nIndex, true, LocalKeys.FRAME_STYLE, "cbStyle") then
        RefreshStyle(self)
    end
end

local function OnClickedAutoAdaptive(self, nIndex)
    if ChangeValue(self, nIndex, true, LocalKeys.AUTO_ADAPTIVE, nil, "pbAutoAdaptives") then
        RefreshAutoAdaptive(self)
    end
end

local function OnClickedBrightnessReduce(self)
    local nCurValue = self.tbInstance:Get(LocalKeys.FRAME_BRIGHTNESS)
    local nMinValue = self.tbInstance:GetMinValue(LocalKeys.FRAME_BRIGHTNESS)
    if nCurValue == nMinValue then
        return
    end
    self.tbInstance:Set(LocalKeys.FRAME_BRIGHTNESS, nCurValue - 1)
    RefreshBrightness(self)
end

local function OnClickedBrightnessAdd(self)
    local nCurValue = self.tbInstance:Get(LocalKeys.FRAME_BRIGHTNESS)
    local nMaxValue = self.tbInstance:GetMaxValue(LocalKeys.FRAME_BRIGHTNESS)
    if nCurValue == nMaxValue then
        return
    end
    self.tbInstance:Set(LocalKeys.FRAME_BRIGHTNESS, nCurValue + 1)
    RefreshBrightness(self)
end

local function OnBrightnessValueChanged(self, nValue)
    local nMinValue = self.tbInstance:GetMinValue(LocalKeys.FRAME_BRIGHTNESS)
    local nCurValue = nValue * 100 + nMinValue
    nCurValue = math.floor( nCurValue )
    self.tbInstance:Set(LocalKeys.FRAME_BRIGHTNESS, nCurValue)
    RefreshBrightness(self)
end

local function OnClickedReset(self)
    self.tbInstance:Reset()
    RefreshUI(self)
end

local function OnClickedSawtooth(self, nIndex, bActivate)
    UIUtils.ShowToast(UITextDef.IN_DEVELOPMENT)
    -- RefreshSawtooth(self)
end

local function ShowCutoutRestartToast(self)
    local nCurTime = GlobalVariableSystem:GetLocalTime()
    if nCurTime - self.nLastShowCutoutTipsTime > SHOW_CUTOUT_TIPS_TIME_INTERVAL then
        self.nLastShowCutoutTipsTime = nCurTime
        UIUtils.ShowToastWithKey("SETTING_CUTOUT_RESTART_TIPS")
    end
end

local function SetCutoutSpacerWidth(self, nValue)
    local nMinValue = self.tbInstance:GetMinValue(LocalKeys.CUTOUT_SPACER_WIDTH)
    local nMaxValue = self.tbInstance:GetMaxValue(LocalKeys.CUTOUT_SPACER_WIDTH)
    nValue = MathUtil.Clamp(nValue, nMinValue, nMaxValue)

    local nCurValue = self.tbInstance:Get(LocalKeys.CUTOUT_SPACER_WIDTH)
    if nCurValue ~= nValue then
        self.tbInstance:Set(LocalKeys.CUTOUT_SPACER_WIDTH, nValue)
        SettingSystemNew:SaveLocalData()
        RefreshCutoutSpacerWidthUI(self, nValue)
        ShowCutoutRestartToast(self)
    end
end

local function OnClickedBtnCutoutSpacerWidthAdd(self)
    local nCurValue = self.tbInstance:Get(LocalKeys.CUTOUT_SPACER_WIDTH)
    SetCutoutSpacerWidth(self, nCurValue + 1)
end

local function OnClickedBtnCutoutSpacerWidthReduce(self)
    local nCurValue = self.tbInstance:Get(LocalKeys.CUTOUT_SPACER_WIDTH)
    SetCutoutSpacerWidth(self, nCurValue - 1)
end

local function OnClickedBtnNotchScreenRecommend(self)
    SetCutoutSpacerWidth(self, CUTOUT_SPACER_VALUE_NOTCH_SCREEN_RECOMMAND)
end

local function OnClickedBtnRoundedScreenRecommend(self)
    SetCutoutSpacerWidth(self, CUTOUT_SPACER_VALUE_ROUNDED_SCREEN_RECOMMAND)
end

local function OnCutoutSpacerWidthValueChanged(self, nValue)
    local nMaxValue = self.tbInstance:GetMaxValue(LocalKeys.CUTOUT_SPACER_WIDTH)
    SetCutoutSpacerWidth(self, math.ceil(nMaxValue * nValue))
end

function UPSettingFrame:OnLoad()
    local PrefabHelper = self.PrefabHelper
    local pWidgetRef = self.pWidgetRef

    self.pbQualitys = {}
    for i = 0, MAX_QUALITY do
        self.pbQualitys[i] = PrefabHelper:BindPrefab(pWidgetRef["pQuality"..i])
        self.pbQualitys[i]:Init("Quality", SETTING_LEVELS[i + 1])
    end 

    self.pbFPSs = {}
    for i = 0, MAX_FPS do
        self.pbFPSs[i] = PrefabHelper:BindPrefab(pWidgetRef["pFPS"..i])
        self.pbFPSs[i]:Init("FPS", SETTING_LEVELS[i + 1])
    end
    
    self.pbAutoAdaptives = {}
    for i = 0, MAX_AUTO do
        self.pbAutoAdaptives[i] = PrefabHelper:BindPrefab(pWidgetRef["pAutoAdaptive"..i])
        self.pbAutoAdaptives[i]:Init("AutoAdaptive", SETTING_OPEN[i + 1]) 
    end
end

function UPSettingFrame:OnUnload()
    self.pbQualitys = nil
    self.pbFPSs = nil
    self.pbAutoAdaptives = nil
end

function UPSettingFrame:OnCreate()
    self.tbInstance = SettingSystemNew:GetInstance(SettingClassType.Setting_Frame)
end

function UPSettingFrame:OnDestroy()
    self.tbInstance = nil
end

function UPSettingFrame:OnShow()
    RefreshUI(self)
end

function UPSettingFrame:Activate()
    self.pWidgetRef.scrollPanel:ScrollToStart()
end

function UPSettingFrame:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    for i = 0, MAX_QUALITY do
        EventHelper:RegisterCppDelegate(self.pbQualitys[i].pWidgetRef.btnPass.OnClicked,  self, function()
            OnClickedQuality(self, i)
        end)
    end
    for i = 0, MAX_FPS do
        EventHelper:RegisterCppDelegate(self.pbFPSs[i].pWidgetRef.btnPass.OnClicked,  self, function()
            OnClickedFPS(self, i)
        end)
    end
    for i = 0, MAX_STYLE do
        EventHelper:RegisterCppDelegate(pWidgetRef["btnStyle"..i].OnClicked,  self, function()
            OnClickedStyle(self, i)
        end)
    end
    for i = 0, MAX_AUTO do
        EventHelper:RegisterCppDelegate(self.pbAutoAdaptives[i].pWidgetRef.btnPass.OnClicked,  self, function()
            OnClickedAutoAdaptive(self, i)
        end)
    end
    for i = 0, MAX_SAWTOOTH do
        EventHelper:RegisterCppDelegate(pWidgetRef["cbSawtooth"..i].OnCheckStateChanged,  self, function(_, bActivate)
            OnClickedSawtooth(self, i, bActivate)
        end)
    end

    EventHelper:RegisterCppDelegate(pWidgetRef.btnBrightnessReduce.OnClicked, self, OnClickedBrightnessReduce)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnBrightnessAdd.OnClicked, self, OnClickedBrightnessAdd)
    EventHelper:RegisterCppDelegate(pWidgetRef.sdBrightness.OnValueChanged, self, OnBrightnessValueChanged)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnReset.OnClicked, self, OnClickedReset)

    EventHelper:RegisterCppDelegate(pWidgetRef.btnCutoutSpacerWidthAdd.OnClicked, self, OnClickedBtnCutoutSpacerWidthAdd)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnCutoutSpacerWidthReduce.OnClicked, self, OnClickedBtnCutoutSpacerWidthReduce)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnNotchScreenRecommend.OnClicked, self, OnClickedBtnNotchScreenRecommend)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnRoundedScreenRecommend.OnClicked, self, OnClickedBtnRoundedScreenRecommend)
    EventHelper:RegisterCppDelegate(pWidgetRef.sldrCutoutSpacerBg.OnValueChanged, self, OnCutoutSpacerWidthValueChanged)
end

return UPSettingFrame