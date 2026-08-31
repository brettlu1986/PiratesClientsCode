-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerMapEnemySound     = luaclass("GuideTriggerMapEnemySound", GuideTrigger)

local ClientEventDef    = require("ClientEventDef")
-----------------------------------------------------
GuideTriggerMapEnemySound.nSoundType = 3 --FFA_SOUND_HUMAN_FIRE
-----------------------------------------------------

function GuideTriggerMapEnemySound:OnMapEnemySound(nSoundType)
    self:DebugLog("OnMapEnemySound nSoundType = " .. tostring(nSoundType) .. " self.nSoundType = " .. self.nSoundType)
    if self.nSoundType == nSoundType then
        self:Trigger()
    end
end

--override
function GuideTriggerMapEnemySound:Begin()
    GuideTriggerMapEnemySound.super.Begin(self)
    local tbParam = self.tbTemplate.tbParam 
    if tbParam and tbParam[1] then
        self.nSoundType = tonumber(tbParam[1])
    end
end

function GuideTriggerMapEnemySound:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_RADARMAP_ENEMY_SOUND, self, self.OnMapEnemySound)
end

return GuideTriggerMapEnemySound
