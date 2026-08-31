-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass              = require("luaclass")
local GuideTrigger          = require("GuideTrigger")
local GuideTriggerKillPlayer  = luaclass("GuideTriggerKillPlayer", GuideTrigger)

local CommonEventDef    = require("CommonEventDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
-----------------------------------------------------
GuideTriggerKillPlayer.nTemplateId = nil
-----------------------------------------------------

function GuideTriggerKillPlayer:OnPawnDead(tbDead, tbCauser)
    self:DebugLog("OnPawnDead ")
    if not tbDead or not tbCauser then
        self:LogError("tbDead or tbCauser is nil")
        return
    end
    if tbDead.ObjectType ~= GameObjectTypeDef.PlayerSelf and tbCauser.ObjectType == GameObjectTypeDef.PlayerSelf then
        --logdebug("########self.nTemplateId = " .. self.nTemplateId .. " tbDead.nTemplateId = " .. tbDead.nTemplateId .. "##############")
        if self.nTemplateId then
            if self.nTemplateId == tbDead.nTemplateId then
                self:Trigger()
            else
                self:Break()
            end
        else
            self:Trigger()
        end 
    end
end

--override
function GuideTriggerKillPlayer:Begin()
    GuideTriggerKillPlayer.super.Begin(self)
    local tbParam = self.tbTemplate.tbParam 
    if tbParam and tbParam[1] then
        self.nTemplateId = tonumber(tbParam[1])
    end
end

function GuideTriggerKillPlayer:BindEvent(EventHelper)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_PRE_DEAD, self, self.OnPawnDead)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
end

return GuideTriggerKillPlayer
