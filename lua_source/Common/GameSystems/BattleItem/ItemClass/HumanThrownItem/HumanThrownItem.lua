-----------------------------------------------------
--File Name    : HumanThrownItem.lua
--Author       : WuJizhou
--Create Time  : 9/17/2018, 12:43:35 PM
--Description  : 人的投掷类武器，如手雷，燃烧弹等
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleItemBase = require("BattleItemBase")
local HumanThrownItem = luaclass("HumanThrownItem", BattleItemBase)

local BattleItemSystemHelper = require("BattleItemSystemHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local HumanThrownItemPropertyHelper = require("HumanThrownItemPropertyHelper")


function HumanThrownItem:SetCurrentWeapon(bCurrentWeapon)
    -- call bp function to set current weapon
    local WeaponComponent = self:GetOwnerCharacter().HumanWeaponComponent
    if(WeaponComponent) then
        return WeaponComponent:SetCurrentWeapon(bCurrentWeapon and self:GetInstanceId() or 0)
    end
    return false
end

function HumanThrownItem:IsCurrentWeapon()
    -- call bp function to check
    local WeaponComponent = self:GetOwnerCharacter().HumanWeaponComponent
    if(WeaponComponent) then
        return WeaponComponent:GetCurrentWeaponInstanceId() == self:GetInstanceId()
    end
    return false
end



function HumanThrownItem:GetCurrentAmmoCount(bIsClient)
    return self:GetStackCount()
end

function HumanThrownItem:DecreaseAmmoCount(nCount)
    assert(GlobalVariableSystem:IsServerLogic())
    nCount = nCount == nil and 1 or nCount
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    local nItemInstanceId = self:GetInstanceId()
    local tbAmmo =  BattleItemSystemHelper:GetItem(nItemInstanceId, false)
    if tbAmmo ~= nil then
        BattleItemSystemServer:DecreaseItemCount(nItemInstanceId, nCount)
        local tbOwner = self:GetOwnerCharacter()
        if tbOwner and tbOwner.HumanWeaponComponent then
            tbOwner.HumanWeaponComponent:RemoveWeapon(self:GetInstanceId())
        end
    else
        logwarning("HumanThrownItem:DecreaseAmmoCount, ammo item is nil")
    end
end


function HumanThrownItem:OnReload()

end

-- 获取投掷物的使用优先级，主要用于当前投掷物用尽时，其他投掷物变成当前投掷物的顺序
function HumanThrownItem:GetPriorty()
    return self:GetTemplateId()
end

function HumanThrownItem:GetProperty(bIsClient)
    if self.tbProperty == nil then
        self.tbProperty = HumanThrownItemPropertyHelper.CreateProperty(self:GetTemplateId())
    end
    return self.tbProperty
end

-- 获取腰射准星资源
function HumanThrownItem:GetSightRes()
    return self:GetTemplate().szSightRes
end

return HumanThrownItem