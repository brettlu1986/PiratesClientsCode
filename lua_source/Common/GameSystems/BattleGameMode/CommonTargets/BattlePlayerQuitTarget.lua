-- 玩家退出副本

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattlePlayerQuitTarget = luaclass("BattlePlayerQuitTarget", BattleTargetBaseClass)

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local BattleBlackboard = require("BattleBlackboard")
local GameObjectTypeDef = require("GameObjectTypeDef")

BattlePlayerQuitTarget.szPlayerKey = nil

function BattlePlayerQuitTarget:Init()
    BattlePlayerQuitTarget.super.Init(self)
    self.szName = "BattlePlayerQuitTarget"    
end

function BattlePlayerQuitTarget:Parse(tbJsonData)
    self.szPlayerKey = tbJsonData.PlayerKey
    return true
end

function BattlePlayerQuitTarget:PlayerLoginOut(tbGamePlayer)
    if tbGamePlayer.ObjectType == GameObjectTypeDef.PlayerSelf then
        if(not tbGamePlayer:IsDead()) then
            if self.szPlayerKey and string.len(self.szPlayerKey) > 0 then
                BattleBlackboard:SetTable(self.szPlayerKey, tbGamePlayer)
            end
        end
    end

    self:Complete()
end

function BattlePlayerQuitTarget:RegisterEvent()
    -- EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, self.PlayerLoginOut)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, self.PlayerLoginOut)
end

function BattlePlayerQuitTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, self.PlayerLoginOut)
end

function BattlePlayerQuitTarget:Start()
    BattlePlayerQuitTarget.super.Start(self)    
end


return BattlePlayerQuitTarget
