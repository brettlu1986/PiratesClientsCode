-----------------------------------------------------
--File Name    : HumanArmorDataTableHelper.lua
--Author       : WuJizhou
--Create Time  : 8/29/2018, 12:05:53 PM
--Description  : HumanArmorDataTableHelper
-----------------------------------------------------
local HumanArmorDataTableHelper = {}

local HumanBodyDef = require("HumanBodyDef")
local HumanWeaponDef = require("HumanWeaponDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local HumanWeaponDamageType = HumanWeaponDef.WeaponDamageType

local L10N = require("L10N")

local SPECIAL_DESC_MAX_COUNT = 7
local REDUCE_DAMAGE_DESC_MAX_COUNT = 3

local function ParseSpecialDesc(Parser, NewTemplate)
    local tbSpecialDesc = {}
    for nIdx = 1, SPECIAL_DESC_MAX_COUNT do
        local l10nSpecialDesc = Parser:Get("special_desc_"..nIdx, L10N.NullString, Parser.TypeL10N)
        if l10nSpecialDesc and l10nSpecialDesc ~= L10N.NullString then
            table.insert(tbSpecialDesc, l10nSpecialDesc)
        end
    end
    NewTemplate.tbSpecialDesc = tbSpecialDesc
end

local function ParseReduceDamageDesc(Parser, NewTemplate)
    local tbReduceDamageDesc = {}
    for nIdx = 1, REDUCE_DAMAGE_DESC_MAX_COUNT do
        local l10nReduceDamageDesc = Parser:Get("reduce_damage_desc_"..nIdx, L10N.NullString, Parser.TypeL10N)
        if l10nReduceDamageDesc and l10nReduceDamageDesc ~= L10N.NullString then
            table.insert(tbReduceDamageDesc, l10nReduceDamageDesc)
        end
    end
    NewTemplate.tbReduceDamageDesc = tbReduceDamageDesc
end

local function ParseDamageReduceByDamageType(Parser, tbSubReduce, nDamageType)
    local bResult = false
    local szDamageTypeKey = "reduce_damage_" .. nDamageType
    local nConfigValue = Parser:Get(szDamageTypeKey, -1, Parser.TypeFloat, false)
    if nConfigValue == -1 then
        for k, v in pairs(HumanBodyDef) do
            local szBodyTypeKey = szDamageTypeKey .. "_" .. v
            nConfigValue = Parser:Get(szBodyTypeKey, -1, Parser.TypeFloat, true)
            if nConfigValue == -1 then
                bResult = false
                break
            else
                -- logdebug("ParseDamageReduceByDamageType bodytype", nDamageType, v,nConfigValue)
                tbSubReduce[v] = nConfigValue
                bResult = true
            end
        end
    else
        -- logdebug("ParseDamageReduceByDamageType damagetype", nDamageType, nConfigValue)
        for k, v in pairs(HumanBodyDef) do
            tbSubReduce[v] = nConfigValue
        end
        bResult = true
    end
    return bResult
end

local function ParseDamageReduce(Parser)
    local tbDamageReduce = {}
    for k, nDamageType in pairs(HumanWeaponDamageType) do
        local tbSubReduce = tbDamageReduce[nDamageType]
        if not tbSubReduce then
            tbDamageReduce[nDamageType] = {}
            tbSubReduce = tbDamageReduce[nDamageType]
        end
        local bResult = ParseDamageReduceByDamageType(Parser, tbSubReduce, nDamageType)
        if not bResult then
            error(string.format("HumanArmorDataTableHelper, ParseDamageReduce error, damage type: %d does not have config", nDamageType))
            break
        end
    end
    return tbDamageReduce
end

function HumanArmorDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nDurability                         = Parser:Get("durable"                      , 1      , Parser.TypeInt)
    NewTemplate.nAvatarId                           = Parser:Get("avatar_id"                    , -1     , Parser.TypeInt)
    NewTemplate.bDestroyedOnZeroDurability          = Parser:Get("destroy_on_zero_durability"   , true   , Parser.TypeBool)
    if GlobalVariableSystem.bUseNewBattleItem then
        NewTemplate.nArmorType                          = Parser:Get("armor_type"                   ,-1      , Parser.TypeInt)
        NewTemplate.nArmorCategory                      = Parser:Get("armor_category_new"           , 1      , Parser.TypeInt)
        NewTemplate.tbBuffIds                           = Parser:Get("buff_ids"                     , {}     , Parser.TypeArrayInt)
        NewTemplate.tbDamageReduce = ParseDamageReduce(Parser)
    else
        NewTemplate.nArmorCategory                      = Parser:Get("armor_category"               , 1      , Parser.TypeInt)
        NewTemplate.nReduceHeadDamage                   = Parser:Get("reduce_head_damage"           , 0.0    , Parser.TypeFloat)
        NewTemplate.nReduceBodyDamage                   = Parser:Get("reduce_body_damage"           , 0.0    , Parser.TypeFloat)
    end
    NewTemplate.l10nGeneralDesc = Parser:Get("general_desc", L10N.NullString, Parser.TypeL10N)
    ParseSpecialDesc(Parser, NewTemplate)
    ParseReduceDamageDesc(Parser, NewTemplate)
end

return HumanArmorDataTableHelper