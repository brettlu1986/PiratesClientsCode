-----------------------------------------------------
--File Name    : GuideActionSelectWidgetInLobbyMain.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideActionSelectWidget               = require("GuideActionSelectWidget")
local GuideActionSelectWidgetInLobbyMain    = luaclass("GuideActionSelectWidgetInLobbyMain", GuideActionSelectWidget)

local UIDef             = require("UIDef")
local ClientEventDef    = require("ClientEventDef")
local DelayTimer        = require("DelayTimer")
local UIManager         = require("UIManager")
----------------------------------------------------------
local tbSpecialWidget = {"bdrMic", "bdrMicPress", "bdrSpeaker"}
----------------------------------------------------------
local function OnSpecialWidgetOpen(self, bOpen)
    self:ActiveGuideWnd(bOpen)
end

local function CheckLobbySpecialWidgetVisiblity(self, tbTemplate)
    local tbMainWnd = UIManager:GetWnd(UIDef.UI_LOBBY_MAIN)
    if not tbMainWnd then
        return false
    end
    for i, szWidgetName in ipairs(tbSpecialWidget) do
        local pWidget = tbMainWnd.pWidgetRef[szWidgetName]
        if pWidget:IsVisible() then
            return true
        end
    end
    return false
end

function GuideActionSelectWidgetInLobbyMain:ActiveGuideWnd(bActive)
    self:DebugLog("ActiveGuideWnd, bActive = " .. tostring(bActive))
    local GuideWnd = self:GetGuideWnd()
    if not GuideWnd then
        return
    end
    if bActive then
        self:DebugLog("ActiveGuideWnd GuideWnd.bActivate = " .. tostring(GuideWnd.bActivate))
        if CheckLobbySpecialWidgetVisiblity(self) then
            return
        end
        if not GuideWnd.bActivate then
            if self.tbTemplate.nDelayTime > 0 then
                self:CloseDelayTimer()
                self.DelayTimerHandle = DelayTimer:DelayRun(function() 
                    GuideWnd:Activate()
                    self:RefreshOnGuideWnd() end, 
                self.tbTemplate.nDelayTime)
            end
        end
    else
        self:DebugLog("Deactivate")
        self:CloseDelayTimer()
        GuideWnd:Deactivate()
        self:StopEffectSound()
    end
end

function GuideActionSelectWidgetInLobbyMain:BindEvent()
    GuideActionSelectWidgetInLobbyMain.super.BindEvent(self)
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_LOBBY_SPECIAL_WIDGET_OPEN, self, OnSpecialWidgetOpen)
end
return GuideActionSelectWidgetInLobbyMain
