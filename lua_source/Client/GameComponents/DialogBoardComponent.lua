local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase") 
local DialogBoardComponent = luaclass("DialogBoardComponent", GameComponentBaseClass)

local SelfEventHelperClass = require("SelfEventHelper")
local NpcDialogBoardSystem = require("NpcDialogBoardSystem")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local DungeonDataTable = require("DungeonDataTable")
local NpcDialogBoardDataTable = require("NpcDialogBoardDataTable")
local IntervalTimeDef = require("IntervalTimeDef")
-- local BrokenTypeDef = require("BrokenTypeDef")
-- local PlayerSelfHelper = require("GamePlayerSelfHelper")

DialogBoardComponent.EventHelper = nil
DialogBoardComponent.tbDialogBoardDataTable = nil
DialogBoardComponent.nDialogBoardId = 0

function DialogBoardComponent:SetDialogBoardId(nDialogBoardId)
    self.nDialogBoardId = nDialogBoardId
end

function DialogBoardComponent:GetDialogBoardId()
    return self.nDialogBoardId
end


--被击事件
local function OnHitByCannon( self, nDamage, nResult, pAttackShip, bTeammate )
    --被击中核心区
    if nResult == IntervalTimeDef.HIT_RESULT_CORE then
        NpcDialogBoardSystem:TryOpenWithTemplate(self.Owner, IntervalTimeDef.LAST_HIT_CORE_INDEX)
    else
        NpcDialogBoardSystem:TryOpenWithTemplate(self.Owner, IntervalTimeDef.LAST_HIT_SELF_INDEX)
    end 
end 

--被鱼雷击中
local function OnHitByTorpedo( self, nDamage, nResult, pAttackerShip, bTeammate )
    NpcDialogBoardSystem:TryOpenWithTemplate(self.Owner, IntervalTimeDef.LAST_HIT_TORPEDO_SELF_INDEX)
end

-- 命中其他船只
local function OnHitAccomplished(self, nHitterType, nHitResult, bWithFire, bWithLeak, bIsFatal, bTeammate, pTakerShip )
    if bTeammate then  -- 忽略队友
        return
    end

    if bIsFatal then
        NpcDialogBoardSystem:TryOpenWithTemplate(self.Owner, IntervalTimeDef.LAST_KILL_ENEMY_INDEX)
        return
    end

    if bWithFire then
        NpcDialogBoardSystem:TryOpenWithTemplate(self.Owner, IntervalTimeDef.LAST_BURN_ENEMY_INDEX)
        return
    end

    -- if bWithLeak then
    -- end

    NpcDialogBoardSystem:TryOpenWithTemplate(self.Owner, IntervalTimeDef.LAST_HIT_ENEMY_INDEX)
end 

-- 部件损坏（燃烧、漏水）
-- local function OnBrokenStatusChanged( self, nBrokenType, pBrokenComponent, bStatus )
--     if bStatus == false then
--         return
--     end

--     if nBrokenType == BrokenTypeDef.TYPE_FIRE_SPOT then
--         NpcDialogBoardSystem:TryOpenWithTemplate(self.Owner, IntervalTimeDef.LAST_BURN_SELF_INDEX)
--         return
--     end

--     if nBrokenType == BrokenTypeDef.TYPE_LEAK_SPOT then
--         NpcDialogBoardSystem:TryOpenWithTemplate(self.Owner, IntervalTimeDef.LAST_WATER_LEAK_SELF_INDEX)
--     end
-- end

-- 被玩家发现时的状态发生改变
-- local function OnClientStealthStateChanged(self, pStealthState)
--     if pStealthState == Enum_StealthState.PlayerFound then
--         local SelfPlayer = PlayerSelfHelper:Get()
--         NpcDialogBoardSystem:TryOpenWithTemplate(SelfPlayer, IntervalTimeDef.LAST_DISCOVER_ENEMY_INDEX)
--     end
-- end

-- AI发现了敌人
local function OnAIAlertedWhenPatrolling(self)
    NpcDialogBoardSystem:TryOpenWithTemplate(self.Owner, IntervalTimeDef.LAST_DISCOVER_ENEMY_INDEX)
end


function DialogBoardComponent:OnCreate(Owner, tbParams)
    DialogBoardComponent.super.OnCreate(self, Owner, tbParams)
    local EventHelper = SelfEventHelperClass()
    self.EventHelper = EventHelper
    if self.Owner.ObjectType == GameObjectTypeDef.Npc then 
        if tbParams == nil then
            return
        end
        self.nDialogBoardId = tbParams.nDialogBoardId
        if self.nDialogBoardId == nil or self.nDialogBoardId == 0 then
            return
        end
        self.tbDialogBoardDataTable = NpcDialogBoardDataTable:GetTemplate(self.nDialogBoardId)
    elseif self.Owner.ObjectType == GameObjectTypeDef.PlayerSelf then
        local nDungeonId = BattleGameModeSystem.nDungeonId
        local tbDungeonDataTable = DungeonDataTable:GetTemplate(nDungeonId)
        local nDialogBoardId = tbDungeonDataTable.nNpcDialogBoardID
        self.tbDialogBoardDataTable = NpcDialogBoardDataTable:GetTemplate(nDialogBoardId)
        if self.tbDialogBoardDataTable == nil then
            return
        end
    end 

    local DelegateComponent = self.Owner.DelegateComponent
    -- 注册被击事件
    EventHelper:RegisterLuaDelegate(DelegateComponent.OnHitByCannon, OnHitByCannon, self)
    -- 注册被鱼雷击中事件
    EventHelper:RegisterLuaDelegate(DelegateComponent.OnHitByTorpedo, OnHitByTorpedo, self)
    -- 注册命中其他船只
    EventHelper:RegisterLuaDelegate(DelegateComponent.OnHitAccomplished, OnHitAccomplished, self)
    -- 被玩家发现的状态发生改变
    -- EventHelper:RegisterLuaDelegate(DelegateComponent.OnClientStealthStateChanged, OnClientStealthStateChanged, self)
    -- AI发现了敌人
    EventHelper:RegisterLuaDelegate(DelegateComponent.OnAIAlertedWhenPatrolling, OnAIAlertedWhenPatrolling, self)
end

function DialogBoardComponent:OnActorCreated(pUEActor)
    DialogBoardComponent.super.OnActorCreated(self, pUEActor)
    --如果一出生就发现敌人
    
    -- if pUEActor.ShipStealthClientComponent and (pUEActor.ShipStealthClientComponent.StealthState == Enum_StealthState.PlayerFound) then
    --     NpcDialogBoardSystem:TryOpenWithTemplate(self.Owner, IntervalTimeDef.LAST_DISCOVER_ENEMY_INDEX)
    -- end
    -- local ShipBrokenStatusComponent = self.Owner.ShipBrokenStatusComponent
    -- 注册自身部件受损
    -- local EventHelper = self.EventHelper
    -- EventHelper:RegisterLuaDelegate(ShipBrokenStatusComponent.OnBrokenStatusChangedDelegate, OnBrokenStatusChanged, self)
end

function DialogBoardComponent:OnActorDestroyed(pUEActor)
    DialogBoardComponent.super.OnActorDestroyed(self, pUEActor)
    if self.EventHelper then
        self.EventHelper:UnregisterAll()
        self.EventHelper = nil
    end
end

return DialogBoardComponent