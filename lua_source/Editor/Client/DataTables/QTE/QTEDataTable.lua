--[[
    DataTable类中必须有的成员变量与函数
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
local QTEDataTable = {}
local MatineeDataTable = require("MatineeDataTable")

QTEDataTable.szFileName = "client/qte/qte.tab"

function QTEDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nStartMatineeId", "start_matinee_id", -1, Parser.TypeInt, false)
    Parser:Define("nQTEMatineeId", "qte_matinee_id", -1, Parser.TypeInt)
    Parser:Define("nEndMatineeId", "end_matinee_id", -1, Parser.TypeInt)
end

function QTEDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nId = Parser:Get("id", -1, Parser.TypeInt)
    local nStartMatineeId = Parser:Get("start_matinee_id", -1, Parser.TypeInt)
    local nQTEMatineeId = Parser:Get("qte_matinee_id", -1, Parser.TypeInt)
    local nEndMatineeId = Parser:Get("end_matinee_id", -1, Parser.TypeInt)
    if nStartMatineeId >= 0 then
        local tbMatineeTemplate = MatineeDataTable:GetTemplate(nStartMatineeId)
        if not tbMatineeTemplate then
            error("QTEDataTable:OnEditorParseLine, invalid nStartMatineeId, qte id ="..nId) 
        end
    end
    local tbMatineeTemplate = MatineeDataTable:GetTemplate(nQTEMatineeId)
    if not tbMatineeTemplate then
        error("QTEDataTable:OnEditorParseLine, invalid nQTEMatineeId, qte id ="..nId) 
    end
    
    tbMatineeTemplate = MatineeDataTable:GetTemplate(nEndMatineeId)
    if not tbMatineeTemplate then
        error("QTEDataTable:OnEditorParseLine, invalid nEndMatineeId, qte id ="..nId) 
     end
    return true;
end

function QTEDataTable:OnEditorParseFinished()
    
end

-- [EXPORT BEGIN]
function QTEDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

return QTEDataTable