-----------------------------------------------------
--File Name    : GuideTriggerCloseUI.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerEnterBattleCount  = luaclass("GuideTriggerEnterBattleCount", GuideTrigger)

local GuideSystem           = require("GuideSystem")
local ClientEventDef        = require("ClientEventDef")
-----------------------------------------------------
function GuideTriggerEnterBattleCount:OnEnterBattle()
    if self:CheckEnterBattleCount() then
        self:Trigger()
    else
        self:Break()
    end
end

function GuideTriggerEnterBattleCount:CheckEnterBattleCount()
    local nTargetCount = self.tbTemplate.nEnterBattleCount
    local nCurrentCount = GuideSystem.nEnterBattleCount
    self:DebugLog("CheckEnterBattleCount, EnterBattleCount=" .. nCurrentCount .. "templateCount=" .. nTargetCount)
    local tbTemplate = self.tbTemplate
    local tbParams = tbTemplate.tbParam
    if tbParams == nil then
        self:DebugLog("CheckEnterBattleCount Check equal！")
        return nCurrentCount == nTargetCount
    else
        local nParam = tonumber(tbParams[1])
        self:DebugLog("CheckEnterBattleCount Check！" .. tostring(nParam))
        if nParam > 0 then
            return nCurrentCount >= nTargetCount
        else
            return nCurrentCount <= nTargetCount
        end
    end
    
end

--override
function GuideTriggerEnterBattleCount:Begin()
    GuideTriggerEnterBattleCount.super.Begin(self)
    if self:CheckEnterBattleCount() then
        self:Trigger()
    else
        self:Break()
    end
end

function GuideTriggerEnterBattleCount:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SET_ENTER_BATTLE_COUNT, self, self.OnEnterBattle)
end

return GuideTriggerEnterBattleCount
