local luaclass = require("luaclass")
local BattleDataStatisticsSystem = require("BattleDataStatisticsSystem")
local BattleDataStatisticsSystem_C = luaclass("BattleDataStatisticsSystem_C", BattleDataStatisticsSystem)
local CommonEventDef = require("CommonEventDef")
local GameObjectTypeDef = require("GameObjectTypeDef")

local function OnActorCreate(self, tbGameObject)
    if tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf then
        self:RegisterCharacter(tbGameObject)
    end
end

function BattleDataStatisticsSystem_C:BindEvent()
    BattleDataStatisticsSystem_C.super.BindEvent(self)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, OnActorCreate)
end

function BattleDataStatisticsSystem_C:Init()
    BattleDataStatisticsSystem_C.super.Init(self)

    return true
end

function BattleDataStatisticsSystem_C:Uninit()
    BattleDataStatisticsSystem_C.super.Uninit(self)     
end

return BattleDataStatisticsSystem_C()