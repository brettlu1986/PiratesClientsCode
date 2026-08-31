local luaclass = require("luaclass")
local ShipDataDisplayHelper = luaclass("ShipDataDisplayHelper")

local MathUtil = require("MathUtil")
local UITextDef = require("UITextDef")
local UISetUtils = require("UISetUtils")
local ShipDataTable = require("ShipDataTable")
local ShipMovementDef = require("ShipMovementDef")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local ShipRegionTypeDef = require("ShipRegionTypeDef")
local ShipGearDataTable = require("ShipGearDataTable")
local ShipSkillDataTable = require("ShipSkillDataTable")
local ShipDataDisplayIni = require("ShipDataDisplayIni")
local ShipScoreContainer = require("ShipScoreContainer")
local BattleItemDataTable = require("BattleItemDataTable")
local ShipUtilityExHelper = require("ShipUtilityExHelper")
local ShipArmorDataTableEx = require("ShipArmorDataTableEx")
local ShipWeaponTemplateDef = require("ShipWeaponTemplateDef")

ShipDataDisplayHelper.tbShipTemplate = nil

-- local DISPLAY_CATEGORY_COUNT = 7

local DISPLAY_CATEGORY = {
    VITALITY = 1,           -- 生存能力
    FIRE_POWER = 2,         -- 整体火力
    MOVEMENT = 3,           -- 机动能力
    CONCEAL = 4,            -- 隐蔽能力
}
ShipDataDisplayHelper.DISPLAY_CATEGORY = DISPLAY_CATEGORY

local DEFAULT_VALID_WEAPON_SLOT_LEVELS = {1,2,3}

local PROP_NAME_HP                          = UISetUtils.GetL10NTextByKey("FFA_UI_SHIP_TIPS_HP")                            -- 血量
local PROP_NAME_SHIP_HEAD_DAMAGE_RATIO      = UISetUtils.GetL10NTextByKey("FFA_UI_SHIP_TIPS_SHIP_HEAD_DAMAGE_RATIO")        -- 船头减伤
local PROP_NAME_SHIP_SIDE_DAMAGE_RATIO      = UISetUtils.GetL10NTextByKey("FFA_UI_SHIP_TIPS_SHIP_SIDE_DAMAGE_RATIO")        -- 船身减伤
local PROP_NAME_SHIP_STERN_DAMAGE_RATIO     = UISetUtils.GetL10NTextByKey("FFA_UI_SHIP_TIPS_SHIP_STERN_DAMAGE_RATIO")       -- 船尾减伤
local PROP_NAME_SHIP_DECK_DAMAGE_RATIO      = UISetUtils.GetL10NTextByKey("FFA_UI_SHIP_TIPS_SHIP_DECK_DAMAGE_RATIO")        -- 甲板减伤
local PROP_NAME_SHIP_CORE_DAMAGE_RATIO      = UISetUtils.GetL10NTextByKey("FFA_UI_SHIP_TIPS_SHIP_CORE_DAMAGE_RATIO")        -- 核心区受伤系数
local PROP_NAME_SHIP_VISIBLE_DISTANCE       = UISetUtils.GetL10NTextByKey("FFA_UI_SHIP_TIPS_SHIP_VISIBLE_DISTANCE")         -- 隐蔽性
local PROP_NAME_MAX_LINER_SPEED             = UISetUtils.GetL10NTextByKey("FFA_UI_SHIP_TIPS_LINER_SPEED")                   -- 最大线速度
local PROP_NAME_MAX_ANGLE_SPEED             = UISetUtils.GetL10NTextByKey("FFA_UI_SHIP_TIPS_ANGLE_SPEED")                   -- 最大角速度
local PROP_NAME_MAX_LINEAR_ACCELERATION     = UISetUtils.GetL10NTextByKey("FFA_UI_SHIP_TIPS_LINEAR_ACCELERATION")           -- 线加速度
local PROP_NAME_MAX_LINEAR_DECELERATION     = UISetUtils.GetL10NTextByKey("FFA_UI_SHIP_TIPS_LINEAR_DECELERATION")           -- 线减速度
local PROP_NAME_MAX_ANGLE_ACCELERATION      = UISetUtils.GetL10NTextByKey("FFA_UI_SHIP_TIPS_ANGLE_ACCELERATION")            -- 角加速度
local PROP_NAME_MAX_ANGLE_DECELERATION      = UISetUtils.GetL10NTextByKey("FFA_UI_SHIP_TIPS_ANGLE_DECELERATION")            -- 角减速度
local PROP_NAME_HEAD_GUN_COUNT              = UISetUtils.GetL10NTextByKey("FFA_UI_SHIP_TIPS_HEAD_GUN_COUNT")                -- 船头炮数
local PROP_NAME_SIDE_GUN_COUNT              = UISetUtils.GetL10NTextByKey("FFA_UI_SHIP_TIPS_SIDE_GUN_COUNT")                -- 单侧炮数
local PROP_NAME_STERN_CANNON_COUNT          = UISetUtils.GetL10NTextByKey("FFA_UI_SHIP_TIPS_STERN_CANNON_COUNT")            -- 船尾炮数

local nVitalityFirstPartParam = ShipDataDisplayIni.tbVitality.nFirstPartParam
local nVitalitySecondPartParam = ShipDataDisplayIni.tbVitality.nSecondPartParam
local nVitalityThirdPartParam = ShipDataDisplayIni.tbVitality.nThirdPartParam
local nSecondPartHeadDamageWeight = ShipDataDisplayIni.tbVitality.nSecondPartHeadDamageWeight
local nSecondPartSideDamageWeight = ShipDataDisplayIni.tbVitality.nSecondPartSideDamageWeight
local nSecondPartSternDamageWeight = ShipDataDisplayIni.tbVitality.nSecondPartSternDamageWeight
local nSecondPartCoreDamageWeight = ShipDataDisplayIni.tbVitality.nSecondPartCoreDamageWeight
local nThirdPartSternDamageWeight = ShipDataDisplayIni.tbVitality.nThirdPartSternDamageWeight
local nThirdPartCoreDamageWeight = ShipDataDisplayIni.tbVitality.nThirdPartCoreDamageWeight

local nMaxLinerSpeedWeight = ShipDataDisplayIni.tbMovement.nMaxLinerSpeedWeight
local nMaxAngleSpeedWeight = ShipDataDisplayIni.tbMovement.nMaxAngleSpeedWeight
local nAngularAccelerationWeight = ShipDataDisplayIni.tbMovement.nAngularAccelerationWeight
local nLinearAccelerationWeight = ShipDataDisplayIni.tbMovement.nLinearAccelerationWeight

local nHeadGunCountWeight = ShipDataDisplayIni.tbHeadFirePower.nHeadGunCountWeight
local nSideGunCountWeight = ShipDataDisplayIni.tbSideFirePower.nSideGunCountWeight
local nSternCannonCountWeight = ShipDataDisplayIni.tbDeckFirePower.nSternCannonCountWeight

local nFinalScoreParam = ShipDataDisplayIni.tbFinalScore.nParam

local tbCategoryScoreCalculator = {
    -- 获得生存能力分数
    [DISPLAY_CATEGORY.VITALITY] = function(self)
        --[[
            生存能力=生命值*
            {1/3/船头受伤比例
            +1/3/（船头受伤比例*0.25+船身受伤比例*0.5+船尾受伤比例*0.125+核心区受伤比例*0.125）
            +1/3/（船尾受伤比例*0.5+核心区受伤比例*0.5）}
        ]]
        local nShipHp = self:GetHp()
        local nHeadDamageRatio = self:GetHeadDamageRatio()
        local nSideDamageRatio = self:GetSideDamageRatio()
        local nSternDamageRatio = self:GetSternDamageRatio()
        local nCoreDamageRatio = self:GetCoreDamageRatio()
        return nShipHp*
            (nVitalityFirstPartParam/nHeadDamageRatio
            +nVitalitySecondPartParam/(nHeadDamageRatio*nSecondPartHeadDamageWeight+nSideDamageRatio*nSecondPartSideDamageWeight+nSternDamageRatio*nSecondPartSternDamageWeight+nCoreDamageRatio*nSecondPartCoreDamageWeight)
            +nVitalityThirdPartParam/(nSternDamageRatio*nThirdPartSternDamageWeight+nCoreDamageRatio*nThirdPartCoreDamageWeight))
    end,

    -- 获得整体火力分数
    [DISPLAY_CATEGORY.FIRE_POWER] = function(self)
        --[[
            火力能力=船头炮数*0.25+侧舷炮数*0.5+船尾炮数*0.25
        ]]
        local nHeadGunCount = self:GetHeadGunCount()
        local nSideGunCount = self:GetSideGunCount()
        local nSternCannonCount = self:GetSternCannonCount()
        return nHeadGunCount * nHeadGunCountWeight + nSideGunCount * nSideGunCountWeight + nSternCannonCount * nSternCannonCountWeight
    end,

    -- 获得机动能力分数
    [DISPLAY_CATEGORY.MOVEMENT] = function(self)
        --[[
            机动能力=角速度*0.1+角加速度*0.1+直线速度*0.5+直线加速度*0.3
        ]]
        local nMaxLinerSpeed = self:GetMaxLinerSpeed()
        local nMaxAngleSpeed = self:GetMaxAngularSpeed()
        local nAngularAcceleration = self:GetAngularAcceleration()
        local nLinearAcceleration = self:GetLinearAcceleration()
        return nMaxAngleSpeed * nMaxAngleSpeedWeight + nAngularAcceleration * nAngularAccelerationWeight
             + nMaxLinerSpeed * nMaxLinerSpeedWeight + nLinearAcceleration * nLinearAccelerationWeight
    end,
    -- 获得隐蔽能力分数
    [DISPLAY_CATEGORY.CONCEAL] = function(self)
        --[[
            隐蔽能力=1/被发现距离
        ]]
        local nVisibleDistance = self:GetVisibleDistance()
        return 1/nVisibleDistance
    end,
}

local function GetFormattedLinerSpped(nSpeed)
    local nSpeedFloor = math.floor(nSpeed)
    if nSpeed - nSpeedFloor == 0 then
        return nSpeed
    else
        return string.format("%.2f", nSpeed)
    end
end

local function GetFormattedDamageReduceRatio(nRatio)
    return MathUtil.Round(nRatio * 100) .. "%"
end

local tbCategoryPropertiesGetter = {
    -- 获得生存能力相关属性
    [DISPLAY_CATEGORY.VITALITY] = function(self)
        local tbProperties = {}
        table.insert(tbProperties,{
            l10nPropName = PROP_NAME_HP,
            l10nPropValue = self:GetHp()
        })
        table.insert(tbProperties,{
            l10nPropName = PROP_NAME_SHIP_HEAD_DAMAGE_RATIO,
            l10nPropValue = GetFormattedDamageReduceRatio(self:GetHeadDamageReduceRatio())
        })
        table.insert(tbProperties,{
            l10nPropName = PROP_NAME_SHIP_SIDE_DAMAGE_RATIO,
            l10nPropValue = GetFormattedDamageReduceRatio(self:GetSideDamageReduceRatio())
        })
        table.insert(tbProperties,{
            l10nPropName = PROP_NAME_SHIP_STERN_DAMAGE_RATIO,
            l10nPropValue = GetFormattedDamageReduceRatio(self:GetSternDamageReduceRatio())
        })
        table.insert(tbProperties,{
            l10nPropName = PROP_NAME_SHIP_DECK_DAMAGE_RATIO,
            l10nPropValue = GetFormattedDamageReduceRatio(self:GetDeckDamageReduceRatio())
        })
        table.insert(tbProperties,{
            l10nPropName = PROP_NAME_SHIP_CORE_DAMAGE_RATIO,
            l10nPropValue = self:GetCoreDamageRatio()
        })
        return tbProperties
    end,

    -- 获得整体火力相关属性
    [DISPLAY_CATEGORY.FIRE_POWER] = function(self)
        local tbProperties = {}
        table.insert(tbProperties,{
            l10nPropName = PROP_NAME_HEAD_GUN_COUNT,
            l10nPropValue = self:GetHeadGunCount()
        })
        table.insert(tbProperties,{
            l10nPropName = PROP_NAME_SIDE_GUN_COUNT,
            l10nPropValue = self:GetSideGunCount()
        })
        table.insert(tbProperties,{
            l10nPropName = PROP_NAME_STERN_CANNON_COUNT,
            l10nPropValue = self:GetSternCannonCount()
        })
        return tbProperties
    end,

    -- 获得机动能力相关属性
    [DISPLAY_CATEGORY.MOVEMENT] = function(self)
        local tbProperties = {}
        table.insert(tbProperties,{
            l10nPropName = PROP_NAME_MAX_LINER_SPEED,
            l10nPropValue = GetFormattedLinerSpped(self:GetMaxLinerSpeed())
        })
        table.insert(tbProperties,{
            l10nPropName = PROP_NAME_MAX_LINEAR_ACCELERATION,
            l10nPropValue = GetFormattedLinerSpped(self:GetLinearAcceleration())
        })
        table.insert(tbProperties,{
            l10nPropName = PROP_NAME_MAX_LINEAR_DECELERATION,
            l10nPropValue = GetFormattedLinerSpped(self:GetLinearDeceleration())
        })
        table.insert(tbProperties,{
            l10nPropName = PROP_NAME_MAX_ANGLE_SPEED,
            l10nPropValue = self:GetMaxAngularSpeed()
        })
        table.insert(tbProperties,{
            l10nPropName = PROP_NAME_MAX_ANGLE_ACCELERATION,
            l10nPropValue = self:GetAngularAcceleration()
        })
        table.insert(tbProperties,{
            l10nPropName = PROP_NAME_MAX_ANGLE_DECELERATION,
            l10nPropValue = self:GetAngularDeceleration()
        })
        return tbProperties
    end,

    -- 获得隐蔽能力相关属性
    [DISPLAY_CATEGORY.CONCEAL] = function(self)
        local tbProperties = {}
        table.insert(tbProperties,{
            l10nPropName = PROP_NAME_SHIP_VISIBLE_DISTANCE,
            l10nPropValue = self:GetVisibleDistance()
        })
        return tbProperties
    end,
}

local function CalBaseScoreByCategory(self, nCategory)
    local nScore = 0
    local fnScoreCalculator = tbCategoryScoreCalculator[nCategory]
    if fnScoreCalculator then
        nScore = fnScoreCalculator(self)
    end
    return nScore
end

-- 获取暂时用各类别评分（0-1）
local function GetDisplayScoreByCategory(self, nCategory)
    return ShipScoreContainer:GetFinalScore(self.nShipItemTemplateId, nCategory)
end

-- 获取船速相关配置
local function GetGearTemplate(self)
    local nGearId = self.tbShipTemplate.nGearId
    return ShipGearDataTable:GetGear(nGearId, ShipMovementDef.ShipPostureDef.FullSail, ShipMovementDef.ShipGearDef.FullSpeed)
end

-- 获取受伤比例
local function GetDamageRadio(nArmorSuitId, nRegionType, bIsCore)
    local tbTemplates = ShipArmorDataTableEx:GetAllPartsForSuit(nArmorSuitId)
    for _, v in pairs(tbTemplates) do
        if v.nRegionType == nRegionType and (not v.bIsCoreRegion) and (not bIsCore) then
            return v.nDamageRatio
        elseif bIsCore and v.bIsCoreRegion then
            return v.nDamageRatio
        end
    end
    return 0
end

-- 获取伤害减免
local function GetDamageReduceRadio(nArmorSuitId, nRegionType, bIsCore)
    local tbTemplates = ShipArmorDataTableEx:GetAllPartsForSuit(nArmorSuitId)
    for _, v in pairs(tbTemplates) do
        if v.nRegionType == nRegionType and (not v.bIsCoreRegion) then
            local nDamageRatio = v.nDamageRatio
            local nDamageReduce = math.max(1 - nDamageRatio, 0)
            return  nDamageReduce
        end
    end
    return 0
end

-- 获取船对应的BPClass
local function GetShipClassPath(self)
    local tbShipResTemplate = self.tbShipTemplate.tbResData
    return tbShipResTemplate.szPawnClassName
end

-- 获取火炮数量
local function GetShipGunCount(self, nWeaponSlot, nTemplateType)
    local szShipClassPath = GetShipClassPath(self)
    local szControlClass = nil
    if nTemplateType then
        szControlClass = ShipWeaponTemplateDef.GetBPControlClassPath(nTemplateType)
    end
    return ShipUtilityExHelper.GetBulletMaxLoadingCount(szShipClassPath, szControlClass, nWeaponSlot, DEFAULT_VALID_WEAPON_SLOT_LEVELS)
end

-- 获得对应船的Template
function ShipDataDisplayHelper:GetTemplate()
    return self.tbShipTemplate
end

--[[
    生存能力
]]
-- 获得血量
function ShipDataDisplayHelper:GetHp()
    return self.tbShipTemplate.nHp
end

-- 获得船头减伤
function ShipDataDisplayHelper:GetHeadDamageReduceRatio()
    local nArmorSuitId = self.tbShipTemplate.nArmorSuitId
    return GetDamageReduceRadio(nArmorSuitId, ShipRegionTypeDef.HEAD)
end

-- 获得船身减伤
function ShipDataDisplayHelper:GetSideDamageReduceRatio()
    local nArmorSuitId = self.tbShipTemplate.nArmorSuitId
    return GetDamageReduceRadio(nArmorSuitId, ShipRegionTypeDef.SIDE)
end

-- 获得船尾减伤
function ShipDataDisplayHelper:GetSternDamageReduceRatio()
    local nArmorSuitId = self.tbShipTemplate.nArmorSuitId
    return GetDamageReduceRadio(nArmorSuitId, ShipRegionTypeDef.STERN)
end

-- 获得甲板减伤
function ShipDataDisplayHelper:GetDeckDamageReduceRatio()
    local nArmorSuitId = self.tbShipTemplate.nArmorSuitId
    return GetDamageReduceRadio(nArmorSuitId, ShipRegionTypeDef.DECK)
end

-- 获得船头受伤倍率
function ShipDataDisplayHelper:GetHeadDamageRatio()
    local nArmorSuitId = self.tbShipTemplate.nArmorSuitId
    return GetDamageRadio(nArmorSuitId, ShipRegionTypeDef.HEAD)
end

-- 获得船身受伤倍率
function ShipDataDisplayHelper:GetSideDamageRatio()
    local nArmorSuitId = self.tbShipTemplate.nArmorSuitId
    return GetDamageRadio(nArmorSuitId, ShipRegionTypeDef.SIDE)
end

-- 获得船尾受伤倍率
function ShipDataDisplayHelper:GetSternDamageRatio()
    local nArmorSuitId = self.tbShipTemplate.nArmorSuitId
    return GetDamageRadio(nArmorSuitId, ShipRegionTypeDef.STERN)
end

-- 获得甲板受伤倍率
function ShipDataDisplayHelper:GetDeckDamageRatio()
    local nArmorSuitId = self.tbShipTemplate.nArmorSuitId
    return GetDamageRadio(nArmorSuitId, ShipRegionTypeDef.DECK)
end

-- 获得核心区受伤倍率
function ShipDataDisplayHelper:GetCoreDamageRatio()
    local nArmorSuitId = self.tbShipTemplate.nArmorSuitId
    return GetDamageRadio(nArmorSuitId, nil, true)
end

-- 获得隐蔽性
function ShipDataDisplayHelper:GetVisibleDistance()
    return self.tbShipTemplate.nVisibleDistance
end

--[[
    机动能力
]]
-- 获得最大线速度
function ShipDataDisplayHelper:GetMaxLinerSpeed()
    return GetGearTemplate(self).nMaxLinearSpeed / 100
end

-- 获得线加速度
function ShipDataDisplayHelper:GetLinearAcceleration()
    return GetGearTemplate(self).nLinearAcceleration / 100
end

-- 获得线减速度
function ShipDataDisplayHelper:GetLinearDeceleration()
    return GetGearTemplate(self).nLinearDeceleration / 100
end

-- 获得最大角速度
function ShipDataDisplayHelper:GetMaxAngularSpeed()
    return GetGearTemplate(self).nMaxAngularSpeed
end

-- 获得角加速度
function ShipDataDisplayHelper:GetAngularAcceleration()
    return GetGearTemplate(self).nAngularAcceleration
end

-- 获得角减速度
function ShipDataDisplayHelper:GetAngularDeceleration()
    return GetGearTemplate(self).nAngularDeceleration
end

--[[
    船头火力
]]
-- 获得船头炮数量
function ShipDataDisplayHelper:GetHeadGunCount()
    return GetShipGunCount(self, ShipWeaponSlotDef.HEAD)
end

--[[
    侧舷火力
]]
-- 获得侧舷单侧炮数
function ShipDataDisplayHelper:GetSideGunCount()
    return GetShipGunCount(self, ShipWeaponSlotDef.SIDE)
end

-- 获得水雷数量
function ShipDataDisplayHelper:GetSternCannonCount()
    return GetShipGunCount(self, ShipWeaponSlotDef.DECK, ShipWeaponTemplateDef.CANNON)
end

-- 获得舰船特性描述
function ShipDataDisplayHelper:GetDescription()
    return self.tbShipTemplate.l10nDesc
end

--[[
    其他
]]
-- 获得舰船技能ID列表
function ShipDataDisplayHelper:GetShipSkillIds()
    local tbShipSkillTemplate = ShipSkillDataTable:GetTemplate(self.tbShipTemplate.nId)
    return tbShipSkillTemplate and tbShipSkillTemplate.tbFlagSkill or {}
end

function ShipDataDisplayHelper:GetDisplayDataGroup()
    local tbDatas = {}
    for _, i in pairs(DISPLAY_CATEGORY) do
        local fnCategoryPropertiesGetter = tbCategoryPropertiesGetter[i]
        tbDatas[i] = {
            nCategoryIndex = i,
            nScore = GetDisplayScoreByCategory(self, i),
            l10nCategoryName = UITextDef.SHIP_PROP_CATEGORY_TEXT[i],
            tbProperties = fnCategoryPropertiesGetter(self)
        }
    end
    return tbDatas
end

function ShipDataDisplayHelper:CalBaseScores()
    local tbDatas = {}
    for _, i in pairs(DISPLAY_CATEGORY) do
        tbDatas[i] = CalBaseScoreByCategory(self, i)
    end
    return tbDatas
end

--[[
    某项评分值=
    （（100-调节值）*船该项值+100*（所有船中该项最大值-所有船中该项最小值）+所有船中该项最大值*（调节值-100））/（所有船中该项最大值-所有船中该项最小值）
]]
function ShipDataDisplayHelper.CalScore(nBaseScore, nMaxScore, nMinScore)
    return ((100 - nFinalScoreParam) * nBaseScore + 100 * (nMaxScore - nMinScore) + nMaxScore * (nFinalScoreParam - 100)) / (nMaxScore - nMinScore)
end

-- 获得一个新的Helper实例
function ShipDataDisplayHelper.New(nShipItemTemplateId)
    local Helper = ShipDataDisplayHelper()
    Helper.nShipItemTemplateId = nShipItemTemplateId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nShipItemTemplateId)
    local nShipTemplateId = tbItemTemplate.nShipId
    Helper.tbShipTemplate = ShipDataTable:GetTemplate(nShipTemplateId)
    return Helper
end

return ShipDataDisplayHelper