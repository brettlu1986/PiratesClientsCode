
local SyncDataUtils = {}

local AgentStatisticsSystem         = require("AgentStatisticsSystem")
local ShipDataTable                 = require("ShipDataTable")
local ShipArmorDataTableEx          = require("ShipArmorDataTableEx")
local GameCoreAgentLuaPoolManager   = require("GameCoreAgentLuaPoolManager")
local AgentStatisticsDef            = require("AgentStatisticsDef")
local HumanMovementStateType        = require("HumanMovementStateType")
local HumanWeaponSlotDef            = require("HumanWeaponSlotDef")
local HumanArmorSlotDef             = require("HumanArmorSlotDef")
local ShipWeaponSlotDef             = require("ShipWeaponSlotDef")
local ShipPartTypeDef               = require("ShipPartTypeDef")
local ShipItemHelper                = require("ShipItemHelper")
local ShipRegionTypeDef             = require("ShipRegionTypeDef")
local GameObjectTypeDef             = require("GameObjectTypeDef")
local BattleShipWeaponSystem        = dynamic_require("BattleShipWeaponSystem")
local HumanWeaponMisc               = require("HumanWeaponMisc")
local HumanWeaponType = HumanWeaponMisc.Type

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SyncDataUtils:", ...)
end
-- luacheck: pop

local tbEmptyTable = {}

local fnGetActorLocation = AIExtendBlueprintFunctions.GetActorLocation_NT
local fnGetActorRotation = AIExtendBlueprintFunctions.GetActorRotation_NT
local fnGetActorVelocity = AIExtendBlueprintFunctions.GetActorVelocity_NT
local fnGetComponentLocation = AIExtendBlueprintFunctions.GetComponentLocation_NT

local tbShipRegionKeys = {
    [ShipRegionTypeDef.SAIL]    = "sail",
    [ShipRegionTypeDef.HEAD]    = "head",
    [ShipRegionTypeDef.SIDE]    = "side",
    [ShipRegionTypeDef.STERN]   = "stern",
    [ShipRegionTypeDef.DECK]    = "deck"
}

local tbBodyParts = {
    ["Uparm_l"]     = "uparm_l",
    ["Uparm_r"]     = "uparm_r",
    ["Forearm_l"]   = "forearm_l",
    ["Forearm_r"]   = "forearm_r",
    ["Head"]        = "head",
    ["Body"]        = "body",
    ["Thigh_r"]     = "thigh_r",
    ["Thigh_l"]     = "thigh_l",
    ["Calf_l"]      = "calf_l",
    ["Calf_r"]      = "calf_r",
}

local RegionTypeLand  = EPiratesGridRegionType.Land
local RegionTypeShore = EPiratesGridRegionType.Shore
local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()

function SyncDataUtils:EmptyTable(tbTable)
    for k,v in pairs(tbTable) do
        tbTable[k] = nil
    end
end

function SyncDataUtils:InRange(nFromX, nFromY, nFromZ, nToX, nToY, nToZ, nRange)
    local nX2 = nFromX - nToX
    nX2 = nX2 * nX2
    local nY2 = nFromY - nToY
    nY2 = nY2 * nY2
    local nZ2 = nFromZ - nToZ
    nZ2 = nZ2 * nZ2
    return nX2 + nY2 + nZ2 <= nRange * nRange
end



function SyncDataUtils:GetShipKeyPositions(tbGameObject, tbKeyPositions, nLuaPoolId)
    self:EmptyTable(tbKeyPositions)
    local nShipId = tbGameObject:GetShipTemplateId()
    local tbShipTemplate = ShipDataTable:GetTemplate(nShipId)
    local nArmorSuitId = tbShipTemplate.nArmorSuitId
    local tbArmorList = ShipArmorDataTableEx:GetAllPartsForSuit(nArmorSuitId)
    local pUEActor = tbGameObject.pUEActor
    local tbShipRegionKeyLuaTable = GameCoreAgentLuaPoolManager:Get(nLuaPoolId, "ShipRegionKey")
    local tbShipKeyPositionLuaTable = GameCoreAgentLuaPoolManager:Get(nLuaPoolId, "ShipKeyPosition")
    for nArmorId, tbArmorTemplate in pairs(tbArmorList) do
        local pSPFD = pUEActor[nArmorId]
        if pSPFD and (pSPFD:GetCollisionEnabled() ~= ECollisionEnabled.NoCollision) then
            local szRegionKey = tbShipRegionKeys[tbArmorTemplate.nRegionType]
            local tbRegionKeyPositions = tbKeyPositions[szRegionKey]
            if not tbRegionKeyPositions then
                tbRegionKeyPositions = tbShipRegionKeyLuaTable:Get()
                self:EmptyTable(tbRegionKeyPositions)
            end
            tbKeyPositions[szRegionKey] = tbRegionKeyPositions
            local nX, nY, nZ = fnGetComponentLocation(pUEActor[nArmorId])
            local tbPos = tbShipKeyPositionLuaTable:Get()
            tbPos.x = nX
            tbPos.y = nY
            tbPos.z = nZ
            table.insert(tbRegionKeyPositions, tbPos)
        end
    end
    return tbKeyPositions
end


local function FetchHumanWeaponParams(tbGameObject, nWeaponInstanceId, tbWeaponParams)
    local HumanWeaponComponent = tbGameObject.HumanWeaponComponent
    local tbWeapon = HumanWeaponComponent:FindWeaponById(nWeaponInstanceId)
    if tbWeapon and not tbWeapon:IsType(HumanWeaponType.THROW) then
        local tbProperty = tbWeapon:GetProperty()
        tbWeaponParams.damage = math.floor(tbProperty.nDamagePerBullet)
        tbWeaponParams.attack_range = tbProperty.nEffectiveRange * 100
        if tbWeapon:IsType(HumanWeaponType.GUN) then
            tbWeaponParams.bullet = tbWeapon:GetCurrentAmmo()
            tbWeaponParams.remain_reloading = tbWeapon:GetRemainReloadingTime()
        elseif tbWeapon:IsType(HumanWeaponType.MELEE) then
            tbWeaponParams.bullet = 1
            tbWeaponParams.remain_reloading = tbWeapon:GetCheatCDTime()
        end
        -- LOG("fetch human weapon params: ",tbGameObject.szName, tbWeapon:GetSlot(),
        -- tbWeaponParams.damage, tbWeaponParams.attack_range, tbWeaponParams.bullet, tbWeaponParams.remain_reloading)
    end
end


local function FetchShipWeaponParams(tbGameObject, tbWeaponItem, tbWeaponParams)
    local tbTemplate = tbWeaponItem:GetTemplate()
    tbWeaponParams.damage = BattleShipWeaponSystem:GetWeaponAttack(tbGameObject, tbWeaponItem:GetSubCategory(), tbWeaponItem:GetTemplate().nBaseDamage)
    tbWeaponParams.bullet = tbWeaponItem:GetBulletLoadedCount(false)
    tbWeaponParams.remain_reloading = math.max(tbWeaponItem:GetRemainingFiringCD(), tbWeaponItem:GetRemainingBulletLoadingTime())
    tbWeaponParams.attack_range = tbTemplate.nFiringRange
    -- LOG("update ship weapon params: ",tbGameObject.szName, tbWeaponItem:GetStorageLocation().nSlotIndex,
    -- tbWeaponParams.damage, tbWeaponParams.attack_range, tbWeaponParams.bullet, tbWeaponParams.remain_reloading)
end


function SyncDataUtils:FillPlayerState(tbGameObject, tbPlayerState, nLuaPoolId, bRealPlayer, bWeaponDetail)
    assert(tbGameObject:GetObjectType() == GameObjectTypeDef.PlayerSelf or tbGameObject:GetObjectType() == GameObjectTypeDef.Npc)
    local pUEActor = tbGameObject.pUEActor
    local tbAgentStatistics = AgentStatisticsSystem:Get(tbGameObject.nServerInstanceId)
    local SAIEntityComponent = tbGameObject.SAIEntityComponent

    local LX, LY, LZ = fnGetActorLocation(pUEActor)
    local RX, RY, RZ = fnGetActorRotation(pUEActor)
    local VX, VY, VZ = fnGetActorVelocity(pUEActor)
    local PropertyComponent = tbGameObject:GetCurrentPropertyComponent()
    local bIsHuman = tbGameObject:IsHuman()

    tbPlayerState.id = tbGameObject.nServerInstanceId
    tbPlayerState.position = tbPlayerState.position or {}
    tbPlayerState.position.x = LX
    tbPlayerState.position.y = LY
    tbPlayerState.position.z = LZ

    tbPlayerState.rotation = tbPlayerState.rotation or {}
    tbPlayerState.rotation.x = RX
    tbPlayerState.rotation.y = RY
    tbPlayerState.rotation.z = RZ

    tbPlayerState.speed = tbPlayerState.speed or {}
    tbPlayerState.speed.x = VX
    tbPlayerState.speed.y = VY
    tbPlayerState.speed.z = VZ

    tbPlayerState.hp     = PropertyComponent:GetHp()
    tbPlayerState.maxhp  = PropertyComponent:GetMaxHp()
    tbPlayerState.teamid = SAIEntityComponent:GetTeamId()
    tbPlayerState.alive  = tbGameObject:IsAlive()
    tbPlayerState.dying  = tbGameObject:IsDying()

    tbPlayerState.kills  = tbAgentStatistics and tbAgentStatistics:GetProperty(AgentStatisticsDef.KILL)   or 0
    tbPlayerState.damages= tbAgentStatistics and tbAgentStatistics:GetProperty(AgentStatisticsDef.DAMAGE) or 0
    tbPlayerState.rescues= tbAgentStatistics and tbAgentStatistics:GetProperty(AgentStatisticsDef.RESCUE) or 0
    tbPlayerState.is_ship= not bIsHuman
    tbPlayerState.ship_posture = SAIEntityComponent:GetShipPosture()
    tbPlayerState.is_human_in_conceal = false

    local tbWeponParamsLuaTable = GameCoreAgentLuaPoolManager:Get(nLuaPoolId, "WeaponParams")
    if bIsHuman then
        tbPlayerState.ship_ext = nil
        local tbHumanState = tbPlayerState.human_ext or {}
        tbPlayerState.human_ext = tbHumanState

        tbPlayerState.active_weapon_category = tbGameObject.HumanWeaponComponent:GetCurrentWeaponCategory()

        local nCurrentState = tbGameObject.HumanMovementStateComponent:GetCurrentState()
        tbHumanState.crouch = nCurrentState == HumanMovementStateType.Crouch_State
        tbHumanState.crawl  = nCurrentState == HumanMovementStateType.Crawl_State
        local nCurrentRegionType = GridTypeManager:GetRegionType(LX, LY)
        if nCurrentRegionType == RegionTypeLand or nCurrentRegionType == RegionTypeShore then
            tbHumanState.binwater = false
        else
            tbHumanState.binwater = true
        end

        if not bRealPlayer then
            local tbKeyPositions = tbHumanState.key_positions or { }
            for k,v in pairs(tbBodyParts) do
                local KeyX, KeyY, KeyZ = fnGetComponentLocation(pUEActor[k])
                tbKeyPositions[v] = tbKeyPositions[v] or {}
                tbKeyPositions[v].x = KeyX
                tbKeyPositions[v].y = KeyY
                tbKeyPositions[v].z = KeyZ
            end
            tbHumanState.key_positions = tbKeyPositions
        end

        local tbWeapons = tbHumanState.weapons or {}
        local tbWeaponParamList = nil
        if bWeaponDetail then
            tbWeaponParamList = tbHumanState.weapon_params or {}
        end
        for i=1,HumanWeaponSlotDef:SlotCount() do
            local tbWeapon = SAIEntityComponent:GetHumanWeapon(i)
            if tbWeapon then
                tbWeapons[i] = tbWeapon:GetTemplateId()
                if bWeaponDetail then
                    local tbWeaponParams = tbWeponParamsLuaTable:Get()
                    FetchHumanWeaponParams(tbGameObject, tbWeapon:GetInstanceId(), tbWeaponParams)
                    tbWeaponParamList[i] = tbWeaponParams
                end
            else
                tbWeapons[i] = 0
                if bWeaponDetail then
                    tbWeaponParamList[i] = tbEmptyTable
                end
            end
        end
        tbHumanState.weapons = tbWeapons
        tbHumanState.weapon_params = tbWeaponParamList

        local tbEquipments = tbHumanState.equipments or {}
        for i=1, HumanArmorSlotDef:SlotCount() do
            local tbArmor = SAIEntityComponent:GetHumanArmor(i)
            if tbArmor then
                tbEquipments[i] = tbArmor:GetTemplateId()
            else
                tbEquipments[i] = 0
            end
        end
        tbHumanState.equipments = tbEquipments
        tbHumanState.fired = SAIEntityComponent:GetFired()

        local HumanConcealComponent = tbGameObject.HumanConcealComponent
        tbPlayerState.is_human_in_conceal = HumanConcealComponent:IsInConceal()

    else
        tbPlayerState.human_ext = nil
        local tbShipState = tbPlayerState.ship_ext or {}
        tbPlayerState.ship_ext = tbShipState

        local tbActiveWeapon = BattleShipWeaponSystem:GetActiveWeaponItem(tbGameObject)
        tbPlayerState.active_weapon_category = tbActiveWeapon and tbActiveWeapon:GetSubCategory() or 0

        local nCharacterInstanceId = tbGameObject.nServerInstanceId

        if not bRealPlayer then
            tbShipState.key_positions = tbShipState.key_positions or {}
            self:GetShipKeyPositions(tbGameObject, tbShipState.key_positions, nLuaPoolId)
        end

        local tbWeapons = tbShipState.weapons or {}
        local tbWeaponParamList = nil
        if bWeaponDetail then
            tbWeaponParamList = tbShipState.weapon_params or {}
        end
        for i=ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
            local tbWeapon = SAIEntityComponent:GetShipWeapon(i)
            if tbWeapon then
                tbWeapons[i] = tbWeapon:GetTemplateId()
                if bWeaponDetail then
                    local tbWeaponParams = tbWeponParamsLuaTable:Get()
                    tbWeaponParams[i] = FetchShipWeaponParams(tbGameObject, tbWeapon, tbWeaponParams)
                    tbWeaponParamList[i] = tbWeaponParams
                end
            else
                tbWeapons[i] = 0
                if bWeaponDetail then
                    tbWeaponParamList[i] = tbEmptyTable
                end
            end
        end
        tbShipState.weapons = tbWeapons
        tbShipState.weapon_params = tbWeaponParamList

        local tbEquipments = tbShipState.equipments or {}
        for i=1, ShipPartTypeDef.Max do
            local tbArmor = SAIEntityComponent:GetShipArmor(i)
            if tbArmor then
                tbEquipments[i] = tbArmor:GetTemplateId()
            else
                tbEquipments[i] = 0
            end
        end
        tbShipState.equipments = tbEquipments

        tbShipState.template_id = ShipItemHelper.GetCurrentShipItemTemplateId(nCharacterInstanceId, false)
    end

    if tbGameObject:GetObjectType() == GameObjectTypeDef.PlayerSelf then
        tbPlayerState.is_npc = false
    elseif tbGameObject:GetObjectType() == GameObjectTypeDef.Npc then
        tbPlayerState.is_npc = true
    end
    return tbPlayerState
end

return SyncDataUtils