--[[
    CampTypeRelation类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnEditorParseLine： 解析函数，参数Parser

    可选的变量与函数
    OnEditorParseFinished: 参数无，本DataTable读取完毕后触发
    OnGameRequired: 参数无，游戏运行时第一次require时触发
    OnEditorDefine: 定义导出参数    自定义导出标签：
         导出单行：-- [EXPORT] 
         导出多行：-- [EXPORT BEGIN] 和 -- [EXPORT END]
--]]
-- [EXPORT]
local CampDef = require("CampDefine")
local CampTypeRelationDataTable = {}

CampTypeRelationDataTable.szFileName = "common/dungeon/camp_type_relation.tab"

-- [EXPORT BEGIN]
local CampTypeKey = {}
CampTypeKey[CampDef.Type.CAMP_NONE] = "nCampNone"
CampTypeKey[CampDef.Type.CAMP_1] = "nCamp1"
CampTypeKey[CampDef.Type.CAMP_2] = "nCamp2"
CampTypeKey[CampDef.Type.CAMP_HOSTILE] = "nCampHostile"
CampTypeKey[CampDef.Type.CAMP_NEUTRAL] = "nCampNeutral"
CampTypeKey[CampDef.Type.CAMP_ALLHOSTILE] = "nCampAllHostile"
CampTypeKey[CampDef.Type.CAMP_6] = "nCamp6"
CampTypeKey[CampDef.Type.CAMP_ENGLAND] = "nCampEngland"
CampTypeKey[CampDef.Type.CAMP_SPAIN] = "nCampSpain"
CampTypeKey[CampDef.Type.CAMP_PIRATE] = "nCampPirate"
-- [EXPORT END]

function CampTypeRelationDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nCamptype")
    Parser:Define("nCamptype", "camptype", 0, Parser.TypeInt)
    Parser:Define("nCampNone", "camp_none", 0, Parser.TypeInt)
    Parser:Define("nCamp1", "camp_1", 0, Parser.TypeInt)
    Parser:Define("nCamp2", "camp_2", 0, Parser.TypeInt)
    Parser:Define("nCampHostile", "camp_hostile", 0, Parser.TypeInt)
    Parser:Define("nCampNeutral", "camp_neutral", 0, Parser.TypeInt)
    Parser:Define("nCampAllHostile", "camp_allhostile", 0, Parser.TypeInt)
    Parser:Define("nCamp6", "camp_6", 0, Parser.TypeInt)
    Parser:Define("nCampEngland", "camp_england", 0, Parser.TypeInt)
    Parser:Define("nCampSpain", "camp_spain", 0, Parser.TypeInt)
    Parser:Define("nCampPirate", "camp_pirate", 0, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function CampTypeRelationDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function CampTypeRelationDataTable:GetRelation(nCampTypeA, nCampTypeB)
    local nRelation = self.tbContainer[nCampTypeA][CampTypeKey[nCampTypeB]]
    if nRelation then
        return nRelation
    end
    return 0
end
-- [EXPORT END]

return CampTypeRelationDataTable
