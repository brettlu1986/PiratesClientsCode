-- 玩家死亡

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattlePlayerDeadTarget = luaclass("BattlePlayerDeadTarget", BattleTargetBaseClass)

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattlePlayerHelper = require("BattlePlayerHelper")
local BattleBlackboard = require("BattleBlackboard")

BattlePlayerDeadTarget.bCanRepeat = true
BattlePlayerDeadTarget.szSetDeadKey = nil
BattlePlayerDeadTarget.szSetKillerKey = nil

function BattlePlayerDeadTarget:Init()
    BattlePlayerDeadTarget.super.Init(self)
    self.szName = "BattlePlayerDeadTarget"    
end

function BattlePlayerDeadTarget:Parse(tbJsonData)
    self.bCanRepeat = tbJsonData.CanRepeat
    self.szSetDeadKey = tbJsonData.SetDeadKey
    self.szSetKillerKey = tbJsonData.SetKillerKey
    return true
end

-- TODO 玩家唯一标识,重进副本id是否变化
function BattlePlayerDeadTarget:OnPawnDead(tbDeadActor)
    local tbKillerActor = nil--tbDeadActor.BattleStatusComponent:GetLastDamageCauser()
    if tbDeadActor.ObjectType == GameObjectTypeDef.PlayerSelf then
        local bDead = BattlePlayerHelper:CheckInDeadList(tbDeadActor.nPlayerId)
        if self.bCanRepeat or bDead == false then
            if self.szSetDeadKey and string.len(self.szSetDeadKey) > 0 then
                BattleBlackboard:SetTable(self.szSetDeadKey, tbDeadActor)
            end
            if self.szSetKillerKey and string.len(self.szSetKillerKey) > 0 then
                BattleBlackboard:SetTable(self.szSetKillerKey, tbKillerActor)
            end
            self:Complete()
        end
    end
end

function BattlePlayerDeadTarget:OnLogout(tbGamePlayer)
    if tbGamePlayer.ObjectType == GameObjectTypeDef.PlayerSelf then
        if(not tbGamePlayer:IsDead()) then
            self:OnPawnDead(tbGamePlayer)
        end
    end
end

function BattlePlayerDeadTarget:RegisterEvent()
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, self.OnLogout)
end

function BattlePlayerDeadTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, self.OnLogout)
end

function BattlePlayerDeadTarget:Start()
    BattlePlayerDeadTarget.super.Start(self)    
end


return BattlePlayerDeadTarget
