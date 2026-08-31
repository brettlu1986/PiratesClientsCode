-- 玩家血量

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattlePlayerHpTarget = luaclass("BattlePlayerHpTarget", BattleTargetBaseClass)

local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

BattlePlayerHpTarget.nPercentage = nil
BattlePlayerHpTarget.nInstanceId = nil
BattlePlayerHpTarget.bMoreThan = nil

function BattlePlayerHpTarget:Init()
    BattlePlayerHpTarget.super.Init(self)
    self.szName = "BattlePlayerHpTarget"
end

local function OnReachPercentage(self)
    self:Complete()
end


function BattlePlayerHpTarget:PlayerHPMonitor()
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for Object, _ in pairs(tbObjects) do
        if Object.ObjectType == GameObjectTypeDef.PlayerSelf then
            self.nInstanceId = Object:GetServerInstanceId()
            Object.BattleShipPropertyComponent:BindHPReachRatioEvent(self.nPercentage,
                not self.bMoreThan, OnReachPercentage, self)
            return
        end
    end
    return
end

function BattlePlayerHpTarget:RegisterEvent()
    self.nInstanceId = nil
    self:PlayerHPMonitor()

    -- 找不到玩家 等玩家进入事件再次处理
    if self.nInstanceId == nil then
        EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, self.PlayerHPMonitor)
    end
end

function BattlePlayerHpTarget:UnregisterEvent()
    if(self.nInstanceId ~= nil) then
        local Player = GameObjectSystem:FindByInstanceId(self.nInstanceId)
        if( Player and Player.BattleShipPropertyComponent ~= nil ) then
            Player.BattleShipPropertyComponent:UnBindHPReachRatioEvent(OnReachPercentage, self)
        end
        self.nInstanceId = nil
    end

    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, self.PlayerHPMonitor)

end

function BattlePlayerHpTarget:Parse(tbJsonData)
    self.nPercentage = tbJsonData.Percentage
    self.bMoreThan = tbJsonData.MoreThan
    return true
end

local function Check(self)
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for Object, _ in pairs(tbObjects) do
        if Object.ObjectType == GameObjectTypeDef.PlayerSelf then
            local nValue = Object.BattleShipPropertyComponent:GetHpPercent()
            return BattleOperationHelper:CallOperator(self.szOperator, nValue, self.nPercentage)
        end
    end
    -- 找不到玩家
    return false
end

function BattlePlayerHpTarget:Start()
    BattlePlayerHpTarget.super.Start(self)

    if(Check(self)) then
        self:Complete()
    end
end

return BattlePlayerHpTarget