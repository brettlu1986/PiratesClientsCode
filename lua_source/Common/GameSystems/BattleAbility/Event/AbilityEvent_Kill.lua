-----------------------------------------------------
--File Name    : AbilityEvent_Kill.lua
--Author       : Song Fuhao
--Create Time  : 2018-10-11
--Description  : 击杀任意目标
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityEventBaseClass = require("AbilityEventBase")
local AbilityEvent_Kill = luaclass("AbilityEvent_Kill", AbilityEventBaseClass)

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

local function OnGameObjectOnPawnDead(self, tbDead, tbKiller)
    if tbKiller == self.OwnerPawn then
        self:TriggerDo()
    end
end

function AbilityEvent_Kill:OnActivate()
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnGameObjectOnPawnDead)
end

function AbilityEvent_Kill:OnDeactivate()
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnGameObjectOnPawnDead)
end

return AbilityEvent_Kill
