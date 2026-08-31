local HumanWeaponPropertyDescKeyParser = {}

local L10N                              = require("L10N")
local UISetUtils                        = require("UISetUtils")
local HumanWeaponDef                    = require("HumanWeaponDef")
local HumanWeaponDefaultDataTable       = require("HumanWeaponDefaultDataTable")
local BattleItemDataTable               = require("BattleItemDataTable")
local LobbyWeaponMiscDataTable          = require("LobbyWeaponMiscDataTable")
local DescKeyParserMiscDef              = require("DescKeyParserMiscDef")
local LobbyCaptainMiscDef               = require("LobbyCaptainMiscDef")
local LobbyCaptainMiscIni               = require("LobbyCaptainMiscIni")

local RecoilLevel = HumanWeaponDef.RecoilLevel
local MeleeAttackSpeedLevel = HumanWeaponDef.MeleeAttackSpeedLevel

local NAME_SPACE_HUMAN_WEAPON = DescKeyParserMiscDef.NAME_SPACE_HUMAN_WEAPON

local tbRecoilLevelNames = {
    [RecoilLevel.Very_Strong]   = UISetUtils.GetL10NTextByKey("HUMAN_WEAPON_RECOIL_LEVEL_VERY_STRONG"),
    [RecoilLevel.Strong]        = UISetUtils.GetL10NTextByKey("HUMAN_WEAPON_RECOIL_LEVEL_STRONG"),
    [RecoilLevel.Normal]        = UISetUtils.GetL10NTextByKey("HUMAN_WEAPON_RECOIL_LEVEL_NORMAL"),
    [RecoilLevel.Weak]          = UISetUtils.GetL10NTextByKey("HUMAN_WEAPON_RECOIL_LEVEL_WEAK"),
    [RecoilLevel.Very_Weak]     = UISetUtils.GetL10NTextByKey("HUMAN_WEAPON_RECOIL_LEVEL_VERY_WEAK"),
}

local tbMeleeAttackSpeedLevelNames = {
    [MeleeAttackSpeedLevel.Very_Fast]   = UISetUtils.GetL10NTextByKey("MELEE_ATTACK_SPEED_LEVEL_VERY_FAST"),
    [MeleeAttackSpeedLevel.Fast]        = UISetUtils.GetL10NTextByKey("MELEE_ATTACK_SPEED_LEVEL_FAST"),
    [MeleeAttackSpeedLevel.Normal]      = UISetUtils.GetL10NTextByKey("MELEE_ATTACK_SPEED_LEVEL_NORMAL"),
    [MeleeAttackSpeedLevel.Slow]        = UISetUtils.GetL10NTextByKey("MELEE_ATTACK_SPEED_LEVEL_SLOW"),
    [MeleeAttackSpeedLevel.Very_Slow]   = UISetUtils.GetL10NTextByKey("MELEE_ATTACK_SPEED_LEVEL_VERY_SLOW"),
}


local ALL_LEVELS_DESC                                           = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_NO_FORMAT_ALL_LEVELS_DESC")
--伤害
local WEAPON_DAMAGE_TITLE                                       = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_DAMAGE_TITLE")                 -- 伤害
local WEAPON_DAMAGE_DESC                                        = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_DAMAGE_DESC")                  -- {0}
-- local WEAPON_DAMAGE_ALL_LEVELS_DESC                             = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_DAMAGE_ALL_LEVELS_DESC")                  -- {0}

--射击次数-
local WEAPON_BULLET_MAX_TITLE                                   = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_BULLET_MAX_TITLE")                 -- 子弹容量
local WEAPON_BULLET_MAX_DESC                                    = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_BULLET_MAX_DESC")                  -- {0}发
-- local WEAPON_BULLET_MAX_ALL_LEVELS_DESC                         = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_BULLET_MAX_ALL_LEVELS_DESC")                  -- {0}发

--装填时间-
local WEAPON_RELOAD_TIME_TITLE                                  = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_RELOAD_TIME_TITLE")                -- 装填时间
local WEAPON_RELOAD_TIME_DESC                                   = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_RELOAD_TIME_DESC")                 -- {0}秒
-- local WEAPON_RELOAD_TIME_ALL_LEVELS_DESC                        = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_RELOAD_TIME_ALL_LEVELS_DESC")                 -- {0}秒

--弹速-
local WEAPON_INITIAL_SPEED_TITLE                                = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_INITIAL_SPEED_TITLE")              -- 弹速
local WEAPON_INITIAL_SPEED_DESC                                 = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_INITIAL_SPEED_DESC")               -- {0}米/秒
-- local WEAPON_INITIAL_SPEED_ALL_LEVELS_DESC                      = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_INITIAL_SPEED_ALL_LEVELS_DESC")               -- {0}米/秒

--射速-
local WEAPON_RATE_OF_FIRE_TITLE                                 = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_RATE_OF_FIRE_TITLE")               -- 射速
local WEAPON_RATE_OF_FIRE_DESC                                  = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_RATE_OF_FIRE_DESC")                -- {0}发/分
-- local WEAPON_RATE_OF_FIRE_ALL_LEVELS_DESC                       = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_RATE_OF_FIRE_ALL_LEVELS_DESC")                -- {0}发/分


--后坐力
local WEAPON_RECOIL_LEVEL_TITLE                                 = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_RECOIL_LEVEL_TITLE")               -- 后坐力
local WEAPON_RECOIL_LEVEL_DESC                                  = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_RECOIL_LEVEL_DESC")               -- 后坐力
-- local WEAPON_RECOIL_LEVEL_ALL_LEVELS_DESC                       = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_RECOIL_LEVEL_ALL_LEVELS_DESC")               -- 后坐力

--伤害半径
local WEAPON_EFFECTIVE_RANGE_TITLE                              = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_EFFECTIVE_RANGE_TITLE")            -- 伤害半径
local WEAPON_EFFECTIVE_RANGE_DESC                               = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_EFFECTIVE_RANGE_DESC")             -- {0}米
-- local WEAPON_EFFECTIVE_RANGE_ALL_LEVELS_DESC                    = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_EFFECTIVE_RANGE_ALL_LEVELS_DESC")             -- {0}米


-- 挥动速度
local WEAPON_MELEE_ATTACK_SPEED_LEVEL_TITLE                     = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_MELEE_ATTACK_SPEED_LEVEL_TITLE")   -- 挥动速度
local WEAPON_MELEE_ATTACK_SPEED_LEVEL_DESC                      = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_MELEE_ATTACK_SPEED_LEVEL_DESC")   -- 挥动速度
-- local WEAPON_MELEE_ATTACK_SPEED_LEVEL_ALL_LEVELS_DESC           = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_MELEE_ATTACK_SPEED_LEVEL_ALL_LEVELS_DESC")   -- 挥动速度


-- 蓄力时间
local WEAPON_CHARGE_TIME_TITLE                                  = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_CHARGE_TIME_TITLE")
local WEAPON_CHARGE_TIME_DESC                                   = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_CHARGE_TIME_DESC")
-- local WEAPON_CHARGE_TIME_ALL_LEVELS_DESC                        = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_CHARGE_TIME_ALL_LEVELS_DESC")


-- 火球初速度
local WEAPON_FIRE_BALL_SPEED_TITLE                              = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_FIRE_BALL_SPEED_TITLE")
local WEAPON_FIRE_BALL_SPEED_DESC                               = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_FIRE_BALL_SPEED_DESC")
-- local WEAPON_FIRE_BALL_SPEED_ALL_LEVELS_DESC                    = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_FIRE_BALL_SPEED_ALL_LEVELS_DESC")

-- 火球爆炸范围
local WEAPON_FIRE_BALL_EXPLOSIVE_RANGE_TITLE                    = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_FIRE_BALL_EXPLOSIVE_RANGE_TITLE")
local WEAPON_FIRE_BALL_EXPLOSIVE_RANGE_DESC                     = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_FIRE_BALL_EXPLOSIVE_RANGE_DESC")
-- local WEAPON_FIRE_BALL_EXPLOSIVE_RANGE_ALL_LEVELS_DESC          = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_FIRE_BALL_EXPLOSIVE_RANGE_ALL_LEVELS_DESC")

-- 自动爆炸距离
local WEAPON_FIRE_BALL_AUTO_EXPLOSIVE_RANGE_TITLE               = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_FIRE_BALL_AUTO_EXPLOSIVE_RANGE_TITLE")
local WEAPON_FIRE_BALL_AUTO_EXPLOSIVE_RANGE_DESC                = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_FIRE_BALL_AUTO_EXPLOSIVE_RANGE_DESC")
-- local WEAPON_FIRE_BALL_AUTO_EXPLOSIVE_RANGE_ALL_LEVELS_DESC     = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_FIRE_BALL_AUTO_EXPLOSIVE_RANGE_ALL_LEVELS_DESC")



local function MakeOutDataInFormat(l10nKey, l10nValueFormat, ...)
    local tbOutData = {}
    tbOutData.l10nKey = l10nKey
    tbOutData.l10nValue = L10N:Format(l10nValueFormat, ...)
    return tbOutData
end

local function MakeOutData(l10nKey, l10nValue)
    local tbOutData = {}
    tbOutData.l10nKey = l10nKey
    tbOutData.l10nValue = l10nValue
    return tbOutData
end


local function GetDamageDescData(tbInputData)
    local nTemplateId = tbInputData.nItemTemplateId
    local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    local nDamage = tbTemplate.nDamagePerBullet
    local tbOutData = MakeOutDataInFormat(WEAPON_DAMAGE_TITLE, WEAPON_DAMAGE_DESC, nDamage)
    return tbOutData
end

local function GetTimesDescData(tbInputData)
    local nTemplateId = tbInputData.nItemTemplateId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    local nBulletMax = tbItemTemplate.nBulletMax
    local tbOutData = MakeOutDataInFormat(WEAPON_BULLET_MAX_TITLE, WEAPON_BULLET_MAX_DESC, nBulletMax)
    return tbOutData
end

local function GetSpeedOfBulletDescData(tbInputData)
    local nTemplateId = tbInputData.nItemTemplateId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    local nInitialSpeed = tbItemTemplate.nInitialSpeed // 100
    local tbOutData = MakeOutDataInFormat(WEAPON_INITIAL_SPEED_TITLE, WEAPON_INITIAL_SPEED_DESC, nInitialSpeed)
    return tbOutData
end

local function GetReloadTimeDescData(tbInputData)
    local nTemplateId = tbInputData.nItemTemplateId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    local nReloadTime = tbItemTemplate.nReloadTime
    local tbOutData = MakeOutDataInFormat(WEAPON_RELOAD_TIME_TITLE, WEAPON_RELOAD_TIME_DESC, nReloadTime)
    return tbOutData
end

local function GetRateOfFireDescData(tbInputData)
    local nTemplateId = tbInputData.nItemTemplateId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    local nBulletSpeed = tbItemTemplate.nBulletSpeed
    local tbOutData = MakeOutDataInFormat(WEAPON_RATE_OF_FIRE_TITLE, WEAPON_RATE_OF_FIRE_DESC, nBulletSpeed)
    return tbOutData
end


local function GetRecoilDescData(tbInputData)
    local nTemplateId = tbInputData.nItemTemplateId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    local nRecoilLevel = tbItemTemplate.nRecoilLevel
    local l10nDesc = tbRecoilLevelNames[nRecoilLevel]
    local tbOutData = MakeOutDataInFormat(WEAPON_RECOIL_LEVEL_TITLE, WEAPON_RECOIL_LEVEL_DESC, l10nDesc)
    return tbOutData
end

local function GetAttackRangeDescData(tbInputData)
    local nTemplateId = tbInputData.nItemTemplateId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    local nAttackRange = tbItemTemplate.nEffectiveRange
    local tbOutData = MakeOutDataInFormat(WEAPON_EFFECTIVE_RANGE_TITLE, WEAPON_EFFECTIVE_RANGE_DESC, nAttackRange)
    return tbOutData
end

local function GetMeleeAttackSpeedDescData(tbInputData)
    local nTemplateId = tbInputData.nItemTemplateId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    local nMeleeAttackSpeedLevel = tbItemTemplate.nMeleeAttackSpeedLevel
    local l10nDesc = tbMeleeAttackSpeedLevelNames[nMeleeAttackSpeedLevel]
    local tbOutData = MakeOutDataInFormat(WEAPON_MELEE_ATTACK_SPEED_LEVEL_TITLE, WEAPON_MELEE_ATTACK_SPEED_LEVEL_DESC, l10nDesc)
    return tbOutData
end

local function GetChargeTimeDescData(tbInputData)
    local nTemplateId = tbInputData.nItemTemplateId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    local nReloadTime = tbItemTemplate.nReloadTime
    local tbOutData = MakeOutDataInFormat(WEAPON_CHARGE_TIME_TITLE, WEAPON_CHARGE_TIME_DESC, nReloadTime)
    return tbOutData
end

local function GetFireBallSpeedDescData(tbInputData)
    local nTemplateId = tbInputData.nItemTemplateId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    local nInitialSpeed = tbItemTemplate.nInitialSpeed // 100
    local tbOutData = MakeOutDataInFormat(WEAPON_FIRE_BALL_SPEED_TITLE, WEAPON_FIRE_BALL_SPEED_DESC, nInitialSpeed)
    return tbOutData
end

local function GetFireBallExplosiveRangeDescData(tbInputData)
    local nTemplateId = tbInputData.nItemTemplateId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    local nFireballExplosiveOutsideRadius = tbItemTemplate.nFireballExplosiveOutsideRadius
    local tbOutData = MakeOutDataInFormat(WEAPON_FIRE_BALL_EXPLOSIVE_RANGE_TITLE, WEAPON_FIRE_BALL_EXPLOSIVE_RANGE_DESC, nFireballExplosiveOutsideRadius)
    return tbOutData
end

local function GetFireBallAutoExplosiveRangeDescData(tbInputData)
    local nTemplateId = tbInputData.nItemTemplateId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    local nAttackRange = tbItemTemplate.nEffectiveRange
    local tbOutData = MakeOutDataInFormat(WEAPON_FIRE_BALL_AUTO_EXPLOSIVE_RANGE_TITLE, WEAPON_FIRE_BALL_AUTO_EXPLOSIVE_RANGE_DESC, nAttackRange)
    return tbOutData
end

local function GetHumanWeaponDefaultData(nInstanceType)
    local tbData = HumanWeaponDefaultDataTable:GetAllLevelData(nInstanceType)
    return tbData
end

local function IsValueDiffAmongALLLevels(tbWeaponData, szPropertKey)
    local bDiff = false
    for nLevel = 1, HumanWeaponDef.MAX_LEVEL - 1 do
        local tbLvData = tbWeaponData[nLevel]
        local tbNextLvData = tbWeaponData[nLevel + 1]
        if tbLvData and tbNextLvData then
            bDiff = (tbLvData[szPropertKey] ~= tbNextLvData[szPropertKey])
            if bDiff then
                break
            end
        end
    end
    return bDiff
end

local function GetAllLevelsDesc(tbWeaponData, szPropertKey, bUseAllLevelsData, fnDataPostProcessor)
    if bUseAllLevelsData then
        local tbArgs = {}
        for nLevel = 1, HumanWeaponDef.MAX_LEVEL do
            local tbLvData = tbWeaponData[nLevel]
            local tbData = tbLvData[szPropertKey]
            if fnDataPostProcessor then
                tbData = fnDataPostProcessor(tbData)
            end
            table.insert(tbArgs, tbData)
        end
        return L10N:FormatFromTable(ALL_LEVELS_DESC, tbArgs)
    else
        local tbLvData = tbWeaponData[1]
        if not tbLvData then
            return {}
        end
        local tbData = tbLvData[szPropertKey]
        if fnDataPostProcessor then
            tbData = fnDataPostProcessor(tbData)
        end
        return tbData
    end
end

local function GetAllLevelsDamageDescData(tbInputData)
    local szPropertKey = "nDamagePerBullet"
    local nInstanceType = tbInputData.nIntanceType
    if nInstanceType == LobbyCaptainMiscDef.UnarmedWeaponInstanceType then
        local tbOutData = MakeOutDataInFormat(WEAPON_DAMAGE_TITLE, WEAPON_DAMAGE_DESC, LobbyCaptainMiscIni.nEmptyHandDamage)
        return tbOutData
    else
        local tbWeaponData = GetHumanWeaponDefaultData(nInstanceType)
        local bDiff = IsValueDiffAmongALLLevels(tbWeaponData, szPropertKey)
        local tbDesc = GetAllLevelsDesc(tbWeaponData, szPropertKey, bDiff)
        local tbOutData = MakeOutDataInFormat(WEAPON_DAMAGE_TITLE, WEAPON_DAMAGE_DESC, tbDesc)
        return tbOutData
    end
end



local function GetAllLevelsTimesDescData(tbInputData)
    local szPropertKey = "nBulletMax"
    local nInstanceType = tbInputData.nIntanceType
    local tbWeaponData = GetHumanWeaponDefaultData(nInstanceType)
    local bDiff = IsValueDiffAmongALLLevels(tbWeaponData, szPropertKey)
    local tbDesc = GetAllLevelsDesc(tbWeaponData, szPropertKey, bDiff)
    local tbOutData = MakeOutDataInFormat(WEAPON_BULLET_MAX_TITLE, WEAPON_BULLET_MAX_DESC, tbDesc)
    return tbOutData
end

local function GetAllLevelsSpeedOfBulletDescData(tbInputData)
    local szPropertKey = "nInitialSpeed"
    local nInstanceType = tbInputData.nIntanceType
    local tbWeaponData = GetHumanWeaponDefaultData(nInstanceType)
    local bDiff = IsValueDiffAmongALLLevels(tbWeaponData, szPropertKey)
    local tbDesc = GetAllLevelsDesc(tbWeaponData, szPropertKey, bDiff, function (nData) return nData // 100 end)
    local tbOutData = MakeOutDataInFormat(WEAPON_INITIAL_SPEED_TITLE, WEAPON_INITIAL_SPEED_DESC, tbDesc)
    return tbOutData
end

local function GetAllLevelsReloadTimeDescData(tbInputData)
    local szPropertKey = "nReloadTime"
    local nInstanceType = tbInputData.nIntanceType
    local tbWeaponData = GetHumanWeaponDefaultData(nInstanceType)
    local bDiff = IsValueDiffAmongALLLevels(tbWeaponData, szPropertKey)
    local tbDesc = GetAllLevelsDesc(tbWeaponData, szPropertKey, bDiff)
    local tbOutData = MakeOutDataInFormat(WEAPON_RELOAD_TIME_TITLE, WEAPON_RELOAD_TIME_DESC, tbDesc)
    return tbOutData
end

local function GetAllLevelsRateOfFireDescData(tbInputData)
    local szPropertKey = "nBulletSpeed"
    local nInstanceType = tbInputData.nIntanceType
    local tbWeaponData = GetHumanWeaponDefaultData(nInstanceType)
    local bDiff = IsValueDiffAmongALLLevels(tbWeaponData, szPropertKey)
    local tbDesc = GetAllLevelsDesc(tbWeaponData, szPropertKey, bDiff)
    local tbOutData = MakeOutDataInFormat(WEAPON_RATE_OF_FIRE_TITLE, WEAPON_RATE_OF_FIRE_DESC, tbDesc)
    return tbOutData
end

local function GetAllLevelsRecoilDescData(tbInputData)
    local szPropertKey = "nRecoilLevel"
    local nInstanceType = tbInputData.nIntanceType
    local tbWeaponData = GetHumanWeaponDefaultData(nInstanceType)
    local bDiff = IsValueDiffAmongALLLevels(tbWeaponData, szPropertKey)
    local tbDesc = GetAllLevelsDesc(tbWeaponData, szPropertKey, bDiff, function (nRecoilLevel) return tbRecoilLevelNames[nRecoilLevel] end)
    local tbOutData = MakeOutDataInFormat(WEAPON_RECOIL_LEVEL_TITLE, WEAPON_RECOIL_LEVEL_DESC, tbDesc)
    return tbOutData
end

local function GetAllLevelsAttackRangeDescData(tbInputData)
    local szPropertKey = "nEffectiveRange"
    local nInstanceType = tbInputData.nIntanceType
    if nInstanceType == LobbyCaptainMiscDef.UnarmedWeaponInstanceType then
        local tbOutData = MakeOutDataInFormat(WEAPON_EFFECTIVE_RANGE_TITLE, WEAPON_EFFECTIVE_RANGE_DESC, LobbyCaptainMiscIni.nEmptyHandRange)
        return tbOutData
    else
        local tbWeaponData = GetHumanWeaponDefaultData(nInstanceType)
        local bDiff = IsValueDiffAmongALLLevels(tbWeaponData, szPropertKey)
        local tbDesc = GetAllLevelsDesc(tbWeaponData, szPropertKey, bDiff)
        local tbOutData = MakeOutDataInFormat(WEAPON_EFFECTIVE_RANGE_TITLE, WEAPON_EFFECTIVE_RANGE_DESC, tbDesc)
        return tbOutData
    end
end

local function GetAllLevelsMeleeAttackSpeedDescData(tbInputData)
    local szPropertKey = "nMeleeAttackSpeedLevel"
    local nInstanceType = tbInputData.nIntanceType
    if nInstanceType == LobbyCaptainMiscDef.UnarmedWeaponInstanceType then
        local nLevel = LobbyCaptainMiscIni.nEmptyHandSpeedLevel
        local l10nDesc = tbMeleeAttackSpeedLevelNames[nLevel]
        local tbOutData = MakeOutDataInFormat(WEAPON_MELEE_ATTACK_SPEED_LEVEL_TITLE, WEAPON_MELEE_ATTACK_SPEED_LEVEL_DESC, l10nDesc)
        return tbOutData
    else
        local tbWeaponData = GetHumanWeaponDefaultData(nInstanceType)
        local bDiff = IsValueDiffAmongALLLevels(tbWeaponData, szPropertKey)
        local tbDesc = GetAllLevelsDesc(tbWeaponData, szPropertKey, bDiff, function(nMeleeAttackSpeedLevel) return tbMeleeAttackSpeedLevelNames[nMeleeAttackSpeedLevel] end)
        local tbOutData = MakeOutDataInFormat(WEAPON_MELEE_ATTACK_SPEED_LEVEL_TITLE, WEAPON_MELEE_ATTACK_SPEED_LEVEL_DESC, tbDesc)
        return tbOutData
    end
end

local function GetAllLevelsCharGetAllLevelsimeDescData(tbInputData)
    local szPropertKey = "nReloadTime"
    local nInstanceType = tbInputData.nIntanceType
    local tbWeaponData = GetHumanWeaponDefaultData(nInstanceType)
    local bDiff = IsValueDiffAmongALLLevels(tbWeaponData, szPropertKey)
    local tbDesc = GetAllLevelsDesc(tbWeaponData, szPropertKey, bDiff)
    local tbOutData = MakeOutDataInFormat(WEAPON_CHARGE_TIME_TITLE, WEAPON_CHARGE_TIME_DESC, tbDesc)
    return tbOutData
end

local function GetAllLevelsFireBallSpeedDescData(tbInputData)
    local szPropertKey = "nInitialSpeed"
    local nInstanceType = tbInputData.nIntanceType
    local tbWeaponData = GetHumanWeaponDefaultData(nInstanceType)
    local bDiff = IsValueDiffAmongALLLevels(tbWeaponData, szPropertKey)
    local tbDesc = GetAllLevelsDesc(tbWeaponData, szPropertKey, bDiff, function(nInitialSpeed) return nInitialSpeed // 100 end)
    local tbOutData = MakeOutDataInFormat(WEAPON_FIRE_BALL_SPEED_TITLE, WEAPON_FIRE_BALL_SPEED_DESC, tbDesc)
    return tbOutData
end

local function GetAllLevelsFireBallExplosiveRangeDescData(tbInputData)
    local szPropertKey = "nFireballExplosiveOutsideRadius"
    local nInstanceType = tbInputData.nIntanceType
    local tbWeaponData = GetHumanWeaponDefaultData(nInstanceType)
    local bDiff = IsValueDiffAmongALLLevels(tbWeaponData, szPropertKey)
    local tbDesc = GetAllLevelsDesc(tbWeaponData, szPropertKey, bDiff)
    local tbOutData = MakeOutDataInFormat(WEAPON_FIRE_BALL_EXPLOSIVE_RANGE_TITLE, WEAPON_FIRE_BALL_EXPLOSIVE_RANGE_DESC, tbDesc)
    return tbOutData
end

local function GetAllLevelsFireBallAutoExplosiveRangeDescData(tbInputData)
    local szPropertKey = "nEffectiveRange"
    local nInstanceType = tbInputData.nIntanceType
    local tbWeaponData = GetHumanWeaponDefaultData(nInstanceType)
    local bDiff = IsValueDiffAmongALLLevels(tbWeaponData, szPropertKey)
    local tbDesc = GetAllLevelsDesc(tbWeaponData, szPropertKey, bDiff)
    local tbOutData = MakeOutDataInFormat(WEAPON_FIRE_BALL_AUTO_EXPLOSIVE_RANGE_TITLE, WEAPON_FIRE_BALL_AUTO_EXPLOSIVE_RANGE_DESC, tbDesc)
    return tbOutData
end

local function GetDungeonGeneralDesc(tbInputData)
    local nTemplateId = tbInputData.nItemTemplateId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    return MakeOutData(tbItemTemplate.l10nGeneralDesc, nil)
end

local function GetLobbyGeneralDesc(tbInputData)
    local nInstanceType = tbInputData.nIntanceType
    local tbTemplate = LobbyWeaponMiscDataTable:GetTemplate(nInstanceType)
    if not tbTemplate then
        logerror("HumanWeaponPropertyDescKeyParser, GetLobbyGeneralDesc error, nInstanceType : ", nInstanceType)
        return
    end
    return MakeOutData(tbTemplate.l10nGeneralDesc, nil)
end

local function GetDungenSpecialDesc(tbInputData)
    local nTemplateId = tbInputData.nItemTemplateId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    return MakeOutData(tbItemTemplate.l10nSpecialDesc, nil)
end

local function GetLobbySpecialDesc(tbInputData)
    local nInstanceType = tbInputData.nIntanceType
    local tbTemplate = LobbyWeaponMiscDataTable:GetTemplate(nInstanceType)
    if not tbTemplate then
        logerror("HumanWeaponPropertyDescKeyParser, GetLobbySpecialDesc error, nInstanceType : ", nInstanceType)
        return
    end
    return MakeOutData(tbTemplate.l10nSpecialDesc, nil)
end



function HumanWeaponPropertyDescKeyParser.Init(fnDefine)
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "lobby_general_desc",                              GetLobbyGeneralDesc)                                  --副本外总体概述
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "lobby_special_desc",                              GetLobbySpecialDesc)                                  --副本外特性描述

    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "dungeon_general_desc",                            GetDungeonGeneralDesc)                                --副本内总体概述
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "dungeon_special_desc",                            GetDungenSpecialDesc)                                 --副本内特性描述


    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "damage",                                          GetDamageDescData)                                  --伤害
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "attack_times",                                    GetTimesDescData)                                   --射击次数
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "speed_of_bullet",                                 GetSpeedOfBulletDescData)                           --弹速
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "reload_time",                                     GetReloadTimeDescData)                              --装填时间
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "rate_of_fire",                                    GetRateOfFireDescData)                              --射速
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "recoil",                                          GetRecoilDescData)                                  --后坐力
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "attack_range",                                    GetAttackRangeDescData)                             --攻击范围
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "melee_attack_speed",                              GetMeleeAttackSpeedDescData)                        --近战挥动速度
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "charge_time",                                     GetChargeTimeDescData)                              --火球蓄力时间
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "fire_ball_speed",                                 GetFireBallSpeedDescData)                           --火球初速度
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "fire_ball_explosive_range",                       GetFireBallExplosiveRangeDescData)                  --火球爆炸范围
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "fire_ball_auto_explosive_range",                  GetFireBallAutoExplosiveRangeDescData)              --火球自动爆炸距离

    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "damage_all_levels",                               GetAllLevelsDamageDescData)                          --伤害
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "attack_times_all_levels",                         GetAllLevelsTimesDescData)                           --射击次数
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "speed_of_bullet_all_levels",                      GetAllLevelsSpeedOfBulletDescData)                   --弹速
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "reload_time_all_levels",                          GetAllLevelsReloadTimeDescData)                      --装填时间
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "rate_of_fire_all_levels",                         GetAllLevelsRateOfFireDescData)                      --射速
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "recoil_all_levels",                               GetAllLevelsRecoilDescData)                          --后坐力
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "attack_range_all_levels",                         GetAllLevelsAttackRangeDescData)                     --攻击范围
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "melee_attack_speed_all_levels",                   GetAllLevelsMeleeAttackSpeedDescData)                --近战挥动速度
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "charge_time_all_levels",                          GetAllLevelsCharGetAllLevelsimeDescData)             --火球蓄力时间
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "fire_ball_speed_all_levels",                      GetAllLevelsFireBallSpeedDescData)                   --火球初速度
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "fire_ball_explosive_range_all_levels",            GetAllLevelsFireBallExplosiveRangeDescData)          --火球爆炸范围
    fnDefine(NAME_SPACE_HUMAN_WEAPON,   "fire_ball_auto_explosive_range_all_levels",       GetAllLevelsFireBallAutoExplosiveRangeDescData)      --火球自动爆炸距离
end

return HumanWeaponPropertyDescKeyParser