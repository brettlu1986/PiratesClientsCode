local luaclass = require("luaclass")
local SyncDataBase = require("SyncDataBase")
local SyncDataThrownWeaponState = luaclass("SyncDataThrownWeaponState", SyncDataBase)
local HumanWeaponMisc = require("HumanWeaponMisc")
local HumanWeaponType = HumanWeaponMisc.Type
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

SyncDataThrownWeaponState.tbThrownWeaponState = nil



local function FillHumanThrownWeaponState(self)
    local tbOwner = self.tbOwner
    local WeaponComponent = tbOwner.HumanWeaponComponent
    local tbCurrentWeapon = WeaponComponent:GetCurrentWeapon()
    local thrown_weapon_state = self.tbThrownWeaponState
    if tbCurrentWeapon and tbCurrentWeapon:IsType(HumanWeaponType.THROW) then
        thrown_weapon_state.item_id = tbCurrentWeapon:GetInstanceId()
        -- 内存持续增加
        -- local tbProperty = tbCurrentWeapon:GetProperty()
        -- thrown_weapon_state.cd_time = tbProperty.nCD
        -- thrown_weapon_state.explode_time = tbProperty.nPreExplodeTime

        local nTemplateId = tbCurrentWeapon:GetTemplateId()
        local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
        thrown_weapon_state.cd_time = tbTemplate.nCD
        thrown_weapon_state.explode_time = tbTemplate.nPreExplodeTime

    end
end

local function FillShipThrownWeaponState(self)
    local thrown_weapon_state = self.tbThrownWeaponState
    local tbOwner = self.tbOwner
    local ActiveWeapon = BattleShipWeaponSystem:GetActiveWeaponItem(tbOwner)
    if (not ActiveWeapon) or (ActiveWeapon:GetCategory() ~= BattleItemCategoryDef.SHIP_THROWN_ITEM) then
        return
    end

    local tbTemplate = ActiveWeapon:GetTemplate()
    thrown_weapon_state.item_id = tbTemplate.nId
    thrown_weapon_state.cd_time = tbTemplate.nFiringInterval
    thrown_weapon_state.explode_time = 0
end

local function FillThrownWeaponState(self)
    local tbOwner = self.tbOwner
    local thrown_weapon_state = self.tbThrownWeaponState
    thrown_weapon_state.item_id = 0;
    thrown_weapon_state.cd_time = 0;
    thrown_weapon_state.explode_time = 0;
    if tbOwner:IsShip() then
        FillShipThrownWeaponState(self)
    else
        FillHumanThrownWeaponState(self)
    end
end

function SyncDataThrownWeaponState:OnSync(tbPack)
    FillThrownWeaponState(self)
    tbPack.thrown_weapon_state = self.tbThrownWeaponState
end


function SyncDataThrownWeaponState:OnStart()
    self.tbThrownWeaponState = {
        item_id = 0;
        cd_time = 0;
        explode_time = 0;
    }
end


function SyncDataThrownWeaponState:OnStop()

end

return SyncDataThrownWeaponState