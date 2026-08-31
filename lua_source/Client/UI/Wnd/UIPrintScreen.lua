-----------------------------------------------------
--File Name    : UIPrintScreen.lua
--Author       : Song Fuhao
--Create Time  : 2020-02-17
--Description  : 用于打印文本到屏幕上（替代引擎的PrintScreen）
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIPrintScreen = luaclass("UIPrintScreen", WndBase)

local UIResourceDef = require("UIResourceDef")
local SelfListHelperNew = require("SelfListHelperNew")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local DEFAULT_TIME_TO_DISPLAY = 3
local DEFAULT_SCALE = 1

UIPrintScreen.tbLogList = nil
UIPrintScreen.tbListHelper = nil
UIPrintScreen.tbNextTickTimer = nil

-- 避免一帧内多次调用SetData
local function RefreshOnNextTick(self)
    if not self.tbNextTickTimer then
        self.tbNextTickTimer = self.TimerHelper:RunNextTick(function()
            self.tbNextTickTimer = nil
            self.tbListHelper:SetData(self.tbLogList)
        end)
    end
end

function UIPrintScreen:OnLoad()
    self.tbLogList = {}
    self.tbListHelper = SelfListHelperNew()
    self.tbListHelper:Init(self, self.pWidgetRef.listLog, self.tbLogList)
end

function UIPrintScreen:OnUnload()
    self.tbListHelper:Uninit()
end

function UIPrintScreen:PrintScreen(szMessage, nTimeToDisplay, pSlateColor, nScale)
    local tbData = {
        szMessage = szMessage or "PrintScreen need a message.",
        pSlateColor = pSlateColor or UIResourceDef.COLOR.WHITE.SLATE_COLOR,
        nScale = nScale or DEFAULT_SCALE,
    }
    table.insert(self.tbLogList, 1, tbData) -- 新消息显示在最前面
    self.TimerHelper:NewTimer(function()
        for i,v in ipairs(self.tbLogList) do
            if v == tbData then
                table.remove(self.tbLogList, i)
                break
            end
        end
        RefreshOnNextTick(self)
    end, nTimeToDisplay or DEFAULT_TIME_TO_DISPLAY)
    RefreshOnNextTick(self)
end

-- @Override
function UIPrintScreen:CanOpen()
    return GlobalVariableSystem:IsDevMode()
end

return UIPrintScreen