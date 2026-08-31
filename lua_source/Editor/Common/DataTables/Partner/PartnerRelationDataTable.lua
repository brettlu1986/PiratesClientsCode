-----------------------------------------------------
--File Name    : PartnerRelationDataTable.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-05
--Description  : 伙伴羁绊相关属性配置表
-----------------------------------------------------
local PartnerRelationDataTable = {}

local L10N = require("L10N")
local ItemDataTable = require("ItemDataTable")

local MAX_PARTNER_COUNT = 3
PartnerRelationDataTable.szFileName = "common/item2/sub/partner/partner_relation.tab"
PartnerRelationDataTable.bEnableIterateKey = true

function PartnerRelationDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId"             , "id"                  , -1                , Parser.TypeInt)
    Parser:Define("nGroupId"        , "group_id"            , -1                , Parser.TypeInt)
    Parser:Define("nLevel"          , "level"               , -1                , Parser.TypeInt)
    Parser:Define("l10nDesc"        , "desc"                , L10N.NullString   , Parser.TypeL10N)
    Parser:Define("nPropertyComboId", "property_combo_id"   , -1                , Parser.TypeInt)
end

function PartnerRelationDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbPartnerIds = {}
    for i=1,MAX_PARTNER_COUNT do
        local nPartnerId = Parser:Get("partner_id_" .. i, nil, Parser.TypeInt)
        if nPartnerId and (not ItemDataTable:GetTemplate(nPartnerId)) then
            logerror("cannot find partner_id in item data table. partner_id =", nPartnerId)
            return false
        end
        tbPartnerIds[i] = nPartnerId
    end
    tbNewTemplate.tbPartnerIds = tbPartnerIds
    return true
end

-- [EXPORT BEGIN]
-- 判断一个partnerid是否在某条template中
local function IsPartnerInTemplate(tbTemplate, nPartnerId)
    for _, nId in ipairs(tbTemplate.tbPartnerIds) do
        if nId == nPartnerId then
            return true
        end
    end
    return false
end

function PartnerRelationDataTable:GetTemplate(nPartnerRelationId)
    return self.tbContainer[nPartnerRelationId]
end

-- {[nGroupId1]={tbTemplate1,tbTemplate2...},[nGroupId2]={tbTemplate3,...},}
function PartnerRelationDataTable:GetRelationsByPartnerId(nPartnerId)
    local tbRelationMap = {}
    for _, tbTemplate in pairs(self.tbContainer) do
        if IsPartnerInTemplate(tbTemplate, nPartnerId) then
            tbRelationMap[tbTemplate.nGroupId] = tbRelationMap[tbTemplate.nGroupId] or {}
            table.insert(tbRelationMap[tbTemplate.nGroupId], tbTemplate)
        end
    end
    local tbRelations = {}
    for _, tbGroupData in pairs(tbRelationMap) do
        table.insert(tbRelations, tbGroupData)
    end
    return tbRelations
end
-- [EXPORT END]

return PartnerRelationDataTable
