-----------------------------------------------------
--File Name    : ScreenShapeHelper.lua
--Author       : zhiyuan
--Create Time  : 2019-07-11
--Description  : 判断屏幕形状的helper
-----------------------------------------------------
local ScreenShapeHelper = {}

local RoundedScreenDataTable = require("RoundedScreenDataTable")

local PLATFORM_NAME_IOS = "IOS"

local SAFE_ZONE_MARGIN_BOTTOM = 30
local SAFE_ZONE_NO_MARGIN = 0
local WIDESCREEN_ASPECT = 2

ScreenShapeHelper.Shape =
{
    NORMAL   = 0,   -- 普通方屏
    ROUNDED  = 1,   -- 圆角屏
    CUTOUT   = 2,   -- 缺口屏
}

-- 这个值是死的，改了之后涉及到改UI，所以直接配在代码里了，没有提供ini/tab配置
local DEFAULT_CUTOUT_SPACER_WIDTH =
{
    [ScreenShapeHelper.Shape.NORMAL]    = 0,
    [ScreenShapeHelper.Shape.ROUNDED]   = 60,
    [ScreenShapeHelper.Shape.CUTOUT]    = 100,
}

-- 长宽比超过2，就认为事宽屏手机
local function IsWidescreen()
    local pViewportSize = WidgetLayoutLibrary.GetViewportSize(GWorld)
    return pViewportSize.X / pViewportSize.Y > WIDESCREEN_ASPECT
end

local function GetScreenShape()
    log("[ScreenShapeHelper] GetScreenShape")
    local Shape = ScreenShapeHelper.Shape
    if GamePlatformMiscLibrary.IsCutoutScreen() then
        log("[ScreenShapeHelper] Shape.CUTOUT")
        return Shape.CUTOUT
    end

    local szDeviceModel = RenderExtendBlueprintFunctions.GetDeviceModel()
    log("[ScreenShapeHelper] DeviceModel =", szDeviceModel)
    if RoundedScreenDataTable:IsRoundedScreen(szDeviceModel) then
        log("[ScreenShapeHelper] Shape.ROUNDED")
        return Shape.ROUNDED
    end

    -- 长宽比超过2的市面手机，大部分都是刘海屏，对于上面接口没有判断成功的，用此规则进行通用判断
    if IsWidescreen() then
        log("[ScreenShapeHelper] Widescreen Shape.CUTOUT")
        return Shape.CUTOUT
    end

    log("[ScreenShapeHelper] Shape.NORMAL")
    return Shape.NORMAL
end

function ScreenShapeHelper.GetDefaultCutoutSpacerWidth()
    local nScreenShape = GetScreenShape()
    return DEFAULT_CUTOUT_SPACER_WIDTH[nScreenShape]
end

-- 获取UI安全区底部间隔（目前只有IOS平台的异形屏手机有）
function ScreenShapeHelper.GetSafeZoneMarginBottom()
    local szPlatformName = GameplayStatics.GetPlatformName()
    if szPlatformName ~= PLATFORM_NAME_IOS then
        return SAFE_ZONE_NO_MARGIN
    end
    local nScreenShape = GetScreenShape()
    if nScreenShape ~= ScreenShapeHelper.Shape.CUTOUT then
        return SAFE_ZONE_NO_MARGIN
    end
    return SAFE_ZONE_MARGIN_BOTTOM
end

return ScreenShapeHelper