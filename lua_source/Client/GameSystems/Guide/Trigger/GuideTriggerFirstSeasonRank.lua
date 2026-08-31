-----------------------------------------------------
--File Name    : GuideTriggerFirstSeasonRank.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerFirstSeasonRank   = luaclass("GuideTriggerFirstSeasonRank",GuideTrigger)

local ClientEventDef    = require("ClientEventDef")
local UIDef             = require("UIDef")
local UIManager         = require("UIManager")
-----------------------------------------------------
--override
function GuideTriggerFirstSeasonRank:OnOpenSeasonRank(szWndName)
    if szWndName == UIDef.UI_SEASON_BATTLEPASS then
        local Wnd = UIManager:GetWnd(UIDef.UI_SEASON_BATTLEPASS)
        self:DebugLog("onRank:OnOpenSeasonRank, ngroup = " .. self.tbGuideTemplate.nGroup .. " nstep = "..self.tbGuideTemplate.nStep .. " Is New = " .. tostring(Wnd.tbOpenArgs.bIsNew))
        if Wnd.tbOpenArgs.bIsNew then
            self:Trigger()
        end
    end
end

function GuideTriggerFirstSeasonRank:CkeckIsBeNew()
    local Wnd = UIManager:GetWnd(UIDef.UI_SEASON_BATTLEPASS)
    if not Wnd then
        return
    end
    self:DebugLog("onRank:CkeckIsBeNew" .. " Is New = " .. tostring(Wnd.tbOpenArgs.bIsNew))
    if Wnd.tbOpenArgs.bIsNew then
        self:Trigger()
    end
end

function GuideTriggerFirstSeasonRank:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_OPEN_UI, self, self.OnOpenSeasonRank)
end

function GuideTriggerFirstSeasonRank:Begin()
    self:DebugLog("onRank:Begin, ngroup = " .. self.tbGuideTemplate.nGroup .. " nstep = "..self.tbGuideTemplate.nStep)
    GuideTriggerFirstSeasonRank.super.Begin(self)
    if self:CkeckIsBeNew() then
        self:Trigger()
    end
end

return GuideTriggerFirstSeasonRank
