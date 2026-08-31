local luaclass = require("luaclass")
local AIEntitySystem = luaclass("AIEntitySystem")
local SelfEventHelperClass      = require("SelfEventHelper")
local CommonEventDef            = require("CommonEventDef")
local SAIEntityComponent        = require("SAIEntityComponent")
local GameObjectSystem          = dynamic_require("GameObjectSystem")
local GlobalVariableSystem      = dynamic_require("GlobalVariableSystem")

AIEntitySystem.tbEntitys = nil
AIEntitySystem.SelfEventHelper = nil

local function LOG(...)
    log("CJ->AIEntitySystem:", ...)
end


local function OnHumanWeaponChanged(self, nNewWeapon, nLastWeapon, nOwnerCharacterInstanceId)
    local AIEntity = self:GetAIEntityByInstanceId(nOwnerCharacterInstanceId)
    if AIEntity then
        AIEntity:OnHumanWeaponChanged(nNewWeapon, nLastWeapon)
    end
end

local function OnShipWeaponChanged(self, OwnerCharacter, tbWeaponItem)
    local AIEntity = self:GetAIEntity(OwnerCharacter)
    if AIEntity then
        AIEntity:OnShipWeaponChanged(tbWeaponItem)
    end
end

local function OnHumanWeaponEquipped(self, nOwnerCharacterInstanceId, tbWeaponItem)
    local AIEntity = self:GetAIEntityByInstanceId(nOwnerCharacterInstanceId)
    if AIEntity then
        AIEntity:OnHumanWeaponEquipped(tbWeaponItem)
    end
end

local function OnHumanWeaponUnEquipped(self, nOwnerCharacterInstanceId, tbWeaponItem)
    local AIEntity = self:GetAIEntityByInstanceId(nOwnerCharacterInstanceId)
    if AIEntity then
        AIEntity:OnHumanWeaponUnEquipped(tbWeaponItem)
    end
end

local function OnShipWeaponEquipped(self, OwnerCharacter, nWeaponSlot, tbWeaponItem)
    local AIEntity = self:GetAIEntity(OwnerCharacter)
    if AIEntity then
        AIEntity:OnShipWeaponEquipped(nWeaponSlot, tbWeaponItem)
    end
end

local function OnShipWeaponUnEquipped(self, OwnerCharacter, nWeaponSlot, tbWeaponItem)
    local AIEntity = self:GetAIEntity(OwnerCharacter)
    if AIEntity then
        AIEntity:OnShipWeaponUnEquipped(nWeaponSlot, tbWeaponItem)
    end
end

local function OnHumanArmorAdd(self, nOwnerCharacterInstanceId, nItemId)
    local AIEntity = self:GetAIEntityByInstanceId(nOwnerCharacterInstanceId)
    if AIEntity then
        AIEntity:OnHumanArmorAdd(nItemId)
    end
end

local function OnHumanArmorRemove(self, nOwnerCharacterInstanceId, nItemId)
    local AIEntity = self:GetAIEntityByInstanceId(nOwnerCharacterInstanceId)
    if AIEntity then
        AIEntity:OnHumanArmorRemove(nItemId)
    end
end

local function OnShipArmorAdd(self, tbOwnerCharacter, nItemId)
    local AIEntity = self:GetAIEntity(tbOwnerCharacter)
    if AIEntity then
        AIEntity:OnShipArmorAdd(nItemId)
    end
end

local function OnShipArmorRemove(self, tbOwnerCharacter, nItemId)
    local AIEntity = self:GetAIEntity(tbOwnerCharacter)
    if AIEntity then
        AIEntity:OnShipArmorRemove(nItemId)
    end
end

local function OnActorCreated(self, tbGameObject)
    local AIEntity = self:GetAIEntity(tbGameObject)
    if AIEntity then
        AIEntity:OnActorCreated()
    end
end

local function OnHumanFired(self, nOwnerCharacterInstanceId)
    local AIEntity = self:GetAIEntityByInstanceId(nOwnerCharacterInstanceId)
    if AIEntity then
        AIEntity:OnFired()
    end
end

function AIEntitySystem:Init()
    if GlobalVariableSystem:IsServerLogic() then
        local SelfEventHelper = SelfEventHelperClass()
        self.SelfEventHelper = SelfEventHelper
        self.tbEntitys = {}

        SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE,      self, OnActorCreated)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED,       self, OnHumanWeaponChanged)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_ON_EQUIPED_SERVER,     self, OnHumanWeaponEquipped)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_ON_UNEQUIPED_SERVER,   self, OnHumanWeaponUnEquipped)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_ARMOR_ON_EQUIPED_SERVER,      self, OnHumanArmorAdd)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_ARMOR_ON_UNEQUIPED_SERVER,    self, OnHumanArmorRemove)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_ACTIVE_WEAPON_ITEM_CHANGED, self, OnShipWeaponChanged)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_WEAPON_EQUIPPED_SERVER ,    self, OnShipWeaponEquipped)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_WEAPON_UNEQUIPPED_SERVER,   self, OnShipWeaponUnEquipped)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_SHIP_ARMOR_ON_EQUIPED_SERVER,       self, OnShipArmorAdd)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_SHIP_ARMOR_ON_UNEQUIPED_SERVER,     self, OnShipArmorRemove)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_ATTACK_IN_SERVER,      self, OnHumanFired)
    end
    return true
end

function AIEntitySystem:Uninit()
    if self.SelfEventHelper then
        self.SelfEventHelper:UnregisterAll()
        self.SelfEventHelper = nil
    end
    self.tbEntitys = nil
end

function AIEntitySystem:GetAIEntity(tbGameObject)
    return self.tbEntitys[tbGameObject]
end

function AIEntitySystem:GetAIEntityByInstanceId(nInstanceId)
    local tbGameObject = GameObjectSystem:FindByInstanceId(nInstanceId)
    return self.tbEntitys[tbGameObject]
end

function AIEntitySystem:Register(tbGameObject)
    local Component = SAIEntityComponent()
    Component:Init(tbGameObject)
    self.tbEntitys[tbGameObject] = Component
    tbGameObject.SAIEntityComponent = Component
    LOG("register ai entity:", tbGameObject.szName)

end

function AIEntitySystem:Unregister(tbGameObject)
    local Component = self:GetAIEntity(tbGameObject)
    Component:Uninit()
    tbGameObject.SAIEntityComponent = nil
    self.tbEntitys[tbGameObject] = nil
    LOG("unregister ai entity:", tbGameObject.szName)
end

return AIEntitySystem()