local GameObjectTypeDef      = require("GameObjectTypeDef")
local GlobalVariableSystem   = dynamic_require("GlobalVariableSystem")
local DamageTypeEx           = require("DamageTypeEx")
local DamageCauserType       = require("DamageCauserType")
local ScoreIni               = require("ScoreIni")
local BattleTeamSystem       = require("BattleTeamSystem")
local BattleItemSystemServer = require("BattleItemSystemServer")
local BattlePrepareSystem    = require("BattlePrepareSystem")
local TemplateTypeDef        = require("TemplateTypeDef")
-- local HumanMovementStateType = require("HumanMovementStateType")

local BattleStatsHelper = {}


local function GetHumanMovementState(tbPlayer)
    if tbPlayer == nil then
        return -1
    end

    if tbPlayer:IsHuman() then
        if tbPlayer.HumanMovementStateComponent ~= nil then
            return tbPlayer.HumanMovementStateComponent:GetCurrentState()
        else
            logerror("BattleStatsHelper GetHumanMovementState is nil ", tbPlayer.szName, tbPlayer.nPlayerId, tbPlayer.nServerInstanceId, debug.traceback( ))
            error("BattleStatsHelper GetHumanMovementState is nil")
            return -1
        end
    end

    return -1
end

local function GetCauserInfo(tbCauser, tbTaker)
    local tbTakerPropertyComponent = tbTaker:GetCurrentPropertyComponent()
    local nTakerDamageType = tbTakerPropertyComponent:GetLastDamageType()
    if nTakerDamageType == DamageTypeEx.POISON_CIRCLE then
        return DamageCauserType.POISON_CIRCLE, 0, DamageCauserType.POISON_CIRCLE
    elseif nTakerDamageType == DamageTypeEx.FALLING then
        return DamageCauserType.FALLING, 0, DamageCauserType.FALLING
    elseif nTakerDamageType == DamageTypeEx.DYING_REDUCE then
        return DamageCauserType.DYING_REDUCE, 0, DamageCauserType.DYING_REDUCE
    elseif nTakerDamageType == DamageTypeEx.DROWN then
        return DamageCauserType.DROWN, 0, DamageCauserType.DROWN
    elseif tbCauser ~= nil then
        local nShipId = tbCauser:GetShipTemplateId()
        local tbPlayerPrepareInfo = BattlePrepareSystem:GetPlayerPrepareInfo(tbCauser.nPlayerId)

        if BattlePrepareSystem:IsBot(tbCauser.nPlayerId) then
            return DamageCauserType.BOT, tbCauser:IsShip() and nShipId or tbPlayerPrepareInfo.nHumanId, tbCauser.nPlayerId, tbCauser.nServerInstanceId
        elseif tbCauser:GetObjectType() == GameObjectTypeDef.Npc then
            return DamageCauserType.NPC, tbCauser.nTemplateId, tbCauser:GetServerInstanceId(), tbCauser.nServerInstanceId
        else
            return DamageCauserType.PLAYER, tbCauser:IsShip() and nShipId or tbPlayerPrepareInfo.nHumanId, tbCauser.nPlayerId, tbCauser.nServerInstanceId
        end
    else
        log("GetCauserType failed: Causer is nil and DamageType is ", nTakerDamageType)
        return DamageCauserType.UNKNOWN, 0, DamageCauserType.UNKNOWN
    end
end

function BattleStatsHelper.MakeDamageData(tbTaker, tbCauser, nDamage, nDamageType)
    local tbTakerPropertyComponent = tbTaker:GetCurrentPropertyComponent()
    local tbTakerDamageExtraData = tbTakerPropertyComponent:GetLastDamageExtraData()
    local tbTakerDamageType = nDamageType ~= nil and nDamageType or tbTakerPropertyComponent:GetLastDamageType()
    -- if nDamage ~= 0 and tbTakerDamageType == DamageTypeEx.UNKNOWN then
    --     logerror("test log ", debug.traceback(  ))
    --     error("damage type is unknown")
    -- end
    local nWeaponTemplateId = tbTakerDamageExtraData and tbTakerDamageExtraData.nWeaponTemplateId
    local nCauserType, nTemplateId, nId, nInstanceId = GetCauserInfo(tbCauser, tbTaker)
    local nMovementState = GetHumanMovementState(tbTaker)
    local tbDamageData = {
        nCauserType = nCauserType,
        nTemplateId = nTemplateId,
        nCauserId = nId,
        nCauserInstanceId = nInstanceId,
        nDamage = nDamage,
        nDamageType = tbTakerDamageType,
        nWeaponTemplateId = nWeaponTemplateId or -1,
        nRegionType = tbTakerDamageExtraData and tbTakerDamageExtraData.nRegionType,
        bIsCoreRegion = tbTakerDamageExtraData and tbTakerDamageExtraData.bIsCoreRegion,
        nMovementState = nMovementState,
        nTime = GlobalVariableSystem:GetLocalTime(),
        nTemplateType = tbCauser ~= nil and tbCauser.nTemplateType or TemplateTypeDef.INVALID,
        -- bDying = nMovementState == HumanMovementStateType.Dying_State 

    }

    return tbDamageData
end

function BattleStatsHelper.GetAllItems(tbTaker)
    local tbItems = BattleItemSystemServer:GetAllPlayerItems(tbTaker:GetServerInstanceId())    
    local tbRet = {}
    for i, v in ipairs(tbItems) do
        local nTempId = v:GetTemplateId()
        local nCount = v:GetStackCount()
        local tbItemData = {nTemplateId = nTempId, nCount = nCount}
        table.insert(tbRet, tbItemData)
    end

    return tbRet
end

function BattleStatsHelper.ArrangeDamagedArray(tbDamagedArray)
    -- 排除重伤下衰减
    -- 排除自杀(自己和队友存活，自己重伤，队友直接死了，这时自己会直接死，伤害类型是KILL_SELF)
    local tbTemp = {}
    for i, v in ipairs(tbDamagedArray) do
        if v.nDamageType ~= DamageTypeEx.DYING_REDUCE and 
            v.nDamageType ~= DamageTypeEx.KILL_SELF 
            and v.nDamageType ~= DamageTypeEx.UNKNOWN then
            table.insert(tbTemp, v)
        end
    end
    tbDamagedArray = tbTemp

    -- 删除超时的数据
    local nCurTime = GlobalVariableSystem:GetLocalTime()
    local nRemoveIndex = 0
    local nTime = ScoreIni.tbAssistScore.nTime
    for i = #tbDamagedArray, 1,  -1 do
        if nCurTime - tbDamagedArray[i].nTime > nTime then
            nRemoveIndex = i
            break
        end
    end
    if nRemoveIndex > 0 then
        tbTemp = {}
        for i = nRemoveIndex + 1, #tbDamagedArray do
            table.insert(tbTemp, tbDamagedArray[i])
        end
        tbDamagedArray = tbTemp
    end

    return tbDamagedArray
end

function BattleStatsHelper:GetPlayerId(tbDamageData)
    if tbDamageData.nCauserType == DamageCauserType.PLAYER then
        return tbDamageData.nCauserId
    end
end

function BattleStatsHelper:GetTeamMemberIds(tbGamePlayer)
    local tbMembers = BattleTeamSystem:GetTeamMembersByPlayer(tbGamePlayer)
    if tbMembers ~= nil then
        local tbRet = {}
        for i, v in ipairs(tbMembers) do
            table.insert(tbRet, v.nPlayerId)
        end 
        return tbRet
    end     
end

return BattleStatsHelper