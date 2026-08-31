-- Npc血量

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleNpcHpTarget = luaclass("BattleNpcHpTarget", BattleTargetBaseClass)

local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")

BattleNpcHpTarget.szTag = nil
BattleNpcHpTarget.nPercentage = nil
BattleNpcHpTarget.nInstanceId = nil
BattleNpcHpTarget.bMoreThan = nil

function BattleNpcHpTarget:Init()
    BattleNpcHpTarget.super.Init(self)
    self.szName = "BattleNpcHpTarget"
end

local function OnReachPercentage(self)
    self:Complete()
end

function BattleNpcHpTarget:RegisterEvent()
    self.nInstanceId = nil
    local szTag = self.szTag
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.Npc)
    for Object, _ in pairs(tbObjects) do
        if(Object.szTag == szTag) then
            self.nInstanceId = Object:GetServerInstanceId()
            Object.BattleShipPropertyComponent:BindHPReachRatioEvent(self.nPercentage,
                not self.bMoreThan, OnReachPercentage, self)
            return
        end
    end

    BattleOperationHelper:PrintError(self, "Cannot find npc, tag: "..self.szTag)
end

function BattleNpcHpTarget:UnregisterEvent()
    if(self.nInstanceId ~= nil) then
        local Npc = GameObjectSystem:FindByInstanceId(self.nInstanceId)
        if(Npc and Npc.BattleShipPropertyComponent) then
            Npc.BattleShipPropertyComponent:UnBindHPReachRatioEvent(OnReachPercentage, self)
        end
        self.nInstanceId = nil
    end
end

function BattleNpcHpTarget:Parse(tbJsonData)
    self.szTag = tbJsonData.Tag
    self.nPercentage = tbJsonData.Percentage
    self.bMoreThan = tbJsonData.MoreThan
    return true
end

local function Check(self)
    local szTag = self.szTag
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.Npc)
    for Object, _ in pairs(tbObjects) do
        if(Object.szTag == szTag) then
            local nValue = Object.BattleShipPropertyComponent:GetHpPercent()
            return BattleOperationHelper:CallOperator(self.szOperator, nValue, self.nPercentage)
        end
    end

    BattleOperationHelper:PrintError(self, "Cannot find npc, tag : "..self.szTag)
    return false
end

function BattleNpcHpTarget:Start()
    BattleNpcHpTarget.super.Start(self)

    if(Check(self)) then
        self:Complete()
    end
end

return BattleNpcHpTarget