
local BuildShipWeaponTipsContentHelper = {}

local UISetUtils = require("UISetUtils")
local L10N = require("L10N")

local BattleItemCategoryDef = require("BattleItemCategoryDef")
local ShipWeaponSubCategoryDef = require("ShipWeaponSubCategoryDef")
local BattleItemDataTable = require("BattleItemDataTable")
local ShipWeaponDeviationLevelDef = require("ShipWeaponDeviationLevelDef")

local WEAPON_TITLE                              = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_TITLE")                            -- {0}({})
local WEAPON_DAMAGE_TITLE                       = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_DAMAGE_TITLE")                     -- 伤害
local WEAPON_FIRING_RANGE_TITLE                 = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_FIRING_RANGE_TITLE")               -- 最大射程
local WEAPON_FIRING_RANGE_DESC                  = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_FIRING_RANGE_DESC")                -- {0}米
-- local WEAPON_PERFECT_FIRING_RANGE_TITLE         = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_PERFECT_FIRING_RANGE_TITLE")       -- 最佳射程:{0}-{1}
local WEAPON_FIRING_INTERVAL_TITLE              = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_FIRING_INTERVAL_TITLE")            -- 攻击间隔
local WEAPON_FIRING_INTERVAL_DESC               = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_FIRING_INTERVAL_DESC")             -- {0}秒
local WEAPON_LOADING_TIME_TITLE                 = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_LOADING_TIME_TITLE")               -- 装填时间
local WEAPON_LOADING_TIME_DESC                  = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_LOADING_TIME_DESC")                -- {0}秒
local WEAPON_ROTATION_RANGE_TITLE               = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_ROTATION_RANGE_TITLE")             -- 射界
local WEAPON_ROTATION_RANGE_DESC                = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_ROTATION_RANGE_DESC")              -- {0}度
local WEAPON_FIRING_ROUND_COUNT_TITLE           = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_FIRING_ROUND_COUNT_TITLE")         -- 开火轮数
local WEAPON_BULLET_SPEED_TITLE                 = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_BULLET_SPEED_TITLE")               -- 炮弹速度
local WEAPON_BULLET_SPEED_DESC                  = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_BULLET_SPEED_DESC")                -- {0}米/秒
local WEAPON_BURNING_PROB_TITLE                 = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_BURNING_PROB_TITLE")               -- 点火率
local WEAPON_BURNING_PROB_DESC                  = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_BURNING_PROB_DESC")                -- {0}%
local WEAPON_DEVIATION_LEVEL_TITLE              = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_DEVIATION_LEVEL_TITLE")            -- 散布
local NO_FORMAT_DESC                            = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_NO_FORMAT_DESC")                          -- {0}

-- local function FormatNumberOneDecimal(nNumber)
--     local nNumberRound = MathUtil.Round(nNumber * 10) / 10
--     local nNumberFloor = math.floor(nNumberRound)
--     local nNumberOneDecimal = tonumber(string.format("%.1f", nNumberRound))
--     if (nNumberOneDecimal - nNumberFloor) * 10 // 1 == 0 then
--         return nNumberFloor
--     end
--     return nNumberOneDecimal
-- end

local function FillData(tbDatas, szTitle, szDesc)
    table.insert(tbDatas, {szTitle = szTitle, szDesc = szDesc})
end

local function FillDamageData(tbDatas, tbItemTemplate)
    local szTitle = WEAPON_DAMAGE_TITLE
    local szDesc = L10N:Format(NO_FORMAT_DESC, tbItemTemplate.nBaseDamage)
    FillData(tbDatas, szTitle, szDesc)
end

local function FillFiringRangeDesc(tbDatas, tbItemTemplate)
    local szTitle = WEAPON_FIRING_RANGE_TITLE
    local szDesc = L10N:Format(WEAPON_FIRING_RANGE_DESC, math.floor(tbItemTemplate.nFiringRange / 100))
    FillData(tbDatas, szTitle, szDesc)
end

-- local function FillPerfectFiringRangeDesc(tbDatas, tbItemTemplate)
--     local szTitle = L10N:Format(WEAPON_PERFECT_FIRING_RANGE_TITLE, math.floor(tbItemTemplate.nPerfectFiringRangeBegin / 100), math.floor(tbItemTemplate.nPerfectFiringRangeEnd / 100))
--     local szDesc = nil
--     FillData(tbDatas, szTitle, szDesc)
-- end

local function FillFiringIntervalDesc(tbDatas, tbItemTemplate)
    local szTitle = WEAPON_FIRING_INTERVAL_TITLE
    local szDesc = L10N:Format(WEAPON_FIRING_INTERVAL_DESC, tbItemTemplate.nFiringInterval)
    FillData(tbDatas, szTitle, szDesc)
end

local function FillLoadingTimeDesc(tbDatas, tbItemTemplate)
    local szTitle = WEAPON_LOADING_TIME_TITLE
    local szDesc = L10N:Format(WEAPON_LOADING_TIME_DESC, tbItemTemplate.nLoadingTime)
    FillData(tbDatas, szTitle, szDesc)
end

local function FillRotationRangeDesc(tbDatas, tbItemTemplate)
    local szTitle = WEAPON_ROTATION_RANGE_TITLE
    local szDesc = L10N:Format(WEAPON_ROTATION_RANGE_DESC, tbItemTemplate.nRotationRange)
    FillData(tbDatas, szTitle, szDesc)
end

local function FillBurningProbDesc(tbDatas, tbItemTemplate)
    local szTitle = WEAPON_BURNING_PROB_TITLE
    local nBurningProb = tbItemTemplate.nBurningProb
    local szDesc = nBurningProb
    if nBurningProb > 0 then
        szDesc = L10N:Format(WEAPON_BURNING_PROB_DESC, nBurningProb * 100)
    end

    FillData(tbDatas, szTitle, szDesc)
end

local function FillDeviationLevelDesc(tbDatas, tbItemTemplate)
    local szTitle = WEAPON_DEVIATION_LEVEL_TITLE
    local nDisplayDeviationLevel = tbItemTemplate.nDisplayDeviationLevel
    local szDesc = ShipWeaponDeviationLevelDef:GetLevelName(nDisplayDeviationLevel)
    FillData(tbDatas, szTitle, szDesc)
end

local function FillFiringRoundCountDesc(tbDatas, tbItemTemplate)
    local szTitle = WEAPON_FIRING_ROUND_COUNT_TITLE
    local szDesc = L10N:Format(NO_FORMAT_DESC, tbItemTemplate.nFiringRoundCount)
    FillData(tbDatas, szTitle, szDesc)
end

local function FillBulletSpeedDesc(tbDatas, tbItemTemplate)
    local szTitle = WEAPON_BULLET_SPEED_TITLE
    local szDesc = L10N:Format(WEAPON_BULLET_SPEED_DESC, tbItemTemplate.nBulletSpeed // 100)
    FillData(tbDatas, szTitle, szDesc)
end

local function FillSmallCannonTipsData(tbDatas, tbItemTemplate)
    FillDamageData(tbDatas, tbItemTemplate)
    FillFiringRangeDesc(tbDatas, tbItemTemplate)
    FillFiringIntervalDesc(tbDatas, tbItemTemplate)
    FillLoadingTimeDesc(tbDatas, tbItemTemplate)
    FillRotationRangeDesc(tbDatas, tbItemTemplate)
    FillFiringRoundCountDesc(tbDatas, tbItemTemplate)
    FillBulletSpeedDesc(tbDatas, tbItemTemplate)
    FillBurningProbDesc(tbDatas, tbItemTemplate)
    FillDeviationLevelDesc(tbDatas, tbItemTemplate)
    -- FillPerfectFiringRangeDesc(tbDatas, tbItemTemplate)
end

local function FillSakerTipsData(tbDatas, tbItemTemplate)
    FillSmallCannonTipsData(tbDatas, tbItemTemplate)
end

local function FillDartleTipsData(tbDatas, tbItemTemplate)
    FillSmallCannonTipsData(tbDatas, tbItemTemplate)
end

local function FillAssaultGunTipsData(tbDatas, tbItemTemplate)
    FillSmallCannonTipsData(tbDatas, tbItemTemplate)
end

local function FillSnipeGunTipsData(tbDatas, tbItemTemplate)
    FillSmallCannonTipsData(tbDatas, tbItemTemplate)
end

local function FillSternCannonTipsData(tbDatas, tbItemTemplate)
    FillDamageData(tbDatas, tbItemTemplate)
    FillFiringRangeDesc(tbDatas, tbItemTemplate)
    FillFiringIntervalDesc(tbDatas, tbItemTemplate)
    FillLoadingTimeDesc(tbDatas, tbItemTemplate)
    FillRotationRangeDesc(tbDatas, tbItemTemplate)
    FillFiringRoundCountDesc(tbDatas, tbItemTemplate)
    FillBulletSpeedDesc(tbDatas, tbItemTemplate)
    FillBurningProbDesc(tbDatas, tbItemTemplate)
    FillDeviationLevelDesc(tbDatas, tbItemTemplate)
    -- FillPerfectFiringRangeDesc(tbDatas, tbItemTemplate)
end

local function GetTitle(tbItemTemplate)
    local l10nCategoryName = BattleItemDataTable:GetSubCategoryName(tbItemTemplate.nCategory, tbItemTemplate.nSubCategory)
    return L10N:Format(WEAPON_TITLE, tbItemTemplate.l10nName, l10nCategoryName)
end

local function GetDesc(tbItemTemplate)
    return tbItemTemplate.l10nDesc
end

local function FillShipWeaponTipsData(tbTipsData, tbItemTemplate)
    local tbDatas = {}
    tbTipsData.tbDatas = tbDatas

    tbTipsData.szTitle = GetTitle(tbItemTemplate)
    tbTipsData.nDamage = tbItemTemplate.nBaseDamage
    tbTipsData.szDesc = GetDesc(tbItemTemplate)

    local nSubCategory = tbItemTemplate.nSubCategory
    if nSubCategory == ShipWeaponSubCategoryDef.SMALL_CANNON then           -- 小钢炮，回旋炮
        FillSmallCannonTipsData(tbDatas, tbItemTemplate)
    elseif nSubCategory == ShipWeaponSubCategoryDef.SAKER then              -- 喷子，霰弹炮
        FillSakerTipsData(tbDatas, tbItemTemplate)
    elseif nSubCategory == ShipWeaponSubCategoryDef.DARTLE then             -- 连射，轮转炮
        FillDartleTipsData(tbDatas, tbItemTemplate)
    elseif nSubCategory == ShipWeaponSubCategoryDef.ASSAULT_GUN then        -- 突击，加农炮
        FillAssaultGunTipsData(tbDatas, tbItemTemplate)
    elseif nSubCategory == ShipWeaponSubCategoryDef.SNIPE_GUN then          -- 狙击，曲射炮
        FillSnipeGunTipsData(tbDatas, tbItemTemplate)
    elseif nSubCategory == ShipWeaponSubCategoryDef.STERN_CANNON then       -- 船尾炮
        FillSternCannonTipsData(tbDatas, tbItemTemplate)
    end
end

-- tbTipsData.szTitle
-- tbTipsData.tbDatas
-- tbTipsData.nDamage
-- tbTipsData.szDesc
-- tbTipsData.tbCharacteristics
-- table.insert(tbTipsData.tbDatas, {szTitle = "", szDesc = ""})
function BuildShipWeaponTipsContentHelper.GetTipsData(nItemTemplateId)
    local tbTipsData = {}
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    assert(nCategory == BattleItemCategoryDef.SHIP_WEAPON, "error! category not ship weapon!".. nItemTemplateId)
    FillShipWeaponTipsData(tbTipsData, tbItemTemplate)
    tbTipsData.tbCharacteristics = tbItemTemplate.tbCharacteristics
    return tbTipsData
end

return BuildShipWeaponTipsContentHelper
