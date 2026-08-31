local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local DamageCalculateComponent = luaclass("DamageCalculateComponent", GameComponentBase)

local SDCHelper = require("SDCHelper")
local BPDamageType = require("BPDamageType")

local tbShipCalculateFunctionMap = {
    [BPDamageType.ShipBullet]       = require("SDC_ShipBullet"),                    -- 船的子弹伤害
    [BPDamageType.ShipEmbolon]      = require("SDC_ShipEmbolon"),                   -- 船的撞角伤害
    [BPDamageType.ShipIncendiary]   = require("SDC_ShipIncendiary"),                -- 船的臼炮燃烧弹
    [BPDamageType.ShipFlamer]       = require("SDC_ShipFlamer"),                    -- 船的喷火器伤害
    [BPDamageType.ShipThrownItem]   = require("SDC_ShipThrownItem"),                -- 船的投掷物
    -- [BPDamageType.HumanBullet]      = require("SDC_HumanBullet"),                   -- 人的子弹伤害
}

local tbHumanCalculateFunctionMap   = {
    [BPDamageType.ShipBullet]       = require("HDC_ShipBullet"),                    -- 船的子弹伤害
    [BPDamageType.ShipEmbolon]      = require("HDC_ShipEmbolon"),                   -- 船的撞角伤害
    [BPDamageType.ShipIncendiary]   = require("HDC_ShipIncendiary"),                -- 船的臼炮燃烧弹
    [BPDamageType.ShipFlamer]       = require("HDC_ShipFlamer"),                    -- 船的喷火器伤害
    [BPDamageType.ShipThrownItem]   = require("HDC_ShipThrownItem"),                -- 船的投掷物
    [BPDamageType.HumanGrenade]     = require("HDC_HumanGrenade"),                  -- 人的手雷伤害
    [BPDamageType.HumanThrowWeapon] = require("HDC_HumanThrowWeapon"),              -- 飞刀飞斧
}

local function SwitchCalculatorMap(self)
    if self.Owner:IsShip() then
        self.tbCalculatorMap = tbShipCalculateFunctionMap
    else
        self.tbCalculatorMap = tbHumanCalculateFunctionMap
    end
end

local function OnTakeDamage(self, _, nActualDamage, pDamageType, _, pDamageCauser, pHitResult)
    local nDamageType = enumtoint(pDamageType.LuaEnum)
    SDCHelper.LOG("OnTakeDamage nActualDamage:%f, nDamageType:%d", nActualDamage, nDamageType)
    local fnCalculate = self.tbCalculatorMap[nDamageType]
    if fnCalculate then
        fnCalculate(self.Owner, nActualDamage, pDamageCauser, pHitResult)
    end
end

-- 人船切换后需要重新绑定
function DamageCalculateComponent:OnActorCreated(...)
    DamageCalculateComponent.super.OnActorCreated(self, ...)
    SwitchCalculatorMap(self)
    local Owner = self.Owner
    Owner.DelegateComponent.OnTakeCommonDamageEx:Bind(OnTakeDamage, self)
    Owner.DelegateComponent.OnTakePointDamageEx:Bind(OnTakeDamage, self)
    Owner.DelegateComponent.OnTakeRadialDamageEx:Bind(OnTakeDamage, self)
end

function DamageCalculateComponent:OnActorDestroyed(...)
    local Owner = self.Owner
    Owner.DelegateComponent.OnTakeRadialDamageEx:Unbind(OnTakeDamage, self)
    Owner.DelegateComponent.OnTakePointDamageEx:Unbind(OnTakeDamage, self)
    Owner.DelegateComponent.OnTakeCommonDamageEx:Unbind(OnTakeDamage, self)
    DamageCalculateComponent.super.OnActorCreated(self, ...)
end

return DamageCalculateComponent