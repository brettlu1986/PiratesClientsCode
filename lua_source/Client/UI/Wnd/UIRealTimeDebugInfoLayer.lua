-----------------------------------------------------
--File Name    : UIRealTimeDebugInfoLayer.lua
--Author       : Song Fuhao
--Create Time  : 2019-07-05
--Description  : 布局设置风格选择框
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIRealTimeDebugInfoLayer = luaclass("UIRealTimeDebugInfoLayer", WndBase)

local MathUtil = require("MathUtil")
local UIUtils = require("UIUtils")

local DEFAULT_DISPLAY_TIME = 10

local function OnClickBtnTakeScreenshot(self)
    local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
    local pUEActor = GamePlayerSelfHelper:GetUEActor()
    local pLocation = pUEActor:K2_GetActorLocation()
    local pRotation = pUEActor:K2_GetActorRotation()
    local nX = MathUtil.Round(pLocation.X)
    local nY = MathUtil.Round(pLocation.Y)
    local nZ = MathUtil.Round(pLocation.Z)
    local nYaw = MathUtil.Round(pRotation.Yaw)
    local szFileName = string.format("Location/dm teleport %d %d %d %d.jpg", nX, nY, nZ, nYaw)
    ClientShell.GetClient(GWorld):GetCameraShotShell():RequestScreenshot(true, true, szFileName, true, 0.7)
    log("Take screenshot, filename =", szFileName)
    UIUtils.ShowToast(szFileName)
end

function UIRealTimeDebugInfoLayer:OnBindEvent(EventHelper)
    self.EventHelper:RegisterCppDelegate(self.pWidgetRef.btnTakeScreenshot.OnClicked, self, OnClickBtnTakeScreenshot)
    self.EventHelper:RegisterCppDelegate(self.pWidgetRef.btnClose.OnClicked, self, self.CloseSelf)
end

-- 目前为了快速接入，逻辑在蓝图里
function UIRealTimeDebugInfoLayer:OnEnter()
    local tbOpenArgs = self.tbOpenArgs
    local nDisplayTime = tbOpenArgs.nDisplayTime or DEFAULT_DISPLAY_TIME
    log("[UIRealTimeDebugInfoLayer] nDisplayTime =", nDisplayTime)
    self.TimerHelper:NewDelayRunTimerMethod(self, self.CloseSelf, nDisplayTime)
end

return UIRealTimeDebugInfoLayer