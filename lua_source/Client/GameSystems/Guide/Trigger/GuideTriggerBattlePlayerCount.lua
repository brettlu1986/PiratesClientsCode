-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideTrigger                      = require("GuideTrigger")
local GuideTriggerBattlePlayerCount     = luaclass("GuideTriggerBattlePlayerCount", GuideTrigger)

local ClientEventDef    = require("ClientEventDef")
-----------------------------------------------------

function GuideTriggerBattlePlayerCount:OnFFAInfoChnaged(rInfo)
    self:DebugLog("OnFFAInfoChnaged, PlayerCount = " .. rInfo.nAlivePlayerCount)
    local tbParam = self.tbTemplate.tbParam
    if not tbParam then
        return
    end
    local nCount = tonumber(tbParam[1])
    self:DebugLog("nCount = " .. tostring(nCount))
    if rInfo.nAlivePlayerCount and rInfo.nAlivePlayerCount >= nCount then
        self:Trigger()
    end
end

--override
function GuideTriggerBattlePlayerCount:Begin()
    GuideTriggerBattlePlayerCount.super.Begin(self)
end

function GuideTriggerBattlePlayerCount:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_INFO_CHANGED, self, self.OnFFAInfoChnaged)
end

return GuideTriggerBattlePlayerCount
