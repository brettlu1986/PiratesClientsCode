local BattleItemUIHelper = {}

local BattleItemResDataTable        = require("BattleItemResDataTable")
local HumanWeaponFashionDataTable   = require("HumanWeaponFashionDataTable")

local HumanAvatarSystem             = dynamic_require("HumanAvatarSystem")

function BattleItemUIHelper.GetWeaponIcon(tbTemplate)
    local szRes
    local tbFashionData = HumanAvatarSystem:GetWeaponAvatarFashion()
    local nWeaponInstanceType = tbTemplate.nWeaponInstanceType
    local  nFashionId = tbFashionData[nWeaponInstanceType]
    local tFashionResTemplate = HumanWeaponFashionDataTable:GetFashionTemplate(nFashionId, tbTemplate.nGrade)

    if tFashionResTemplate then
        szRes = tFashionResTemplate.szIcon
    end
    if not szRes then
        local tbResTemplate = BattleItemResDataTable:GetTemplate(tbTemplate.nResId)
        szRes = tbResTemplate.szIconPath
    end
    return szRes
end



return BattleItemUIHelper