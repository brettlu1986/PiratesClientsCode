
local luaclass = require("luaclass")
local SAISystemBase = require("SAISystemBase")
local SAIWeaponSystem = luaclass("SAIWeaponSystem", SAISystemBase)

SAIWeaponSystem.pAIController = nil
SAIWeaponSystem.tbWeapon = nil
SAIWeaponSystem.tbConfig = nil

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAIWeaponSystem:", ...)
end
-- luacheck: pop


function SAIWeaponSystem:OnStart()
    if not self.tbWeapon then
        LOG("start")
        self.pAIController = self.tbOwner.SAIComponent:GetAIController()
        if (self.tbOwner:IsShip()) then
            self.tbWeapon = require("SAIWeaponShip")()
        elseif (self.tbOwner:IsHuman()) then
            self.tbWeapon = require("SAIWeaponHuman")()
        end
        if (self.tbWeapon) then
            self.tbWeapon:Config(self.tbConfig)
            self.tbWeapon:Start (self.tbOwner, self.pAIController)
        end
    end
end

function SAIWeaponSystem:ActiveStrategy(nID)
    if (self.tbWeapon) then
        self.tbWeapon:ActiveStrategy(nID)
    end
end

function SAIWeaponSystem:OnConfig(tbConfig)
    self.tbConfig  = tbConfig.Weapon
end

function SAIWeaponSystem:OnStop()
    if (self.tbWeapon) then
        self.tbWeapon:Stop()
        self.tbWeapon = nil
    end
    LOG("stop")
end

function SAIWeaponSystem:SetWeaponHitProb(nProb)
    if (self.tbWeapon) then
        self.tbWeapon:SetWeaponHitProb(nProb)
    end
end

function SAIWeaponSystem:SetAimPart(szPart)
    if (self.tbWeapon) then
        self.tbWeapon:SetAimPart(szPart)
    end
end

function SAIWeaponSystem:SetAimTarget(pTarget)
    if (self.tbWeapon) then
        self.tbWeapon:SetAimTarget(pTarget)
    end
end

function SAIWeaponSystem:CanAttack()
    return self.tbWeapon and self.tbWeapon:CanAttack()
end

-- 激活武器
function SAIWeaponSystem:PickOutWeapon()
    if (self.tbWeapon) then
        self.tbWeapon:PickOutWeapon()
    end
end

-- 收起武器
function SAIWeaponSystem:DropInWeapon()
    if (self.tbWeapon) then
        self.tbWeapon:DropInWeapon()
    end
end

function SAIWeaponSystem:ChangeWeapon(nWeaponSlot)
    if (self.tbWeapon) then
        self.tbWeapon:ChangeWeapon(nWeaponSlot)
    end
end

function SAIWeaponSystem:OnUninit()

end



return SAIWeaponSystem
