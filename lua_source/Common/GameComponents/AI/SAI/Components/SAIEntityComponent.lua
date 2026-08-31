local luaclass = require("luaclass")
local SAIEntityComponent = luaclass("SAIEntityComponent")
local BattleTeamSystem  = require("BattleTeamSystem")
local BattleItemSystemServer        = require("BattleItemSystemServer")
local AIHelper                      = require("AIHelper")
local HumanWeaponSlotDef    = require("HumanWeaponSlotDef")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local ShipWeaponSlotDef     = require("ShipWeaponSlotDef")
local HumanArmorSlotDef  = require("HumanArmorSlotDef")
local ShipPartTypeDef    = require("ShipPartTypeDef")
local SelfTimerHelperClass  = require("SelfTimerHelper")
-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAIEntityComponent:", ...)
end
-- luacheck: pop

local fnGetActorLocation = AIExtendBlueprintFunctions.GetActorLocation_NT
local fnGetActorRotation = AIExtendBlueprintFunctions.GetActorRotation_NT
local fnGetActorVelocity = AIExtendBlueprintFunctions.GetActorVelocity_NT

SAIEntityComponent.Owner = nil
SAIEntityComponent.nTeamId = -1
SAIEntityComponent.nActiveWeaponTemplateId = 0
SAIEntityComponent.bInvisbleFromAI = false
SAIEntityComponent.tbHumanWeapons = nil
SAIEntityComponent.tbHumanArmors = nil
SAIEntityComponent.tbShipWeapons = nil
SAIEntityComponent.tbShipArmors = nil
SAIEntityComponent.nFired = 0
SAIEntityComponent.tbTimerHelper = nil

function SAIEntityComponent:OnHumanWeaponChanged(nNewWeapon, nLastWeapon)
    local tbWeaponItem = BattleItemSystemServer:GetItem(nNewWeapon)
    if tbWeaponItem then
        self.nActiveWeaponTemplateId = tbWeaponItem:GetTemplateId()
    else
        self.nActiveWeaponTemplateId = 0
    end
end

function SAIEntityComponent:OnShipWeaponChanged(tbWeaponItem)
    if tbWeaponItem then
        self.nActiveWeaponTemplateId = tbWeaponItem:GetTemplateId()
    else
        self.nActiveWeaponTemplateId = 0
    end
end

function SAIEntityComponent:OnHumanWeaponEquipped(tbWeaponItem)
    if tbWeaponItem then
        local nSlotIndex  = tbWeaponItem:GetStorageLocation().nSlotIndex
        self.tbHumanWeapons[nSlotIndex] = tbWeaponItem
        LOG("human weapon equipped at ", nSlotIndex)
    end
end

function SAIEntityComponent:OnHumanWeaponUnEquipped(tbWeaponItem)
    local nSlotIndex  = tbWeaponItem:GetStorageLocation().nSlotIndex
    self.tbHumanWeapons[nSlotIndex] = nil
    LOG("human weapon removed at ", nSlotIndex)
end

function SAIEntityComponent:OnShipWeaponEquipped(nWeaponSlot, tbWeaponItem)
    self.tbShipWeapons[nWeaponSlot] = tbWeaponItem
    LOG("ship weapon equipped at ", nWeaponSlot)
end

function SAIEntityComponent:OnShipWeaponUnEquipped(nWeaponSlot, tbWeaponItem)
    self.tbShipWeapons[nWeaponSlot] = nil
    LOG("ship weapon removed at ", nWeaponSlot)
end

function SAIEntityComponent:OnHumanArmorAdd(nItemId)
    local tbItem = BattleItemSystemServer:GetItem(nItemId)
    local _, _, nSlotIndex = tbItem:SplitAndGetStorageLocation()
    self.tbHumanArmors[nSlotIndex] = tbItem
    LOG("human armor equipped at ", nSlotIndex)

end

function SAIEntityComponent:OnHumanArmorRemove(nItemId)
    for k,v in pairs(self.tbHumanArmors) do
        if v and v:GetInstanceId() == nItemId then
            self.tbHumanArmors[k] = nil
            LOG("human armor removed at ", k)
            break
        end
    end
end

function SAIEntityComponent:OnShipArmorAdd(nItemId)
    local tbItem = BattleItemSystemServer:GetItem(nItemId)
    local _, _, nSlotIndex = tbItem:SplitAndGetStorageLocation()
    self.tbShipArmors[nSlotIndex] = tbItem
    LOG("ship armor equipped at ", nSlotIndex)
end

function SAIEntityComponent:OnShipArmorRemove(nItemId)
    for k,v in pairs(self.tbShipArmors) do
        if v and v:GetInstanceId() == nItemId then
            self.tbShipArmors[k] = nil
            LOG("ship armor removed at ", k)
            break
        end
    end
end

function SAIEntityComponent:OnFired()
    self.nFired = self.nFired + 1
end

local function InitWeapons(self)
    self.tbHumanWeapons = {}
    self.tbShipWeapons  = {}
    local tbGameObject = self.Owner
    local nCharacterInstanceId = tbGameObject:GetServerInstanceId()
    for i=1,HumanWeaponSlotDef:SlotCount() do
        local tbWeaponItem = BattleItemSystemServer:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_WEAPON,
        nCharacterInstanceId, i)
        if tbWeaponItem then
            self.tbHumanWeapons[i] = tbWeaponItem
        end
    end
    for i=ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
        local tbWeaponItem = BattleItemSystemServer:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.SHIP_WEAPON,
        nCharacterInstanceId, i)
        if tbWeaponItem then
            self.tbShipWeapons[i] = tbWeaponItem
        end
    end
end

local function InitArmors(self)
    self.tbHumanArmors  = {}
    self.tbShipArmors   = {}
    local tbGameObject = self.Owner
    local nCharacterInstanceId = tbGameObject:GetServerInstanceId()
    for i=1, HumanArmorSlotDef:SlotCount() do
        local tbArmorItem = BattleItemSystemServer:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_ARMOR,
        nCharacterInstanceId, i)
        if tbArmorItem then
            self.tbHumanArmors[i] = tbArmorItem
        end
    end
    for i=1, ShipPartTypeDef.Max do
        local tbArmorItem = BattleItemSystemServer:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.SHIP_PART,
        nCharacterInstanceId, i)
        if tbArmorItem then
            self.tbShipArmors[i] = tbArmorItem
        end
    end
end

function SAIEntityComponent:Init(tbGameObject)
    self.Owner = tbGameObject
    self.tbTimerHelper = SelfTimerHelperClass()
end

function SAIEntityComponent:OnActorCreated()
    local tbGameObject = self.Owner
    local pUEActor = tbGameObject.pUEActor
    self.nTeamId = BattleTeamSystem:FindTeamId(tbGameObject)
    if pUEActor.AISettingComponent then
        pUEActor.AISettingComponent.TeamId = self.nTeamId
    end
    InitArmors(self)
    InitWeapons(self)
    self.nFired = 0
end

function SAIEntityComponent:Uninit()
    self.Owner = nil
    self.tbTimerHelper:ClearAllTimer()
    self.tbTimerHelper = nil
end

function SAIEntityComponent:SetInvisibleFromAI(bInvisbleFromAI)
    self.bInvisbleFromAI = bInvisbleFromAI
end


----------------------------------------------------------------------------------------------------
function SAIEntityComponent:GetId()
    return self.Owner:GetServerInstanceId()
end

function SAIEntityComponent:GetLocation()
    return fnGetActorLocation(self.Owner.pUEActor)
end

function SAIEntityComponent:GetRotation()
    return fnGetActorRotation(self.Owner.pUEActor)
end

function SAIEntityComponent:GetSpeed()
    return fnGetActorVelocity(self.Owner.pUEActor)
end

function SAIEntityComponent:GetHp()
    return self.Owner:GetCurrentPropertyComponent():GetHp()
end

function SAIEntityComponent:GetHpPercent()
    return self.Owner:GetCurrentPropertyComponent():GetHpPercent()
end

function SAIEntityComponent:GetTeamId()
    return self.nTeamId
end

function SAIEntityComponent:GetIsShip()
    return self.Owner:IsShip()
end

function SAIEntityComponent:GetIsAlive()
    return self.Owner:IsAlive()
end

function SAIEntityComponent:GetIsDying()
    return self.Owner:IsDying()
end

function SAIEntityComponent:GetIsDead()
    return self.Owner:IsDead()
end

function SAIEntityComponent:GetActiveWeaponTemplateId()
    return self.nActiveWeaponTemplateId
end

function SAIEntityComponent:VisibleToAI()
    return not self.bInvisbleFromAI
end

function SAIEntityComponent:IsRealPlayer()
    return not AIHelper.IsAIControlled(self.Owner)
end

function SAIEntityComponent:GetShipPosture()
    local tbPlayer = self.Owner
    if not tbPlayer:IsShip() then
        return nil
    end
    local BattleShipMovementComponent = tbPlayer.BattleShipMovementComponent
    if not BattleShipMovementComponent then
        logerror("Cannot find BattleShipMovementComponent", tbPlayer:GetServerInstanceId())
        return nil
    end
    return BattleShipMovementComponent:GetPosture()
end


function SAIEntityComponent:GetHumanWeapon(nIndex)
    return self.tbHumanWeapons[nIndex]
end

function SAIEntityComponent:GetShipWeapon(nIndex)
    return self.tbShipWeapons[nIndex]
end

function SAIEntityComponent:GetHumanArmor(nIndex)
    return self.tbHumanArmors[nIndex]
end

function SAIEntityComponent:GetShipArmor(nIndex)
    return self.tbShipArmors[nIndex]
end

function SAIEntityComponent:GetFired()
    return self.nFired
end

return SAIEntityComponent