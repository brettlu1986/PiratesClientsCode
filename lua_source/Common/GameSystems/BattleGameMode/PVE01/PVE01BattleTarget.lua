-- 根据20级副本的玩法，这里的目标是，所有的NPC死亡，除了最后一个剩下40%的血

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local PVE01BattleTarget = luaclass("PVE01BattleTarget", BattleTargetBaseClass)

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")

PVE01BattleTarget.DeadGameObjectType = nil

-- GameObject.nUniqueId list
PVE01BattleTarget.tbTargetNpcInstanceList = nil

-- 最后一只NPC的血量 最好配置配置表
PVE01BattleTarget.nLastNpcBloodRatio = 0.0

-- 最后一个NPC实例
PVE01BattleTarget.LastBattleShipPropertyComponent = nil

local function LastNpcHPLessthanTarget(self)
    self.LastBattleShipPropertyComponent:UnBindHPReachRatioEvent(LastNpcHPLessthanTarget, self)
    self:Complete()
end

local function ProcessLastNpc(self, GameNpcInstance)
    local BattleShipPropertyComponent = GameNpcInstance.BattleShipPropertyComponent
    local nCurrentHP = BattleShipPropertyComponent:GetHp()
    local nMaxHP = BattleShipPropertyComponent.tbFightTemplate.nHp

    local nRatio = nCurrentHP/nMaxHP
    if nRatio < self.nLastNpcBloodRatio then
        self:Complete()
        return
    end
    self.LastBattleShipPropertyComponent = BattleShipPropertyComponent
    BattleShipPropertyComponent:BindHPReachRatioEvent(self.nLastNpcBloodRatio, true, LastNpcHPLessthanTarget, self)
end

function PVE01BattleTarget:Init()
    PVE01BattleTarget.super.Init(self)
    self.szName = "PVE01BattleTarget"
    self.tbTargetNpcInstanceList = {}
end

function PVE01BattleTarget:SetParams(DeadGameObjectType, tbNpcInstanceList)
    self.DeadGameObjectType = DeadGameObjectType
    self.tbTargetNpcInstanceList = tbNpcInstanceList
end

function PVE01BattleTarget:OnPawnDead(DeadGameNpc)
    local DeadGameObjectType = self.DeadGameObjectType
    if(DeadGameObjectType ~= nil and DeadGameNpc.ObjectType ~= DeadGameObjectType) then
        log('PVE01BattleTarget:OnPawnDead(), dead game object type not fit : ', DeadGameNpc.ObjectType)
        return
    end

    for k, NpcInstance in pairs(self.tbTargetNpcInstanceList) do
        if DeadGameNpc == NpcInstance then
            table.remove(self.tbTargetNpcInstanceList, k)
            break
        end
    end

    local nRemainCount = #self.tbTargetNpcInstanceList

    if nRemainCount == 1 then
        ProcessLastNpc(self, self.tbTargetNpcInstanceList[1])
    end

    if nRemainCount == 0 then
        self:Complete()
    end
end

function PVE01BattleTarget:OnLogout(tbGamePlayer)
    if(not tbGamePlayer:IsDead()) then
        self:OnPawnDead(tbGamePlayer)
    end
end

function PVE01BattleTarget:RegisterEvent()
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, self.OnLogout)
end

function PVE01BattleTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, self.OnLogout)
end


return PVE01BattleTarget
