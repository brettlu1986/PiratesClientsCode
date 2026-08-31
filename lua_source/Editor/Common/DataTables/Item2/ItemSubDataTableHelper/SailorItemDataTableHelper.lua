-----------------------------------------------------
--File Name    : SailorItemDataTableHelper.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-19
--Description  :水手的配置表读取helper
-----------------------------------------------------
local SailorItemDataTableHelper = {}

local function GetUpgradeToTopCurrencyAmount(tbTemplates, nSailorId)
    local nUpgradeToTopCurrencyAmount = 0
    while nSailorId ~= 0 do
        local tbTemplate = tbTemplates[nSailorId]
        nUpgradeToTopCurrencyAmount = nUpgradeToTopCurrencyAmount + tbTemplate.nUpgradeCurrencyAmount
        nSailorId = tbTemplate.nUpgradeTo
    end
    return nUpgradeToTopCurrencyAmount
end

function SailorItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nDegradeTo                          = 0
    NewTemplate.nUpgradeTo                          = Parser:Get("upgrade_to"                           , -1                , Parser.TypeInt)
    NewTemplate.nUpgradeCurrencyAmount              = Parser:Get("upgrade_currency_amount"              , -1                , Parser.TypeInt)
    NewTemplate.nAccumulativeDegradeCurrencyAmount  = Parser:Get("accumulative_degrade_currency_amount" , -1                , Parser.TypeInt)
    NewTemplate.nPropertyComboId                    = Parser:Get("property_combo_id"                    , -1                , Parser.TypeInt)
end

function SailorItemDataTableHelper.OnEditorParseFinished(tbSubContainer)
    for nSailorId, tbTemplate in pairs(tbSubContainer) do
        -- 补全上下级关系，建立双向链式关系
        local nUpgradeTo = tbTemplate.nUpgradeTo
        if nUpgradeTo ~= 0 then
            tbSubContainer[nUpgradeTo].nDegradeTo = nSailorId
        end
        -- 补全升级至最高级价格
        tbTemplate.nUpgradeToTopCurrencyAmount = GetUpgradeToTopCurrencyAmount(tbSubContainer, nSailorId)
    end
end

return SailorItemDataTableHelper