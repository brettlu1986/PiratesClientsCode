local luaclass = require("luaclass")
local GameComponentDataParserClass = require("GameComponentDataParser")
local GameComponentDataParser_C = luaclass("GameComponentDataParser_C", GameComponentDataParserClass)

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local NPCDataTable = require("NPCDataTable")
local TemplateTypeDef = require("TemplateTypeDef")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local HumanAvatarHelper = require("HumanAvatarHelper")

-- 单机GameMode创建玩家时
function GameComponentDataParser_C:ParsePlayerSelfGameModeData(tbPrepareInfo, tbSpawnInfo, tbInOutInitProtoData)
    local tbData = GameComponentDataParser_C.super.ParsePlayerSelfGameModeData(self, tbPrepareInfo, tbSpawnInfo, tbInOutInitProtoData)
    tbData["SkillComponentClient"] = tbData["SkillComponentServer"]
    tbData["ShipAvatarComponent"] = tbInOutInitProtoData.ship_res
    tbData["BattleFactionComponent"] = {nFaction =  tbInOutInitProtoData.faction}
    tbData["GuildComponent"] = {guild_name = tbInOutInitProtoData.guild_name}
    return tbData
end

-- 公海进入时
function GameComponentDataParser_C:ParsePlayerSelfHubData(nTemplateType, tbProtoData)
    local tbData = {}
    local tbPlayerData = tbProtoData.data
    -- local nTemplateId
    -- if bShip then
    --     nTemplateId = GamePlayerSelfHelper:GetShipTemplateId(tbPlayerData.ship_list)
    -- else
    --     nTemplateId = GamePlayerSelfHelper:GetHumanTemplateId(tbPlayerData.avatar)
    -- end

    if(GlobalVariableSystem.bEnableNewLobbyServer) then
        tbData["LobbyPropertyComponent"] = tbPlayerData
        --tbData["ShipSelfPropertyComponent"] = GamePlayerSelfHelper:GetCurrentShipData(tbPlayerData.ship_list)
    else
        tbData["HumanSelfPropertyComponent"] = tbPlayerData.avatar
        tbData["ShipSelfPropertyComponent"] = GamePlayerSelfHelper:GetCurrentShipData(tbPlayerData.ship_list)
    end

    tbData["ItemComponent"] = tbPlayerData.item
    local tbCurrency = {}
    tbCurrency.currency = tbPlayerData.currency
    tbCurrency.currency_ceilings = tbPlayerData.currency_ceilings
    tbData["CurrencyComponent"] = tbCurrency
    tbData["WearComponent"] = {fashion = tbPlayerData.wears.fashion, weapon_fashion = tbPlayerData.weapon_skin.weapon_skins, dry_fashion_flag = tbPlayerData.wears.dry_fashion_flag}
    tbData["SailorComponent"] = tbPlayerData.sailor
    tbData["SeasonComponent"] = tbPlayerData.season
    tbData["ShipPreparationComponent"] = tbPlayerData.ship
    tbData["PartnerComponent"] = tbPlayerData.partners
    tbData["HumanAvatarComponentNew"] = HumanAvatarHelper.MakeHumanAvatarComponentCreateParameterByPlayerData(tbPlayerData)
    tbData["AppearanceComponent"] = tbPlayerData.appearance

    return tbData
end

-- 客户端联网副本进入时
-- tbPlayerActorInitData结构请参见dungeon_common.proto里的PlayerActorInitData
function GameComponentDataParser_C:ParsePlayerReplicatedData(pUEActor, tbPlayerActorInitData)
    local tbData = {}
    tbData["SkillComponentClient"] = tbPlayerActorInitData.skill_info
    tbData['BattleCampComponent'] = {CampType = tbPlayerActorInitData.camp_type}
    tbData["ShipAvatarComponent"] = tbPlayerActorInitData.ship_res
    local tbShipInfo = {}
    tbShipInfo.nShipTemplateId = tbPlayerActorInitData.template_id
    tbData["BattleShipMovementComponent"] = tbShipInfo
    tbData["BattleFactionComponent"] = {nFaction =  tbPlayerActorInitData.faction}
    return tbData
end

----------------------------------------------------------------------------------
-- Npc
-- 公海进入时
function GameComponentDataParser_C:ParseNpcHubData(tbProtoData)
    return nil
end

-- 客户端联网副本进入时
-- tbNpcActorInitData结构请参见dungeon_common.proto里的NpcActorInitData
function GameComponentDataParser_C:ParseNpcReplicatedData(pUEActor, tbNpcActorInitData)
    local tbData = {}
    tbData['BattleCampComponent'] = {CampType = tbNpcActorInitData.camp_type}
    local tbNpcTemplate = NPCDataTable:GetTemplate(tbNpcActorInitData.template_id)
    if tbNpcTemplate.nType == TemplateTypeDef.SHIP then
        tbData["BattleShipMovementComponent"] = { nShipTemplateId = tbNpcTemplate.nTypeID }
    -- elseif tbNpcTemplate.nType == TemplateTypeDef.HUMAN then
        -- tbData["HumanAvatarComponentNew"] = HumanAvatarHelper.MakeHumanAvatarComponentCreateParameterByNpcActorInitData(tbNpcActorInitData)
    end

    tbData["DialogBoardComponent"] = {nDialogBoardId = tbNpcActorInitData.dialog_board_id}
    return tbData
end

----------------------------------------------------------------------------------
-- PlayerOther
-- 公海
function GameComponentDataParser_C:ParsePlayerOtherHubData(tbProtoData)
    local tbData = {}
    -- tbData["HumanOtherPropertyComponent"] = tbProtoData
    -- tbData["ShipOtherPropertyComponent"] = tbProtoData
    -- tbData["HumanMovementHubModeComponent"] = tbProtoData.actor
    -- tbData["ShipAvatarComponent"] = tbProtoData.actor.ship_res
    -- tbData["HumanAvatarComponent"] = tbProtoData.actor.human_res
    -- tbData["FactionComponent"] = tbProtoData.player
    -- tbData["PlayerStateComponent"] = tbProtoData.actor.human_action_state
    tbData["HumanAvatarComponentNew"] = HumanAvatarHelper.MakeHumanAvatarComponentCreateParameterForPlayerOtherInHub(tbProtoData)
    return tbData
end

function GameComponentDataParser_C:ParseTriggerReplicatedData(tbInitProtoData)
    local tbData = {}
    tbData["BattleTriggerComponent"] = { nCollisionType = tbInitProtoData.collision_type}
    return tbData
end

function GameComponentDataParser_C:ParseDestructibleObjectReplicatedData(tbInitProtoData)
    local tbData = {}
    return tbData
end

return GameComponentDataParser_C
