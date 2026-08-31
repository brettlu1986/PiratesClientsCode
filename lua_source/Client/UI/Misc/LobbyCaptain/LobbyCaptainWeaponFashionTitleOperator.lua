-----------------------------------------------------
--File Name    : LobbyCaptainWeaponFashionTitleOperator.lua
--Description  :
-----------------------------------------------------

local luaclass = require("luaclass")
local LobbyCaptainTitleOperator = require("LobbyCaptainTitleOperator")
local LobbyCaptainWeaponFashionTitleOperator = luaclass("LobbyCaptainWeaponFashionTitleOperator", LobbyCaptainTitleOperator)

local HumanWeaponDefaultDataTable   = require("HumanWeaponDefaultDataTable")
local HumanWeaponDef                = require("HumanWeaponDef")
local LobbyCaptainMiscDef           = require("LobbyCaptainMiscDef")
local DescKeyParser                 = require("DescKeyParser")
local DescKeyParserMiscDef          = require("DescKeyParserMiscDef")


local MELEE_DESC_KEYS =
{
    "lobby_general_desc",
    "lobby_special_desc",
    "damage_all_levels",
    "attack_range_all_levels",
    "melee_attack_speed_all_levels",
}
local RANGED_DESC_KEYS =
{
    "lobby_general_desc",
    "lobby_special_desc",
    "damage_all_levels",
    "attack_times_all_levels",
    "speed_of_bullet_all_levels",
    "reload_time_all_levels",
    "rate_of_fire_all_levels",
    "recoil_all_levels",
}
local WAND_DESC_KEYS =
{
    "lobby_general_desc",
    "lobby_special_desc",
    "damage_all_levels",
    "charge_time_all_levels",
    "fire_ball_speed_all_levels",
    "fire_ball_explosive_range_all_levels",
    "fire_ball_auto_explosive_range_all_levels",
}

local function GetKeyList(nInstanceType)
    local tbInstanceData = HumanWeaponDefaultDataTable:GetAllLevelData(nInstanceType)
    if nInstanceType == LobbyCaptainMiscDef.UnarmedWeaponInstanceType then
        return MELEE_DESC_KEYS
    else
        local nWeaponCategory = tbInstanceData.nWeaponCategory
        if nWeaponCategory == HumanWeaponDef.WeaponCategory.Wand then
            return WAND_DESC_KEYS
        end
        if tbInstanceData.nRangeType  == HumanWeaponDef.WeaponPrimaryCategory.Melee then
            return MELEE_DESC_KEYS
        else
            return RANGED_DESC_KEYS
        end
    end
end

local function GetProperties(nInstanceType)
    local tbProperties = {}
    local tbKeyList = GetKeyList(nInstanceType)
    local szNameSpace = DescKeyParserMiscDef.NAME_SPACE_HUMAN_WEAPON
    local tbInputData = {}
    tbInputData.nIntanceType = nInstanceType
    for _, szKey in ipairs(tbKeyList) do
        local tbResult =  DescKeyParser.GetParseData(szNameSpace, szKey, tbInputData)
        if tbResult then
            local tbData = {}
            tbData[1] = tbResult.l10nKey
            tbData[2] = tbResult.l10nValue
            table.insert(tbProperties, tbData)
        end
    end
    return tbProperties
end

local function RefreshDescription(self, nInstanceType)
    local tbDesc = GetProperties(nInstanceType)
    self.ListHelper:SetData(tbDesc)
end

local function RefreshTitle(self, nInstanceType)
    local tbInstanceData = HumanWeaponDefaultDataTable:GetAllLevelData(nInstanceType)
    self:SetTipTitle(tbInstanceData.l10nName)
end

function LobbyCaptainWeaponFashionTitleOperator:OnTitleInfoSet(tbTitleInfo)
    local nWeaponInstanceType = tbTitleInfo.nWeaponInstanceType
    local tbInstanceData = HumanWeaponDefaultDataTable:GetAllLevelData(nWeaponInstanceType)
    self:SetTitleText(tbInstanceData.l10nName)
    self:SetTitleVisible(true)
end

function LobbyCaptainWeaponFashionTitleOperator:OnTipShow(tbTitleInfo)
    local nWeaponInstanceType = tbTitleInfo.nWeaponInstanceType
    RefreshDescription(self, nWeaponInstanceType)
    RefreshTitle(self, nWeaponInstanceType)
end


return LobbyCaptainWeaponFashionTitleOperator