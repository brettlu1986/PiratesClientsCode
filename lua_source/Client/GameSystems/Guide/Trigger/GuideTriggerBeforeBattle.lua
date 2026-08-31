-----------------------------------------------------
--File Name    : GuideTriggerBeforeBattle.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerBeforeBattle      = luaclass("GuideTriggerBeforeBattle",GuideTrigger)

local ClientEventDef                = require("ClientEventDef")
local DelayTimer                    = require("DelayTimer")
local GlobalVariableSystem          = dynamic_require("GlobalVariableSystem")
-----------------------------------------------------
local DELAY_SEC = 2

GuideTriggerBeforeBattle.nReminTime         = nil
GuideTriggerBeforeBattle.nLimit             = nil
GuideTriggerBeforeBattle.DelayTimerHandle   = nil
-----------------------------------------------------
local function ClearTimer(self)
    if self.DelayTimerHandle then
        DelayTimer:ClearTimer(self.DelayTimerHandle)
    end
end

local function CheckReminTime(self)
    local nReminTime = self.nReminTime
    if nReminTime == nil or nReminTime > self.nLimit then
        self:Trigger()
    else
        self:Break() 
    end
end

local function OnLoadingFinish(self)
    local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
    if bIsInDungeon then
        ClearTimer(self)
        self.DelayTimerHandle = DelayTimer:DelayRun(function() CheckReminTime(self) end, DELAY_SEC)
    end
end

local function OnBattleRemineTime(self, tbPacket)
    local nReminTime = tbPacket.nTime
    self.nReminTime = nReminTime
    if nReminTime > self.nLimit then
        self:Trigger()
    else
        self:Break()
    end
end

--override
function GuideTriggerBeforeBattle:Begin()
    GuideTriggerBeforeBattle.super.Begin(self)
    local tbParam = self.tbTemplate.tbParam 
    if tbParam and tbParam[1] then
        self.nLimit = tonumber(tbParam[1])
    end
end

function GuideTriggerBeforeBattle:End()
    GuideTriggerBeforeBattle.super.End(self)
    ClearTimer(self)
end

function GuideTriggerBeforeBattle:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_STEP_REMAIN_TIME, self, OnBattleRemineTime)
    EventHelper:RegisterEvent(ClientEventDef.EV_EXIT_LOADING, self, OnLoadingFinish)
end

return GuideTriggerBeforeBattle
