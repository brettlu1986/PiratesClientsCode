local luaclass = require("luaclass")
local SAIWeaponStrategyBase = require("SAIWeaponStrategyBase")
local SAIWeaponStrategyNoChange = luaclass("SAIWeaponStrategyNoChange", SAIWeaponStrategyBase)

local function LOG(...)
    log("CJ->SAIWeaponStrategyNoChange:", ...)
end

SAIWeaponStrategyNoChange.nSelectedSlot = 0

function SAIWeaponStrategyNoChange:AddWeapon(nWeaponSlot, tbWeaponItem)
    if self.nSelectedSlot <= 0 then
        LOG("select weapon ", nWeaponSlot, self.tbOwner:IsShip(), tbWeaponItem:GetTemplateId())
        self.nSelectedSlot = nWeaponSlot
        self:ChangeWeapon(nWeaponSlot)
    end
end

function SAIWeaponStrategyNoChange:OnStop()
    self.nSelectedSlot = 0
end

function SAIWeaponStrategyNoChange:RemoveWeapon(nWeaponSlot)
    if nWeaponSlot == self.nSelectedSlot then
        self.nSelectedSlot = 0
    end
end


return SAIWeaponStrategyNoChange