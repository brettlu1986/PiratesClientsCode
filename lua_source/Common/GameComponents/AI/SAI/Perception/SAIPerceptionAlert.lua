local luaclass = require("luaclass")
local SAIPerceptionBase = require("SAIPerceptionBase")
local SAIPerceptionAlert = luaclass("SAIPerceptionAlert", SAIPerceptionBase)
local Timer                     = require("Timer")
local GameObjectSystem          = dynamic_require("GameObjectSystem")
local GameObjectTypeDef         = require("GameObjectTypeDef")

SAIPerceptionAlert.nAlertTimer = nil
SAIPerceptionAlert.nChangeSpeed = 0
SAIPerceptionAlert.nLevel = 0
SAIPerceptionAlert.nBaseLevel = 10
SAIPerceptionAlert.tbEnemys = nil

local nMaxAlertLevel = 100

local function LOG(...)
    log("CJ->SAIPerceptionAlert:", ...)
end


function SAIPerceptionAlert:OnStarted()
    LOG("start")
    local tbConfig = self.tbConfig
    self.nChangeSpeed = tbConfig.AlertChangeSpeed or 1
    self.nBaseLevel = tbConfig.BaseAlertLevel or 10
    self.tbEnemys = {}
    LOG("set risk alert params:",self.nChangeSpeed, self.nBaseLevel)
end

function SAIPerceptionAlert:BindEvent(SelfEventHelper)
    SAIPerceptionAlert.super.BindEvent(self, SelfEventHelper)
    local pAIController = self.pAIController
    SelfEventHelper:RegisterCppDelegate(pAIController.NotifyActorInSight, self, self.EnemyEnter)
    SelfEventHelper:RegisterCppDelegate(pAIController.NotifyActorLoseSight, self, self.EnemyLeave)
end

function SAIPerceptionAlert:Reset()
    self:SetAlertLevel(0)
    self.tbEnemys = {}
    self:EndAlertLevelTick()
    self:FireEvent("OnAlertLevelReset")
end

function SAIPerceptionAlert:SetRange(nDistance, nFov)
    local pAIController = self.pAIController
    pAIController:ConfigSight(nDistance, nDistance * 1.1, nFov)
    LOG("config sight:", nDistance, nFov)
end

function SAIPerceptionAlert:SetChangeSpeed(nSpeed)
    self.nChangeSpeed = nSpeed
end

local function IsEnemy(self, tbGameObject)
    return tbGameObject and tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf and
    not tbGameObject:IsDead() and self.tbOwner:IsShip() == tbGameObject:IsShip()
end

function SAIPerceptionAlert:EnemyEnter(nUniqueId)
    local tbEnemyObject = GameObjectSystem:FindByUniqueId(nUniqueId)
    if tbEnemyObject and IsEnemy(self, tbEnemyObject) then
        for _,v in ipairs(self.tbEnemys) do
            if v == tbEnemyObject then
                return
            end
        end
        table.insert( self.tbEnemys, tbEnemyObject)
        if not self.nAlertTimer then
            self:StartAlertLevelTick()
            self:SetAlertLevel(self.nBaseLevel)
        end
        LOG("enemy enter ", tbEnemyObject.szName)
        self:FireEvent("OnAlertFound", tbEnemyObject)
    end
end

function SAIPerceptionAlert:EnemyLeave(nUniqueId)
    local tbEnemyObject = GameObjectSystem:FindByUniqueId(nUniqueId)
    for i,v in ipairs(self.tbEnemys) do
        if v == tbEnemyObject then
            table.remove(self.tbEnemys, i)
            LOG("enemy leave ", tbEnemyObject.szName)
            self:FireEvent("OnAlertLost", tbEnemyObject)
            return
        end
    end
end

function SAIPerceptionAlert:FindAlertTarget()
    if #self.tbEnemys > 0 then
        return self.tbEnemys[1]
    end
end

function SAIPerceptionAlert:SetAlertLevel(nLevel)
    if (self.nLevel ~= nLevel) then
        self.nLevel  = nLevel
        --LOG("alert level->", nLevel)
        self:FireEvent("OnAlertLevelChanged", self.nLevel)
    end
end

function SAIPerceptionAlert:UpdateAlert()
    local nAliveEnemy = 0
    for _,v in ipairs(self.tbEnemys) do
        if not v:IsDead() then
            nAliveEnemy = nAliveEnemy + 1
        end
    end
    local nNewAlertLevel = self.nLevel
    if nAliveEnemy > 0 then
        nNewAlertLevel = nNewAlertLevel + self.nChangeSpeed
    else
        nNewAlertLevel = nNewAlertLevel - self.nChangeSpeed
    end
    if nNewAlertLevel >= nMaxAlertLevel then
        self:SetAlertLevel(nMaxAlertLevel)
        self:FireEvent("OnAlertMax")
        LOG("alert full")
    elseif nNewAlertLevel <= 0 then
        self:Reset()
    else
        self:SetAlertLevel(nNewAlertLevel)
    end
end

function SAIPerceptionAlert:StartAlertLevelTick()
    if not self.nAlertTimer then
        self.nAlertTimer = Timer.NewTimerMethod(self, self.UpdateAlert, 1, true)
        LOG("start tick")
    end
end

function SAIPerceptionAlert:GetEnemys()
    return self.tbEnemys or {}
end

function SAIPerceptionAlert:EndAlertLevelTick()
    if self.nAlertTimer then
        self.nAlertTimer:Clear()
        self.nAlertTimer = nil
        LOG("end tick")
    end
end

function SAIPerceptionAlert:OnStop()
    self.tbEnemys = {}
    self:EndAlertLevelTick()
    LOG("stop")
end


function SAIPerceptionAlert:UnbindEvent(SelfEventHelper)
    SAIPerceptionAlert.super.UnbindEvent(self, SelfEventHelper)
    SelfEventHelper:UnregisterAll()
end


return SAIPerceptionAlert