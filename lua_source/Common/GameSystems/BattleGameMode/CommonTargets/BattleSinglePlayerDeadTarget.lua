-- 单机副本玩家退出或死亡


local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleSinglePlayerDeadTarget = luaclass("BattleSinglePlayerDeadTarget", BattleTargetBaseClass)

local GameObjectTypeDef = require("GameObjectTypeDef")

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")

function BattleSinglePlayerDeadTarget:Init()
    BattleSinglePlayerDeadTarget.super.Init(self)
    self.szName = "BattleSinglePlayerDeadTarget"
end

function BattleSinglePlayerDeadTarget:OnPawnDead(tbDeadActor)
    if tbDeadActor.ObjectType == GameObjectTypeDef.PlayerSelf then
        self:Complete()
    end
end

function BattleSinglePlayerDeadTarget:OnLogout(tbGamePlayer)
    if(not tbGamePlayer:IsDead()) then
        self:OnPawnDead(tbGamePlayer)
    end
end

function BattleSinglePlayerDeadTarget:RegisterEvent()
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, self.OnLogout)
end

function BattleSinglePlayerDeadTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)   
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, self.OnLogout)
end


return BattleSinglePlayerDeadTarget
