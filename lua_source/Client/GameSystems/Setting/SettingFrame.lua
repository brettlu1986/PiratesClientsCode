local luaclass = require("luaclass")
local SettingBase = require("SettingBase")
local SettingFrame = luaclass("SettingFrame", SettingBase)
local SettingKeyDef = require("SettingKeyDef")
local SettingIni = require("SettingIni")
local ScreenShapeHelper = require("ScreenShapeHelper")
local CppDelegate = require("CppDelegate")
local UISetUtils = require("UISetUtils")
local UIUtils = require("UIUtils")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")

local LocalKeys = SettingKeyDef.LocalKeys

-- local MAX_QUALITY = 3
local MAX_STYLE = 4
local DEFAULT_FPS = 1
local MAX_AUTOADAPTIVE = 1
local MAX_FPS = 2
local MIN_BRIGHTNESS, MAX_BRIGHTNESS = 50, 150
local MIN_CUTOUT_SPACER_WIDTH = 0
local MAX_CUTOUT_SPACER_WIDTH = 100

local nCutoutSpacerWidth = 0 -- 是不是可以改成SettingFrame的成员变量？不过现在fnGet都没有传self...

local FRAMES = {
    -- 画面品质
    QUALITY = {
        nKey = LocalKeys.FRAME_QUALITY,
        nMin = 0,
        fnGet = function(pRenderSettingManager)
            local nValue = pRenderSettingManager:GetQuality()
            log("get frame cur quality ", nValue) 
            return nValue
        end,
        fnSet = function(pRenderSettingManager, nLevel)
            log("set frame quality ", nLevel)
            EventManager:OnFireEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_IMAGE_QUALITY_CHANGE, nLevel)
            return pRenderSettingManager:SetQuality(nLevel)
        end,
        fnGetMax = function(pRenderSettingManager)
            local nValue = pRenderSettingManager:GetDeviceDefualtQuality()
            log("get frame max quality ", nValue) 
            return nValue
        end,
        fnGetDefault = function(pRenderSettingManager)
            return pRenderSettingManager:GetDeviceDefualtQuality()
        end
    },
    -- 帧数
    FPS = {
        nKey = LocalKeys.FPS_QUALITY,
        nMax = MAX_FPS,
        nMin = 0, 
        fnGet = function(pRenderSettingManager)
            return pRenderSettingManager:GetFPSQuality()
        end,
        fnSet = function(pRenderSettingManager, nLevel)
            return pRenderSettingManager:SetFPSQuality(nLevel)
        end,
        fnGetDefault = function(pRenderSettingManager)
            -- if pRenderSettingManager:GetDeviceDefualtQuality() == MAX_QUALITY then
            --     return MAX_FPS
            -- else
                return DEFAULT_FPS
            -- end
        end
    },
    -- 画面风格
    STYLE = {
        nKey = LocalKeys.FRAME_STYLE,
        nMax = MAX_STYLE,
        nMin = 0, 
        fnGet = function(pRenderSettingManager)
            local nValue = pRenderSettingManager:GetPictureStyle()
            log("get frame style ", nValue)
            return nValue
        end,
        fnSet = function(pRenderSettingManager, nLevel)
            log("set frame style ", nLevel)
            return pRenderSettingManager:SetPictureStyle(nLevel)
        end,
        fnGetDefault = function(pRenderSettingManager)
            local nValue = pRenderSettingManager:GetDeviceDefualtPictureStyle()
            log("get default frame style ")
            return nValue
        end
    },
    -- 亮度
    BRIGHTNESS = {
        nKey = LocalKeys.FRAME_BRIGHTNESS,
        fnGet = function(pRenderSettingManager)
            local nValue = pRenderSettingManager:GetPictureBrightness()
            log("get brightness ", nValue)
            return nValue
        end,
        fnSet = function(pRenderSettingManager, nLevel)
            return pRenderSettingManager:SetPictureBrightness(nLevel)
        end,
        fnGetMax = function(pRenderSettingManager)
            local nValue = pRenderSettingManager:GetPictureMaxBrightness()
            log("get max brightness ", nValue)
            return nValue
        end,
        fnGetMin = function(pRenderSettingManager)
            local nValue = pRenderSettingManager:GetPictureMinBrightness()
            log("get min brightness ", nValue)
            return nValue
        end,
        fnGetDefault = function(pRenderSettingManager)
            local nValue = pRenderSettingManager:GetDeviceDefualtPictureBrightness()
            log("get default brightness ", nValue)
            return nValue
        end
    },
    -- 自适应
    AUTOADAPTIVE = {
        nKey = LocalKeys.AUTO_ADAPTIVE,
        nMax = MAX_AUTOADAPTIVE,
        nMin = 0,
        fnGet = function(pRenderSettingManager)
            return pRenderSettingManager:IsAutoAdaptive() and 1 or 0
        end,
        fnSet = function(pRenderSettingManager, nLevel)
            return pRenderSettingManager:SetAutoAdaptive(nLevel > 0 and true or false)
        end,
        fnGetDefault = function(pRenderSettingManager)
            return pRenderSettingManager:IsDeviceDefualtAutoAdaptive() and 1 or 0
        end
    },
    -- 异形屏边距
    CUTOUTSPACERWIDTH = {
        nKey = LocalKeys.CUTOUT_SPACER_WIDTH,
        nMax = MAX_CUTOUT_SPACER_WIDTH,
        nMin = MIN_CUTOUT_SPACER_WIDTH,
        fnGet = function(pRenderSettingManager)
            return nCutoutSpacerWidth
        end,
        fnSet = function(pRenderSettingManager, nWidth)
            nCutoutSpacerWidth = nWidth
            return nCutoutSpacerWidth
        end,
        fnGetDefault = function(pRenderSettingManager)
            return ScreenShapeHelper.GetDefaultCutoutSpacerWidth()
        end
    }
}

SettingFrame.pDelegate = nil

local function GetSetting(self, nKey)
    for k, v in pairs(FRAMES) do
        if v.nKey == nKey then
            return v
        end
    end
end

local function OnRenderQualityAutoAdaptived(nLastQualityLevel, nCurQualityLevel)
    if nCurQualityLevel > nLastQualityLevel then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FRAME_QUALITY_UP"))
    elseif nCurQualityLevel < nLastQualityLevel then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FRAME_QUALITY_DOWN"))
    end
end

function SettingFrame:Init(Owner)
    SettingFrame.super.Init(self, Owner)
    local pRenderSettingManager = ClientShell.GetClient(GWorld):GetRenderSettingsManager()
    if pRenderSettingManager == nil then
        return
    end

    self.pDelegate = CppDelegate:Bind(pRenderSettingManager.OnRenderQualityAutoAdaptived, OnRenderQualityAutoAdaptived)
    
    pRenderSettingManager:SetPictureBrightnessRange(MIN_BRIGHTNESS, MAX_BRIGHTNESS)
    local tbBrightness = SettingIni.tbBrightness
    pRenderSettingManager:SetPictureBrightnessRangeInner(tbBrightness.nMin,  tbBrightness.nMax)
end

function SettingFrame:Uninit()
    if self.pDelegate ~= nil then
        self.pDelegate:Unbind()
        self.pDelegate = nil
    end
 end

function SettingFrame:LoadLocalSetting()
    local pRenderSettingManager = ClientShell.GetClient(GWorld):GetRenderSettingsManager()
    if pRenderSettingManager == nil then
        return
    end

    for k, v in pairs(FRAMES) do
        local nKey = v.nKey
        local nValue = self.Owner:Get(nKey)
        if nValue < 0 then
            if nKey == LocalKeys.CUTOUT_SPACER_WIDTH then
                nValue = v.fnGetDefault(pRenderSettingManager)
            else
                nValue = v.fnGetDefault(pRenderSettingManager)
            end
            self.Owner:Set(nKey, nValue)
            v.fnSet(pRenderSettingManager, nValue)
        else
            v.fnSet(pRenderSettingManager, nValue)
        end
    end
end

function SettingFrame:Get(nKey)
    local nValue = SettingFrame.super.Get(self, nKey)
    if nValue < 0 then
        local pRenderSettingManager = ClientShell.GetClient(GWorld):GetRenderSettingsManager()
        if pRenderSettingManager == nil then
            return nValue
        end
        local tbSetting = GetSetting(self, nKey)
        if tbSetting then
            nValue = tbSetting.fnGet(pRenderSettingManager)
        end
        return nValue
    else
        return nValue
    end
end

function SettingFrame:Set(nKey, nValue)
    local tbSetting = GetSetting(self, nKey)
    if tbSetting == nil then
        logwarning("Setting_Frame:Set failed: not find key", nKey)
        return
    end
    local pRenderSettingManager = ClientShell.GetClient(GWorld):GetRenderSettingsManager()
    if pRenderSettingManager == nil then
        logwarning("Setting_Frame:Set failed: no render setting manager", nKey)
        return
    end
    if tbSetting.fnSet(pRenderSettingManager, nValue) then
        SettingFrame.super.Set(self, nKey, nValue)
    end
end

function SettingFrame:GetMaxValue(nKey)
    local tbSetting = GetSetting(self, nKey)
    if tbSetting == nil then
        logwarning("Setting_Frame:GetMaxValue failed: not find key", nKey)
        return
    end
    if tbSetting.nMax ~= nil then
        return tbSetting.nMax
    end
    local pRenderSettingManager = ClientShell.GetClient(GWorld):GetRenderSettingsManager()
    if pRenderSettingManager == nil then
        logwarning("Setting_Frame:GetMaxValue failed: no render setting manager", nKey)
        return
    end
    return tbSetting.fnGetMax(pRenderSettingManager)
end

function SettingFrame:GetMinValue(nKey)
    local tbSetting = GetSetting(self, nKey)
    if tbSetting == nil then
        logwarning("Setting_Frame:GetMinValue failed: not find key", nKey)
        return
    end
    if tbSetting.nMin ~= nil then
        return tbSetting.nMin
    end
    local pRenderSettingManager = ClientShell.GetClient(GWorld):GetRenderSettingsManager()
    if pRenderSettingManager == nil then
        logwarning("Setting_Frame:GetMinValue failed: no render setting manager", nKey)
        return
    end
    return tbSetting.fnGetMin(pRenderSettingManager)
end

function SettingFrame:Reset()
    local pRenderSettingManager = ClientShell.GetClient(GWorld):GetRenderSettingsManager()
    if pRenderSettingManager == nil then
        logwarning("Setting_Frame:Reset failed: no render setting manager")
        return
    end

    for k, v in pairs(FRAMES) do
        local nKey = v.nKey
        local nDefaultValue = v.fnGetDefault(pRenderSettingManager)
        if v.fnSet(pRenderSettingManager, nDefaultValue) then
            self.Owner:Set(nKey, nDefaultValue)
        end
    end
end

return SettingFrame