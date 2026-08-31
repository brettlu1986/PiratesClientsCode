local luaclass = require("luaclass")
local SAIPerceptionBase = require("SAIPerceptionBase")
local SAIPerceptionEnmity = luaclass("SAIPerceptionEnmity", SAIPerceptionBase)
local Timer = require("Timer")
local CommonEventDef = require("CommonEventDef")
local DamageTypeEx   = require("DamageTypeEx")
local GameObjectSystem = dynamic_require("GameObjectSystem")

SAIPerceptionEnmity.tbEnmity = nil
SAIPerceptionEnmity.nAgeTimer = nil
SAIPerceptionEnmity.nExpirationTime = nil
SAIPerceptionEnmity.nEnmityScale = 2


-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAIPerceptionEnmity:", ...)
end
-- luacheck: pop


local function OnTookDamage(self, Owner, tbCauser, nDamage, nDamageType)
    if not tbCauser then
        return
    end
    nDamage = math.max( 1, nDamage)
    if --[[nDamage > 0 and]] (GameObjectSystem:IsCharacter(Owner)) and (DamageTypeEx.IsCausedByShip(nDamageType) or DamageTypeEx.IsCausedByHuman(nDamageType)
    and (Owner:IsShip() == tbCauser:IsShip())) then
         -- npc ai is hit by player and not self
        if Owner == self.tbOwner and tbCauser ~= self.tbOwner then
            LOG("took damage")
            local nEnmity = math.floor(nDamage * (1 + self.nEnmityScale))
            if nEnmity > 0 then
                self:AddEnmity(tbCauser, nEnmity)
            end
        -- npc ai hited player
        elseif tbCauser == self.tbOwner then
            LOG("cause damage")
            for i,v in ipairs(self.tbEnmity) do
                if v.nInstanceId == Owner.nServerInstanceId then
                    v.nAge = 0
                    LOG("refresh enmity")
                    break
                end
            end
        end
    end

end

local function OnPlayerDead(self, tbGameObject)
    local nInstanceId = tbGameObject.nServerInstanceId
    for i,v in ipairs(self.tbEnmity) do
        if v.nInstanceId == nInstanceId then
            table.remove( self.tbEnmity, i )
            LOG("player dead " .. tbGameObject.szName)
            break
        end
    end
    if #self.tbEnmity <= 0 then
        self:EndAgeTick()
    end
end

function SAIPerceptionEnmity:ClearEnmity()
    self:EndAgeTick()
    self.tbEnmity = {}
    self:FireEvent("OnEnmityClear")
end

function SAIPerceptionEnmity:IsObjectHasEnmity(tbGameObject)
    local nInstanceId = tbGameObject.nServerInstanceId
    for i,v in ipairs(self.tbEnmity) do
        if v.nInstanceId == nInstanceId then
            return true
        end
    end
    return false
end

function SAIPerceptionEnmity:SetExpirationTime(nTime)
    self.nExpirationTime = nTime
end

function SAIPerceptionEnmity:OnStarted()
    LOG("start")
    local tbConfig = self.tbConfig
    self.tbEnmity = {}
    self.nExpirationTime = tbConfig.ExpirationTime
    self.nEnmityScale    = tbConfig.EnmityScale
    LOG("set enmity params:", self.nExpirationTime, self.nEnmityScale)
end


function SAIPerceptionEnmity:BindEvent(SelfEventHelper)
    SAIPerceptionEnmity.super.BindEvent(self, SelfEventHelper)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_ON_TAKE_DAMAGE, self, OnTookDamage)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnPlayerDead)
end


function SAIPerceptionEnmity:SetKeepMinEnmity(tbGameObject , nEnmity)
    local nInstanceId = tbGameObject.nServerInstanceId
    for i,v in ipairs(self.tbEnmity) do
        if v.nInstanceId == nInstanceId then
            v.nMinEnmity = nEnmity
            break
        end
    end
end

function SAIPerceptionEnmity:AddEnmity(tbGameObject , nEnmity)
    if not self.bStarted then
        return
    end
    LOG("add " .. tbGameObject.szName .. " enmity " .. nEnmity )
    local nInstanceId = tbGameObject.nServerInstanceId
    local bExsit = false
    for i,v in ipairs(self.tbEnmity) do
        if v.nInstanceId == nInstanceId then
            v.nAge = 0
            v.nEnmity = v.nEnmity + nEnmity
            bExsit = true
            break
        end
    end
    if not bExsit then
        local tbEnmity = { nInstanceId = nInstanceId, nAge = 0, nEnmity = nEnmity  }
        table.insert( self.tbEnmity, tbEnmity)
        self:StartAgeTick()
    end
    self:FireEvent("OnEnmityAdd", tbGameObject)
end

function SAIPerceptionEnmity:UpdateEnmityAge()
    local tbNewEnmitys = { }
    local bRemoved = false
    for i,v in ipairs(self.tbEnmity) do
        v.nAge = v.nAge + 1
        if v.nAge > self.nExpirationTime then
            if v.nMinEnmity and v.nMinEnmity > 0 then
                v.nEnmity = v.nMinEnmity
                table.insert( tbNewEnmitys, v)
            else
                bRemoved = true
            end
        else
            table.insert( tbNewEnmitys, v)
        end
    end
    if bRemoved then
        self.tbEnmity = tbNewEnmitys
    end
    if #self.tbEnmity <= 0 then
        self:EndAgeTick()
    end
end

function SAIPerceptionEnmity:IterateEnemys(func)
    for i,v in ipairs(self.tbEnmity) do
        func(v.nInstanceId)
    end
end


function SAIPerceptionEnmity:GetHighestEnmityTarget()
    local nInstanceId = -1
    local nEnmity = -1
    for i,v in ipairs(self.tbEnmity) do
        if v.nEnmity > nEnmity then
            nEnmity = v.nEnmity
            nInstanceId = v.nInstanceId
        end
    end
    return nInstanceId
end

function SAIPerceptionEnmity:StartAgeTick()
    if not self.nAgeTimer then
        self.nAgeTimer = Timer.NewTimerMethod(self, self.UpdateEnmityAge, 1, true)
        LOG("start tick")
    end
end

function SAIPerceptionEnmity:EndAgeTick()
    if self.nAgeTimer then
        self.nAgeTimer:Clear()
        self.nAgeTimer = nil
        LOG("end tick")
    end
end

function SAIPerceptionEnmity:OnStop()
    self:ClearEnmity()
    LOG("stop")
end

function SAIPerceptionEnmity:UnbindEvent(SelfEventHelper)
    SAIPerceptionEnmity.super.UnbindEvent(self, SelfEventHelper)
    SelfEventHelper:UnregisterAll()
end

return SAIPerceptionEnmity