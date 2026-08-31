local luaclass = require("luaclass")
local SAIPerceptionBase = require("SAIPerceptionBase")
local SAIPerceptionDamage = luaclass("SAIPerceptionDamage", SAIPerceptionBase)
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local Timer = require("Timer")

SAIPerceptionDamage.tbDamageEvent = nil
SAIPerceptionDamage.nTimer = nil
SAIPerceptionDamage.nRememberTime = 10

local MAX_DAMAGE_EVENT = 5

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAIPerceptionDamage:", ...)
end
-- luacheck: pop

local function OnTookDamage(self, nUniqueId)
    local tbGameObject = GameObjectSystem:FindByUniqueId(nUniqueId)
    if tbGameObject and GameObjectTypeDef.PlayerSelf == tbGameObject:GetObjectType() then
        local nServerInstanceId = tbGameObject:GetServerInstanceId()
        for i,v in ipairs(self.tbDamageEvent) do
            if v.DamageMakerId == nServerInstanceId then
                v.Age = self.nRememberTime
                return
            end
        end
        if #self.tbDamageEvent >= MAX_DAMAGE_EVENT then
            table.remove(self.tbDamageEvent, 1)
        end
        table.insert(self.tbDamageEvent, { DamageMakerId = nServerInstanceId, Age = self.nRememberTime })
        self:StartTimer()
        self:FireEvent("OnTookDamage", nServerInstanceId)
        LOG("took damage ", tbGameObject.szName)
    end
end

function SAIPerceptionDamage:Tick()
    local tbDamageEvent = {}
    for i,v in ipairs(self.tbDamageEvent) do
        v.Age = v.Age - 1
        if v.Age > 0 then
            table.insert(tbDamageEvent, v)
        end
    end
    self.tbDamageEvent = tbDamageEvent
    if #tbDamageEvent <= 0 then
        LOG("forget all damages")
        self:StoptTimer()
    end
end

function SAIPerceptionDamage:StartTimer()
    if not self.nTimer then
        self.nTimer = Timer.NewTimerMethod(self, self.Tick, 1, true)
    end
end

function SAIPerceptionDamage:StoptTimer()
    if self.nTimer then
        self.nTimer:Clear()
        self.nTimer = nil
    end
end

function SAIPerceptionDamage:OnStarted()
    self.tbDamageEvent = {}
    local tbConfig = self.tbConfig
    if tbConfig.RememberTime then
        self.nRememberTime = tbConfig.RememberTime
    end
    LOG("config damage:", self.nRememberTime)
end

function SAIPerceptionDamage:OnStop()
    self:StoptTimer()
    self.tbDamageEvent = {}
end

function SAIPerceptionDamage:BindEvent(SelfEventHelper)
    SAIPerceptionDamage.super.BindEvent(self, SelfEventHelper)
    local pAIController = self.pAIController
    SelfEventHelper:RegisterCppDelegate(pAIController.NotifyTookDamage, self, OnTookDamage)
end

function SAIPerceptionDamage:GetDamageList()
    return self.tbDamageEvent
end


function SAIPerceptionDamage:UnbindEvent(SelfEventHelper)
    SAIPerceptionDamage.super.UnbindEvent(self, SelfEventHelper)
    SelfEventHelper:UnregisterAll()
end

return SAIPerceptionDamage