-----------------------------------------------------
--File Name    : HumanArmorItemPropertyHelper.lua
--Author       : WuJizhou
--Create Time  : 9/12/2018, 3:09:21 PM
--Description  : HumanArmorItemPropertyHelper
-----------------------------------------------------

local HumanArmorItemPropertyHelper = {}

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleItemDataTable = require("BattleItemDataTable")

local tbPropertyMetatable = {}
tbPropertyMetatable.__newindex = function (tb, key, value)
    if rawget(tb, key) == nil then
        logerror("HumanArmorItemProperty table should not be assigned any new key")
    else
        rawset(tb, key, value)
    end
end

function HumanArmorItemPropertyHelper.CreatePropertyOld(nTemplateId)
    if nTemplateId == nil then
        logerror("HumanArmorItemPropertyHelper.CreateProperty error, the template id is nil!")
        return nil
    end
    local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    if tbTemplate == nil then
        logerror("HumanArmorItemPropertyHelper.CreateProperty error, the template id does not exist!")
        return nil
    end

    local tbProperty = {}
    tbProperty.nTemplateId = nTemplateId
    tbProperty.nReduceHeadDamage = tbTemplate.nReduceHeadDamage -- 减伤比例
    tbProperty.nReduceBodyDamage = tbTemplate.nReduceBodyDamage -- 减伤比例
    setmetatable(tbProperty, tbPropertyMetatable)
    return tbProperty
end



function HumanArmorItemPropertyHelper.CreatePropertyNew(nTemplateId)
    if nTemplateId == nil then
        logerror("HumanArmorItemPropertyHelper.CreateProperty error, the template id is nil!")
        return nil
    end
    local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    if tbTemplate == nil then
        logerror("HumanArmorItemPropertyHelper.CreateProperty error, the template id does not exist!")
        return nil
    end

    local tbProperty = {}
    tbProperty.nTemplateId = nTemplateId
    tbProperty.tbDamageReduce = tbTemplate.tbDamageReduce
    tbProperty.tbBuffIds = tbTemplate.tbBuffIds
    setmetatable(tbProperty, tbPropertyMetatable)
    return tbProperty
end

local function DynamicAssignFunction()
    if GlobalVariableSystem.bUseNewBattleItem then
        HumanArmorItemPropertyHelper.CreateProperty = HumanArmorItemPropertyHelper.CreatePropertyNew
    else
        HumanArmorItemPropertyHelper.CreateProperty = HumanArmorItemPropertyHelper.CreatePropertyOld
    end
end

DynamicAssignFunction()


function HumanArmorItemPropertyHelper.GetReduceDamageFactor(tbArmorItem, nHumanWeaponDamageType, nHumanBodyType)
    local tbDamageReduce = tbArmorItem.tbProperty.tbDamageReduce
    local tbSubReduce = tbDamageReduce[nHumanWeaponDamageType]
    if not tbSubReduce then
        logerror("HumanArmorItemPropertyHelper.GetReduceDamageFactor failed", string.format("weapon damagetype : %d, human body type : %d", nHumanWeaponDamageType, nHumanBodyType))
        return nil
    else
        return tbSubReduce[nHumanBodyType]
    end
end

return HumanArmorItemPropertyHelper