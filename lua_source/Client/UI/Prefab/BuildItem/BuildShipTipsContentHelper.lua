local BuildShipTipsContentHelper = {}

local L10N = require("L10N")
local UISetUtils = require("UISetUtils")
local ShipDataDisplayHelper = require("ShipDataDisplayHelper")
local BattleItemDataTable = require("BattleItemDataTable")

local DESC_TITLE = UISetUtils.GetL10NTextByKey("FFA_UI_SHIP_TIPS_TITLE")

-- return tbShipTipsDatas
-- tbShipTipsDatas.szTitle
-- tbShipTipsDatas.
-- tbShipTipsDatas.tbSkillIds
function BuildShipTipsContentHelper.GetShipTipsDatas(nShipItemTemplateId)
    local tbDisplayHelper = ShipDataDisplayHelper.New(nShipItemTemplateId)
    local tbShipTemplate = tbDisplayHelper:GetTemplate()

    -- local tbDescDatas = {}
    -- local tbDisplayDataGroup = tbDisplayHelper:GetDisplayDataGroup()
    -- for _, tbCategoryData in ipairs(tbDisplayDataGroup) do
    --     for _, v in ipairs(tbCategoryData.tbProperties) do
    --         table.insert(tbDescDatas, {szName = v.l10nPropName, szValue = v.l10nPropValue})
    --     end
    -- end
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nShipItemTemplateId)

    local tbShipTipsDatas = {}
    tbShipTipsDatas.szTitle = L10N:Format(DESC_TITLE, tbItemTemplate.l10nName, tbShipTemplate.nGrade)
    -- tbShipTipsDatas.tbDescDatas = tbDescDatas
    tbShipTipsDatas.tbSkillIds = tbDisplayHelper:GetShipSkillIds()
    tbShipTipsDatas.tbRecommendedWeapons = tbItemTemplate.tbRecommendedWeapons
    return tbShipTipsDatas
end

return BuildShipTipsContentHelper
