local SailorSummonDataTable = {}

SailorSummonDataTable.szFileName = "common/item2/sub/sailor/sailor_summon.tab"

function SailorSummonDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId"         , "id"          , -1, Parser.TypeInt)
    Parser:Define("nCurrencyId" , "currency_id" , -1, Parser.TypeInt)
    Parser:Define("nPrice"      , "price"       , -1, Parser.TypeInt)
    Parser:Define("nCount"      , "count"       , -1, Parser.TypeInt)
    Parser:Define("nFreePeriod" , "free_period" , -1, Parser.TypeInt)
end

function SailorSummonDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    tbNewTemplate.bCanFree = false
    if tbNewTemplate.nFreePeriod > 0 then
        tbNewTemplate.bCanFree = true
        tbNewTemplate.nFreeSeconds = tbNewTemplate.nFreePeriod * 60
    end
    return true
end

-- [EXPORT BEGIN]
function SailorSummonDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function SailorSummonDataTable:GetAllTemplates()
    return self.tbContainer
end
-- [EXPORT END]

return SailorSummonDataTable
