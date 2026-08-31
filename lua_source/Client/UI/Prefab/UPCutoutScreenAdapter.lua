-----------------------------------------------------
--File Name    : UPCutoutScreenAdapter.lua
--Author       : Song Fuhao
--Create Time  : 2019-07-05
--Description  : 异形屏适配框架
-----------------------------------------------------
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPCutoutScreenAdapter = luaclass("UPCutoutScreenAdapter", PrefabBase)

local MathUtil = require("MathUtil")
local SettingKeyDef = require("SettingKeyDef")
local SettingClassType = require("SettingClassType")
local SettingSystemNew = require("SettingSystemNew")

local SETTING_KEYS = SettingKeyDef.LocalKeys
local DEFAULT_ASPECT = 16 / 9               -- 屏幕默认默认长宽比
local DEFAULT_VIEWPORT_WIDTH = 1920         -- 宽屏默认适配宽度

local pSpacerSize = nil                     -- 游戏运行期间只取一次
local nCutoutSpacerWidth = 0                -- 游戏运行期间只取一次

local function CalculateCutoutSpacerWidth(self)
    local tbSettingInstance = SettingSystemNew:GetInstance(SettingClassType.Setting_Frame)
    local nSettingCutoutSpacerWidth = tbSettingInstance:Get(SETTING_KEYS.CUTOUT_SPACER_WIDTH)
    if nSettingCutoutSpacerWidth > 0 then
        local nViewPortScale = WidgetLayoutLibrary.GetViewportScale(GWorld)
        local pViewportSize = WidgetLayoutLibrary.GetViewportSize(GWorld)
        local pRealViewPortSize = KismetMathLibrary.Divide_Vector2DFloat(pViewportSize, nViewPortScale)
        local nViewportWidth = pRealViewPortSize.X
        local nViewportHeight = pRealViewPortSize.Y
        if nViewportWidth / nViewportHeight > DEFAULT_ASPECT then -- 只对超过16:9的宽屏手机进行适配
            return MathUtil.Clamp((nViewportWidth - DEFAULT_VIEWPORT_WIDTH) / 2, 0, nSettingCutoutSpacerWidth)
        end
    end
    return 0
end

local function LoadSpacerSize(self)
    if not pSpacerSize then
        nCutoutSpacerWidth = CalculateCutoutSpacerWidth(self)
        if nCutoutSpacerWidth > 0 then
            log("[UPCutoutScreenAdapter] nCutoutSpacerWidth =", nCutoutSpacerWidth)
            pSpacerSize = KismetMathLibrary.MakeVector2D(nCutoutSpacerWidth, 0)
        end
    end
end

function UPCutoutScreenAdapter:OnLoad()
    LoadSpacerSize(self)
    if pSpacerSize then
        log("[UPCutoutScreenAdapter] Set spacer size", pSpacerSize.X, pSpacerSize.Y)
        self.pWidgetRef.sprLeft:SetSize(pSpacerSize)
        self.pWidgetRef.sprRight:SetSize(pSpacerSize)
    end
end

-- 获取手机刘海屏适配边距（单边宽度）
function UPCutoutScreenAdapter:GetCutoutSpacerWidth()
    return nCutoutSpacerWidth
end

return UPCutoutScreenAdapter
