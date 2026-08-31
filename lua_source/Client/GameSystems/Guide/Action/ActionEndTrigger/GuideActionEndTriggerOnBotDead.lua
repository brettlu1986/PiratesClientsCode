-----------------------------------------------------
--File Name    : GuideActionEndTriggerOnBotDead.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideActionEndTriggerBase             = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerOnBotDead        = luaclass("GuideActionEndTriggerOnBotDead", GuideActionEndTriggerBase)

local CommonEventDef        = require("CommonEventDef")
local GameObjectTypeDef     = require("GameObjectTypeDef")
-----------------------------------------------------

local function OnPawnDead(self, tbDeadActor)
    if tbDeadActor and tbDeadActor.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        self:Triggered()
    end
end

function GuideActionEndTriggerOnBotDead:BindEvent(tbParam)
    GuideActionEndTriggerOnBotDead.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnPawnDead)
end

return GuideActionEndTriggerOnBotDead
