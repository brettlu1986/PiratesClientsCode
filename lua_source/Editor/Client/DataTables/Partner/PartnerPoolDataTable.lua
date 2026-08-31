-----------------------------------------------------
--File Name    : PartnerPoolDataTable.lua
--Author       : Song Fuhao
--Create Time  : 2019-04-09
--Description  : 伙伴招募池相关属性配置表
-----------------------------------------------------
local PartnerPoolDataTable = {}

PartnerPoolDataTable.szFileName = "common/item2/sub/partner/partner_pool.tab"

function PartnerPoolDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nPoolId")
    Parser:Define("nPoolId"         , "pool_id"         , -1    , Parser.TypeInt)
    Parser:Define("nCurrencyId"     , "currency_id"     , -1    , Parser.TypeInt)
    Parser:Define("nOneTimeCount"   , "one_time_count"  , -1    , Parser.TypeInt)
    Parser:Define("nTenTimesCount"  , "ten_times_count" , -1    , Parser.TypeInt)
    Parser:Define("bDisabled"       , "disabled"        , false , Parser.TypeBool)
end

-- [EXPORT BEGIN]
function PartnerPoolDataTable:GetTemplate(nPartnerRelationId)
    return self.tbContainer[nPartnerRelationId]
end
-- [EXPORT END]

return PartnerPoolDataTable
