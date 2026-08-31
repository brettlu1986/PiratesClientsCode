
local luaclass = require("luaclass")
local SAIWeaponBase = luaclass("SAIWeaponBase")
local SelfEventHelperClass   = require("SelfEventHelper")
local SelfTimerHelperClass   = require("SelfTimerHelper")
local SAIWeaponStrategyFactory = require("SAIWeaponStrategyFactory")
local SAIMisc = require("SAIMisc")
local SAIWeaponStrategyDef = require("SAIWeaponStrategyDef")

SAIWeaponBase.Owner = nil
SAIWeaponBase.pBlackboard    = nil
SAIWeaponBase.pAIController  = nil
SAIWeaponBase.TimerHelper    = nil
SAIWeaponBase.pAIWeaponComponent = nil
SAIWeaponBase.tbConfig = nil
SAIWeaponBase.tbSelfEventHelper = nil
SAIWeaponBase.szAnimPart = ""
SAIWeaponBase.nHitProb = 0
SAIWeaponBase.bCanAttack = false
SAIWeaponBase.tbStrategy = nil
SAIWeaponBase.tbSwitchWeaponCDTimer = nil
SAIWeaponBase.nSwitchWeaponCD = 0

local function LOG(...)
    log("CJ->SAIWeaponBase:", ...)
end

function SAIWeaponBase:Config(tbConfig)
    self.tbConfig = tbConfig
    self:OnConfiged()
end

function SAIWeaponBase:OnConfiged()

end

function SAIWeaponBase:OnStart()

end

function SAIWeaponBase:OnStop()

end

local function ClearSwitchWeaponCDTimer(self)
    if self.tbSwitchWeaponCDTimer then
        self.tbSwitchWeaponCDTimer:Clear()
        self.tbSwitchWeaponCDTimer = nil
        self.pAIWeaponComponent.bSwitchWeapon = false
    end
end

local function OnSwitchWeapon(self)
    assert(self.Owner and self.Owner.pUEActor)
    local pAIWeaponComponent = self.pAIWeaponComponent
    local nSwitchWeaponCD = self.nSwitchWeaponCD
    ClearSwitchWeaponCDTimer(self)
    if nSwitchWeaponCD > 0 then
        pAIWeaponComponent.bSwitchWeapon = true
        self.tbSwitchWeaponCDTimer = self.TimerHelper:NewTimer(function ()
            pAIWeaponComponent.bSwitchWeapon = false
            self.tbSwitchWeaponCDTimer = nil
            --LOG("clear switch weapon CD")
        end, nSwitchWeaponCD, false)
    end
end

function SAIWeaponBase:ChangeWeapon(nSlot)
    OnSwitchWeapon(self)
end

function SAIWeaponBase:ActiveStrategy(nID)
    LOG("active weapon strategy ", nID)
    local tbStrategy = self.tbStrategy
    if (tbStrategy) then
        tbStrategy:Stop()
        tbStrategy:Uninit()
    end
    tbStrategy = SAIWeaponStrategyFactory:CreateWeaponStrategy(nID)
    if (tbStrategy) then
        tbStrategy:Init(self.Owner)
        tbStrategy:Start(self)
    end
    self.tbStrategy = tbStrategy
end

function SAIWeaponBase:Start(tbOwner, pAIController)
    self.pAIController = pAIController
    self.pBlackboard = pAIController.Blackboard
    self.pAIWeaponComponent = pAIController.AIWeaponsComponent
    self.Owner = tbOwner
    self.TimerHelper = SelfTimerHelperClass()
    self.tbSelfEventHelper = SelfEventHelperClass()
    self:RegisterEvent(self.tbSelfEventHelper)
    assert(self.pAIWeaponComponent, "aicontroller must have aiweaponcomponent")
    self:ActiveStrategy(self.tbConfig.Strategy or SAIWeaponStrategyDef.NoChange)
    self:OnStart()
end

function SAIWeaponBase:Stop()
    LOG("stop")
    ClearSwitchWeaponCDTimer(self)
    self:OnStop()
    self:ActiveStrategy(0)
    self.tbSelfEventHelper:UnregisterAll()
    self.Owner = nil
    self.pBlackboard = nil
    self.TimerHelper:ClearAllTimer()
    self.TimerHelper = nil
    self.tbSelfEventHelper = nil
end


function SAIWeaponBase:RegisterEvent(SelfEventHelper)
    local pAIWeaponComponent = self.pAIWeaponComponent
    SelfEventHelper:RegisterCppDelegate(pAIWeaponComponent.OnStartFire, self, self.OnStartFire)
    SelfEventHelper:RegisterCppDelegate(pAIWeaponComponent.OnEndFire, self, self.OnEndFire)
    SelfEventHelper:RegisterCppDelegate(pAIWeaponComponent.OnPreFire, self, self.OnPreFire)
end


function SAIWeaponBase:OnStartFire(X, Y, Z)

end

function SAIWeaponBase:OnEndFire()

end

function SAIWeaponBase:OnPreFire()

end

-- 激活武器
function SAIWeaponBase:PickOutWeapon()

end

-- 收起武器
function SAIWeaponBase:DropInWeapon()

end

function SAIWeaponBase:CanUseWeapon(nTemplateId)
    return SAIMisc:CanUseWeapon(self.Owner, nTemplateId)
end

function SAIWeaponBase:GetWeaponConfig(nTemplateId)
    return SAIMisc:GetWeaponConfig(self.Owner, nTemplateId)
end

function SAIWeaponBase:SetWeaponHitProb(nProb)
    self.nHitProb = math.floor(nProb * 100)
    self.pAIWeaponComponent.FireHitProbability = self.nHitProb
    LOG("set hit prob:", self.nHitProb)
end

function SAIWeaponBase:SetAimPart(szPart)
    self.szAnimPart = szPart
    self.pAIWeaponComponent.AimPart = szPart
    LOG("set aim part:", self.szAnimPart)
end

function SAIWeaponBase:SetAimTarget(pTarget)
    self.pAIWeaponComponent.AimTarget = pTarget
end

function SAIWeaponBase:CanAttack()
    return self.bCanAttack
end

return SAIWeaponBase