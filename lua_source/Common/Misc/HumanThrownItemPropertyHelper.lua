-----------------------------------------------------
--File Name    : HumanThrownItemPropertyHelper.lua
--Author       : WuJizhou
--Create Time  : 9/12/2018, 3:09:21 PM
--Description  : HumanThrownItemPropertyHelper
-----------------------------------------------------
local HumanWeaponCategoryPropertyDataTable = require("HumanWeaponCategoryPropertyDataTable")

local HumanThrownItemPropertyHelper = {}

local BattleItemDataTable = require("BattleItemDataTable")

local tbPropertyMetatable = {}
-- tbPropertyMetatable.__index = function (tb, key)

-- end

tbPropertyMetatable.__newindex = function (tb, key, value)
    if rawget(tb, key) == nil then
        logerror("HumanThrownItemProperty table should not be assigned any new key")
    else
        rawset(tb, key, value)
    end
end


local function GetWeaponCategoryProperty(self)
    local tbTemplate = HumanWeaponCategoryPropertyDataTable:GetTemplate(1000 + self.nWeaponCategory)
    if tbTemplate ~= nil then
        return tbTemplate
    end
end

tbPropertyMetatable.__index = function (tb, key)
    if key == "tbWeaponCategoryProperty" then
        return GetWeaponCategoryProperty(tb)
    else
        return rawget(tb, key)
    end
end

function HumanThrownItemPropertyHelper.CreateProperty(nTemplateId)
    if nTemplateId == nil then
        logerror("HumanThrownItemPropertyHelper.CreateProperty error, the template id is nil!")
        return nil
    end
    local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    if tbTemplate == nil then
        logerror("HumanThrownItemPropertyHelper.CreateProperty error, the template id does not exist!")
        return nil
    end

    local tbProperty = {}
    tbProperty.nTemplateId = nTemplateId
    tbProperty.nWeaponCategory = tbTemplate.nThrownItemCategory
    tbProperty.nDamage = tbTemplate.nDamage
    tbProperty.nInnerRadius = tbTemplate.nInnerRadius
    tbProperty.nOuterRadius = tbTemplate.nOuterRadius
    tbProperty.nDamageFallOff = tbTemplate.nDamageFallOff
    tbProperty.nPreActionTime = tbTemplate.nPreActionTime
    tbProperty.nPreExplodeTime = tbTemplate.nPreExplodeTime
    tbProperty.nGroundLastTime = tbTemplate.nGroundLastTime
    tbProperty.nThrowOutTimenThrowOutTime = tbTemplate.nThrowOutTime
    tbProperty.nCD = tbTemplate.nCD
    tbProperty.nTraceId = tbTemplate.nTraceId
    tbProperty.nThrowDistance = tbTemplate.nThrowDistance
    tbProperty.nInitialLowSpeed = tbTemplate.nInitialLowSpeed
    tbProperty.nInitialSpeed = tbTemplate.nInitialSpeed
    tbProperty.nBounceAttenuationValue = tbTemplate.nBounceAttenuationValue
    tbProperty.nBounceAttenuationPercent = tbTemplate.nBounceAttenuationPercent
    tbProperty.nVerticleHighSpeed = tbTemplate.nVerticleHighSpeed
    tbProperty.nVerticleLowSpeed = tbTemplate.nVerticleLowSpeed
    tbProperty.nBuffId = tbTemplate.nBuffId
    tbProperty.nGravityRate = tbTemplate.nGravityRate

    setmetatable(tbProperty, tbPropertyMetatable)
    return tbProperty
end


return HumanThrownItemPropertyHelper