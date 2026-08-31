local HumanWeaponDefaultDataTable = {}

local BattleItemDataTable     = require("BattleItemDataTable")
local BattleItemCategoryDef   = require("BattleItemCategoryDef")
local BattleItemResDataTable  = require("BattleItemResDataTable")

local szCustomData = [[
    
function HumanWeaponDefaultDataTable:GetTemplate(nWeaponInstanceType, nLevel)
    local tbContainer = self.tbContainer
    local tbInstanceData = tbContainer[nWeaponInstanceType]
    if tbInstanceData then
        local tbLevelData = tbInstanceData[nLevel]
        if tbLevelData then
            return tbLevelData
        end
    end
    return {}
end

function HumanWeaponDefaultDataTable:GetAllLevelData(nWeaponInstanceType)
    local tbContainer = self.tbContainer
    local tbInstanceData = tbContainer[nWeaponInstanceType]
    if not tbInstanceData then
        tbInstanceData = {}
    end
    return tbInstanceData
end


function HumanWeaponDefaultDataTable:GetAllDatas()
    local tbContainer = self.tbContainer
    return tbContainer
end

]]

function HumanWeaponDefaultDataTable:Export()
    local tbData = {}
    local tbContainer = {}
    local tbTemplates = BattleItemDataTable:GetTemplatesByCategory(BattleItemCategoryDef.HUMAN_WEAPON)
    for k, tbTemplate in pairs(tbTemplates) do
        local nWeaponInstanceType = tbTemplate.nWeaponInstanceType
        if nWeaponInstanceType ~= -1 then
            local tbInstanceData = tbContainer[nWeaponInstanceType]
            if not tbInstanceData then
                tbInstanceData = {}
                tbContainer[nWeaponInstanceType]= tbInstanceData
            end
            local nLevel = tbTemplate.nGrade
            local nResId = tbTemplate.nResId
            local tbResTemplate = BattleItemResDataTable:GetTemplate(nResId)

            local tbLevelData = tbInstanceData[nLevel]
            if not tbLevelData then
                tbLevelData = {}
                tbInstanceData[nLevel] = tbLevelData
                tbInstanceData.szBPClassName = tbResTemplate.szEquipClassName
                tbInstanceData.l10nName = tbTemplate.l10nName
                tbInstanceData.nRangeType = tbTemplate.nPrimaryCategory
                tbInstanceData.nWeaponCategory = tbTemplate.nWeaponCategory
            end
            tbLevelData.szIconPath = tbResTemplate.szIconPath
            tbLevelData.nDefaultTrunkPartId = tbTemplate.nTrunkPartId

            tbLevelData.nDamagePerBullet = tbTemplate.nDamagePerBullet
            tbLevelData.nBulletMax = tbTemplate.nBulletMax
            tbLevelData.nInitialSpeed = tbTemplate.nInitialSpeed
            tbLevelData.nReloadTime = tbTemplate.nReloadTime
            tbLevelData.nBulletSpeed = tbTemplate.nBulletSpeed
            tbLevelData.nRecoilLevel = tbTemplate.nRecoilLevel
            tbLevelData.nEffectiveRange = tbTemplate.nEffectiveRange
            tbLevelData.nMeleeAttackSpeedLevel = tbTemplate.nMeleeAttackSpeedLevel
            tbLevelData.nFireballExplosiveOutsideRadius = tbTemplate.nFireballExplosiveOutsideRadius
        end
    end

    tbData.tbContainer = tbContainer
    return "HumanWeaponDefaultDataTable", tbData, szCustomData
end

return HumanWeaponDefaultDataTable