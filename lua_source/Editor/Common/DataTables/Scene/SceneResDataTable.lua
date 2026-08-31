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
local SceneResDataTable = {}

SceneResDataTable.szFileName = "common/res/scene_res.tab"

function SceneResDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nID")
    Parser:Define("nID", "ID", -1, Parser.TypeInt)
    Parser:Define("szPath", "LevelName", "", Parser.TypeString)
    Parser:Define("szLogicRedirect", "LogicRedirect", nil, Parser.TypeString)
end

function SceneResDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)

    local szTemp = string.reverse(tbNewTemplate.szPath)
    local nIndex, _ = string.find(szTemp, "/")
    if(not nIndex) then nIndex, _ = string.find(szTemp, "/") end
    if(nIndex) then
        tbNewTemplate.szMapName = string.sub(tbNewTemplate.szPath, string.len(tbNewTemplate.szPath)-nIndex+2)
    else
        tbNewTemplate.szMapName = tbNewTemplate.szPath
    end

    return true
end

-- [EXPORT BEGIN]
function SceneResDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

return SceneResDataTable