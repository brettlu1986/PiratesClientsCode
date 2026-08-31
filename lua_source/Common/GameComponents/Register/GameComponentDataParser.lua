local luaclass = require("luaclass")
local GameComponentDataParser = luaclass("GameComponentDataParser")

local NPCDataTable = require("NPCDataTable")
local NpcSkillDataTable = require("NpcSkillDataTable")
local TemplateTypeDef = require("TemplateTypeDef")
local HumanAvatarHelper = require("HumanAvatarHelper")

-- GameMode创建玩家时
-- 创建controller时
function GameComponentDataParser:ParsePlayerSelfControllerData(tbPlayerSelf, tbInOutInitProtoData)
end

-- tbInOutInitProtoData结构请参见dungeon_common.proto里的PlayerActorInitData
function GameComponentDataParser:ParsePlayerSelfGameModeData(tbPrepareInfo, tbSpawnInfo, tbInOutInitProtoData)
    local tbData = {}
    local tbStartJsonData = tbSpawnInfo.tbStartJsonData
    local tbShipInfo = tbPrepareInfo.tbShipInfo

    tbData["HumanBattlePropertyComponent"] = { nHumanTemplateId = tbPrepareInfo.nHumanId }
    tbData["BattleShipMovementComponent"] = { nShipTemplateId = tbShipInfo.nTypeId }
    tbData["SkillComponentServer"] = tbShipInfo.tbSkills
    tbData["BattleShipSkinComponent"] = tbPrepareInfo.tbShipSkinIds
    tbData["PropertyComboComponent"] = tbPrepareInfo
    tbData["HumanAvatarComponentNew"] = HumanAvatarHelper.MakeHumanAvatarComponentCreateParameterByPrepareInfo(tbPrepareInfo)
    tbData["HumanWeaponAvatarComponentNew"] = tbPrepareInfo.tbHumanWeaponFashionTemplateIds


    tbInOutInitProtoData["skill_info"] = tbShipInfo.tbSkills
    tbInOutInitProtoData['ship_res'] = tbShipInfo.tbShipRes
    tbInOutInitProtoData['firstEffects'] = tbShipInfo.tbFirstEffects
    tbInOutInitProtoData['secondEffects'] = tbShipInfo.tbSecondEffects
    tbInOutInitProtoData['cannonBalls'] = tbShipInfo.tbCannonBalls
    tbInOutInitProtoData['durability'] = tbShipInfo.nDurability
    tbInOutInitProtoData['faction']    = tbPrepareInfo.nFaction
    tbInOutInitProtoData["guild_name"]  = tbPrepareInfo.szGuildName

    -- Temp Code end
    if tbStartJsonData ~= nil then
        tbData["BattleCampComponent"] = { CampType = tbStartJsonData.CampType }
        tbInOutInitProtoData['camp_type'] = tbStartJsonData.CampType
    end
    return tbData
end

-- Gamemode创建Npc时
function GameComponentDataParser:ParseNpcGameModeData(tbSpawnInfo, tbInOutInitProtoData)
    local nTemplateId = tbSpawnInfo.nTemplateId
    local tbStartJsonData = tbSpawnInfo.tbJsonData
    -- local bCreateAI = tbSpawnInfo.bCreateAI

    local tbTemplate = NPCDataTable:GetTemplate(nTemplateId)
    if tbTemplate == nil then
        error('GameComponentDataParser:ParseNpcGameModeData tbTemplate is nil, nTemplateId : '.. nTemplateId)
        return nil
    end

    local tbData = {}
    tbData["SkillComponentServer"] = NpcSkillDataTable:GetNpcSkillInfo(nTemplateId)
    if tbTemplate.nType == TemplateTypeDef.SHIP then
        tbData["BattleShipMovementComponent"] = { nShipTemplateId = tbTemplate.nTypeID }
    elseif tbTemplate.nType == TemplateTypeDef.HUMAN then
        tbData["HumanBattlePropertyComponent"] = { nHumanTemplateId = tbTemplate.nTypeID }
        local nHumanTemplateId = tbTemplate.nTypeID
        local tbAvatarComponentCreateParameter = HumanAvatarHelper.MakeHumanAvatarComponentCreateParameterByHumanConfig(nHumanTemplateId)
        tbData["HumanAvatarComponentNew"] = tbAvatarComponentCreateParameter
    end
    if tbStartJsonData ~= nil then
        tbData["BattleCampComponent"] = { CampType = tbStartJsonData.CampType }
        tbInOutInitProtoData['camp_type'] = tbStartJsonData.CampType
        -- if(tbStartJsonData.PathId) then
        --     tbData["BattleNpcAIComponent"] = { nPathId = tonumber(tbStartJsonData.PathId), tbTargetingPriorities = tbStartJsonData.TargetingPriorities }
        -- end
        tbInOutInitProtoData['dialog_board_id'] = tbStartJsonData.DialogBoardId
        tbData["DialogBoardComponent"] = {nDialogBoardId = tbStartJsonData.DialogBoardId}
    end

    tbData["HumanWeaponAvatarComponentNew"] = {}
    -- if tbData.BattleNpcAIComponent ~= nil then
    --     tbData.BattleNpcAIComponent.bCreateAI = bCreateAI
    -- else
    --     tbData.BattleNpcAIComponent = { bCreateAI = bCreateAI }
    -- end

    return tbData
end

-- Trigger创建时
function GameComponentDataParser:ParseTriggerGameModeData(tbSpawnInfo, tbInOutInitProtoData)
    local tbData = {}
    local tbJsonData = tbSpawnInfo.tbJsonData
    tbData["BattleTriggerComponent"] = { nCollisionType = tbJsonData.CollisionType or 0 }
    return tbData
end

-- Dummy创建时
function GameComponentDataParser:ParseDummyGameModeData(nTemplateId, tbJsonData, tbInOutInitProtoData)
    return nil
end

function GameComponentDataParser:ParseDestructibleObjectGameModeData(nTemplateId, tbJsonData, tbInOutInitProtoData)
    local tbData = {}
    tbData["DestructibleObjectAIComponent"] = { nTransformId = tbJsonData.TransformId }
    return tbData
end

return GameComponentDataParser
