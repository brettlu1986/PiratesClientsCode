--[[
    DataTable类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    tbContainer: table
    OnEditorParseLine： 解析函数，参数Parser

    可选的变量与函数
    OnEditorParseFinished: 参数无，本DataTable读取完毕后触发
    OnGameRequired: 参数无，游戏运行时第一次require时触发
    OnEditorDefine: 定义导出参数    自定义导出标签：
         导出单行：-- [EXPORT] 
         导出多行：-- [EXPORT BEGIN] 和 -- [EXPORT END]
--]]
local FactionLevelTable = {}

FactionLevelTable.szFileName = "common/faction/faction_level.tab"
-- [EXPORT]
FactionLevelTable.nMaxLevel = 0

function FactionLevelTable:OnEditorDefine(Parser)
    Parser:SetKey("nLevel")
    Parser:Define("nLevel", "level", -1, Parser.TypeInt)
    Parser:Define("nFactionPoint", "faction_point", -1, Parser.TypeInt)
    Parser:Define("szFactionName", "name", "unknown", Parser.TypeString)
    Parser:Define("szTxtColor", "txt_color", "", Parser.TypeString)
end

function FactionLevelTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if tbNewTemplate.nLevel > self.nMaxLevel then 
        self.nMaxLevel = tbNewTemplate.nLevel
    end 

    return true
end

-- [EXPORT BEGIN]
function FactionLevelTable:GetTemplateByLevel(nLevel)
    return self.tbContainer[nLevel]
end 
-- [EXPORT END]

-- [EXPORT BEGIN]
function FactionLevelTable:GetTemplate(nFactionPoint)
    local tbFactionData = nil 
    for _,v in ipairs(self.tbContainer) do
        if nFactionPoint >= v.nFactionPoint then 
            if not tbFactionData or tbFactionData.nFactionPoint < v.nFactionPoint then 
                tbFactionData = v
            end 
        end 
    end

    return tbFactionData
end
-- [EXPORT END]


return FactionLevelTable
