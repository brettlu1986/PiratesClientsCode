local luaclass = require("luaclass")
local ShipAvatarComponent = require("ShipAvatarComponent")
local ShipAvatarComponent_C = luaclass("ShipAvatarComponent_C", ShipAvatarComponent)

local PropName = require("PropName")
local ShipResDataTable = require("ShipResDataTable")
local GameAvatarHelper = require("GameAvatarHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local ShipPartBrokenStatus = require("ShipPartBrokenStatus")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local BattleItemDataTable = require("BattleItemDataTable")
local ShipWeaponTemplateDef = require("ShipWeaponTemplateDef")
local ResourceManager = require("ResourceManager")

local SHIP_MERGE_ENABLED = false

local EMPTY_WEAPON_EQUIP_ID = -1

local SHIP_WEAPON_RES_KEY_TO_ENUM = {
    ["head_id"] = ShipWeaponSlotDef.HEAD,
    ["side_id"] = ShipWeaponSlotDef.SIDE,
    ["deck_id"] = ShipWeaponSlotDef.DECK,
}

-- local BURN_BROKEN_STATUS_VALUE = {
--     [ShipPartBrokenStatus.UNBROKEN] = 0.0,
--     [ShipPartBrokenStatus.DAMANGED] = 0.6,
--     [ShipPartBrokenStatus.BROKEN]   = 1.0,
-- }

local COMMON_BROKEN_STATUS_VALUE = {
    [ShipPartBrokenStatus.UNBROKEN] = 0.0,
    [ShipPartBrokenStatus.DAMANGED] = 0.6,
    [ShipPartBrokenStatus.BROKEN]   = 1.0,
}

local SHIP_PART_BROKEN_INFO_MAP = {
    armor           = {
        szFuncName  = "SetArmorMaterialParamFloat",
        szSlotName  = "default",
        szParamName = "damage",
        tbStatus = COMMON_BROKEN_STATUS_VALUE
    },
    captain_cabin   = {
        szFuncName  = "SetCaptainCabinMaterialParamFloat",
        szSlotName  = "default",
        szParamName = "damage",
        tbStatus = COMMON_BROKEN_STATUS_VALUE
    },
    -- sail            = {
    --     szFuncName  = "SetMaterialParamFloat",
    --     szSlotName  = "sail",
    --     szParamName = "Burn",
    --     tbStatus = BURN_BROKEN_STATUS_VALUE
    -- }
}

ShipAvatarComponent_C.pAvatarComponent = nil
ShipAvatarComponent_C.tbBrokenStatusCache = nil
ShipAvatarComponent_C.tbWeaponResCache = nil
ShipAvatarComponent_C.tbWeaponLoadingHandles = nil

local function AddShipWeaponMeshInternal(self, szResKey, tbTemplate, pWeaponMesh, pSimplifiedModelRes)
    if not (pWeaponMesh and pSimplifiedModelRes and self.pAvatarComponent) then
        return
    end
    local szWeaponClassName = BattleItemDataTable:GetItemClass(tbTemplate.nCategory, tbTemplate.nSubCategory)
    local nWeaponTemplateType = require(szWeaponClassName):GetTemplateType()
    local pControlClass = ShipWeaponTemplateDef.GetBPControlClassPath(nWeaponTemplateType):load()
    local tbValidWeaponSlotLevel = tbTemplate.tbValidWeaponSlotLevel
    local pWeaponSlot = ShipWeaponSlotDef.GetBPEnum(SHIP_WEAPON_RES_KEY_TO_ENUM[szResKey])
    self.pAvatarComponent:AddShipWeaponMesh(pWeaponSlot, pWeaponMesh, pSimplifiedModelRes, tbValidWeaponSlotLevel, pControlClass)
end

local function RecordAsyncInfo(self, szResKey, nHandle, pObject)
    local tbHandles = self.tbWeaponLoadingHandles[szResKey]
    if not tbHandles then
        tbHandles = {}
        self.tbWeaponLoadingHandles[szResKey] = tbHandles
    end
    tbHandles[nHandle] = pObject or false
    log("[ShipAvatarComponent] RecordAsyncInfo", szResKey, nHandle, pObject)
end

local function CancelLoadAsync(self, szResKey, tbHandles)
    tbHandles = tbHandles or self.tbWeaponLoadingHandles[szResKey]
    if tbHandles then
        for nHandle, pObject in pairs(tbHandles) do
            ResourceManager:CancelLoadAsync(nHandle)
            if pObject then
                ResourceManager:Unhold(pObject)
            end
            log("[ShipAvatarComponent] CancelLoadAsync", szResKey, nHandle, pObject)
        end
        self.tbWeaponLoadingHandles[szResKey] = nil
    end
end

local function CancelAllLoadAsync(self)
    for szResKey, tbHandles in pairs(self.tbWeaponLoadingHandles) do
        CancelLoadAsync(self, szResKey, tbHandles)
    end
    self.tbWeaponLoadingHandles = nil
end

local function AddShipWeaponMesh(self, szResKey, nTemplateId)
    local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    if not tbTemplate then
        logerror("AddShipWeaponMesh failed", szResKey, nTemplateId)
        return
    end
    local szModelRes = tbTemplate.szModelRes
    if not szModelRes then
        return
    end

    local szSimplifiedModelRes = tbTemplate.szSimplifiedModelRes
    local pWeaponMesh = nil
    local pSimplifiedModelRes = nil
    local nModelHandle = ResourceManager:LoadAsync(szModelRes, function(_szAssetName, pObject, nHandle)
        pWeaponMesh = pObject
        if not szSimplifiedModelRes then
            pSimplifiedModelRes = pObject
        end
        RecordAsyncInfo(self, szResKey, nHandle, pObject)
        AddShipWeaponMeshInternal(self, szResKey, tbTemplate, pWeaponMesh, pSimplifiedModelRes)
    end, true)
    RecordAsyncInfo(self, szResKey, nModelHandle, pWeaponMesh)

    if szSimplifiedModelRes then
        local nSimpleModelHandle = ResourceManager:LoadAsync(szSimplifiedModelRes, function(_szAssetName, pObject, nHandle)
            pSimplifiedModelRes = pObject
            RecordAsyncInfo(self, szResKey, nHandle, pObject)
            AddShipWeaponMeshInternal(self, szResKey, tbTemplate, pWeaponMesh, pSimplifiedModelRes)
        end, true)
        RecordAsyncInfo(self, szResKey, nSimpleModelHandle, pSimplifiedModelRes)
    end
end

local function RemoveShipWeaponMesh(self, szResKey)
    CancelLoadAsync(self, szResKey)

    local pWeaponSlot = ShipWeaponSlotDef.GetBPEnum(SHIP_WEAPON_RES_KEY_TO_ENUM[szResKey])
    self.pAvatarComponent:RemoveShipWeaponMesh(pWeaponSlot)
end

local function OnAvatarResChangedInternal(self, tbResData)
    if not self.pAvatarComponent.Inited then
        return
    end

    local nShipResId = self.Owner.ShipBattlePropertyComponent:GetProp(PropName.nShipResTemplateId)
    local tbShipResData = ShipResDataTable:GetTemplate(nShipResId)
    GameAvatarHelper:UpdateShipAvatar(self.pAvatarComponent, tbResData, self.nShipTemplateId, tbShipResData)
    EventManager:OnFireEvent(ClientEventDef.EV_SHIP_AVATAR_RES_CHANGED, tbResData)
end

local function OnShipPartBrokenStatusChangedInternal(self, tbBrokenStatusData)
    for szPartName, nBrokenStatus in pairs(tbBrokenStatusData) do
        if self.tbBrokenStatusCache[szPartName] ~= nBrokenStatus then
            self.tbBrokenStatusCache[szPartName] = nBrokenStatus
            local tbBrokenInfo = SHIP_PART_BROKEN_INFO_MAP[szPartName]
            if tbBrokenInfo then
                local nParamValue = tbBrokenInfo.tbStatus[nBrokenStatus]
                if nParamValue then
                    local fnSetMaterialParam = self.Owner.pUEActor[tbBrokenInfo.szFuncName]
                    fnSetMaterialParam(self.Owner.pUEActor, tbBrokenInfo.szSlotName, tbBrokenInfo.szParamName, tbBrokenInfo.tbStatus[nBrokenStatus])
                end
            end
        end
    end
end

local function OnShipArmorGradeChangedInternal(self, nNewShipArmorGrade)
    self.Owner.pUEActor:SetArmorGrade(nNewShipArmorGrade)
end

local function OnWeaponResChangedInternal(self, tbWeaponResData)
    for szResKey,nTemplateId in pairs(tbWeaponResData) do
        local nLastTemplateId = self.tbWeaponResCache[szResKey] or EMPTY_WEAPON_EQUIP_ID
        if nLastTemplateId ~= nTemplateId then
            self.tbWeaponResCache[szResKey] = nTemplateId
            if nLastTemplateId ~= EMPTY_WEAPON_EQUIP_ID then
                RemoveShipWeaponMesh(self, szResKey)
            end
            if nTemplateId ~= EMPTY_WEAPON_EQUIP_ID then
                AddShipWeaponMesh(self, szResKey, nTemplateId)
            end
        end
    end
end

local function OnAvatarResCommitFinish(self)
    self.Owner.pUEActor:InitShipMaterials()

    self.tbBrokenStatusCache = {}

    local PropertyComponent = self.Owner.ShipBattlePropertyComponent
    self:OnShipPartBrokenStatusChanged(PropertyComponent:GetProp(PropName.rShipPartBrokenStatus))
    self:OnShipArmorGradeChanged(PropertyComponent:GetProp(PropName.nShipArmorGrade))

    if (self.Owner:GetObjectType() == GameObjectTypeDef.PlayerSelf)
    or (self.Owner:GetObjectType() == GameObjectTypeDef.PlayerOther) then
        self.Owner.pUEActor:TriggerMastVisibleChangedEvent()
    end
end

function ShipAvatarComponent_C:OnActorCreated(pUEActor)
    ShipAvatarComponent_C.super.OnActorCreated(self, pUEActor)

    self.pAvatarComponent = pUEActor.ShipAvatarComponent
    self.pAvatarComponent:SetUseMerge(SHIP_MERGE_ENABLED)

    self.tbBrokenStatusCache = {}
    self.tbWeaponResCache = {}
    self.tbWeaponLoadingHandles = {}

    self.EventHelper:RegisterLuaDelegate(self.Owner.DelegateComponent.OnAvatarResCommitFinish, OnAvatarResCommitFinish, self)

    pUEActor:InitShipMaterials()

    local PropertyComponent = self.Owner.ShipBattlePropertyComponent
    self:OnAvatarResChanged(PropertyComponent:GetProp(PropName.rShipAvatarResData))
    self:OnShipPartBrokenStatusChanged(PropertyComponent:GetProp(PropName.rShipPartBrokenStatus))
    self:OnShipArmorGradeChanged(PropertyComponent:GetProp(PropName.nShipArmorGrade))
    self:OnWeaponResChanged(PropertyComponent:GetProp(PropName.rShipWeaponResData))
end

function ShipAvatarComponent_C:OnActorDestroyed(pUEActor)
    CancelAllLoadAsync(self)
    self.pAvatarComponent = nil
    ShipAvatarComponent_C.super.OnActorDestroyed(self, pUEActor)
end

function ShipAvatarComponent_C:OnAvatarResChanged(tbAvatarResData)
    if self.pAvatarComponent then
        OnAvatarResChangedInternal(self, tbAvatarResData)
    end
end

function ShipAvatarComponent_C:OnShipPartBrokenStatusChanged(tbBrokenStatusData)
    if self.pAvatarComponent then
        OnShipPartBrokenStatusChangedInternal(self, tbBrokenStatusData)
    end
end

function ShipAvatarComponent_C:OnShipArmorGradeChanged(nShipArmorGrade)
    if self.pAvatarComponent then
        OnShipArmorGradeChangedInternal(self, nShipArmorGrade)
    end
end

function ShipAvatarComponent_C:OnWeaponResChanged(tbWeaponResData)
    if self.pAvatarComponent then
        OnWeaponResChangedInternal(self, tbWeaponResData)
    end
end

return ShipAvatarComponent_C
