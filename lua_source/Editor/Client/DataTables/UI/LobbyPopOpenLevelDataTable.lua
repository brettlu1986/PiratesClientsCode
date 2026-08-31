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
local LobbyPopOpenLevelDataTable = {}

LobbyPopOpenLevelDataTable.szFileName = "client/ui/lobby_pop_open_level.tab"

function LobbyPopOpenLevelDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nLevel")    
    Parser:Define("nLevel", "level", -1, Parser.TypeInt)
    Parser:Define("szSuccessProto", "success_proto", "", Parser.TypeString)
    Parser:Define("szFailedProto", "failed_proto", "", Parser.TypeString)
    Parser:Define("szUI", "ui", "", Parser.TypeString)    
    Parser:Define("szProcess", "process", nil, Parser.TypeString)    
    Parser:Define("bCanSkip", "can_skip", false, Parser.TypeBool)    
    Parser:Define("szSkipParam", "skip_param", nil, Parser.TypeString)    
end

-- [EXPORT BEGIN]
function LobbyPopOpenLevelDataTable:GetContainer()
    return self.tbContainer
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function LobbyPopOpenLevelDataTable:GetTemplate(nLevel)
    return self.tbContainer[nLevel]
end
-- [EXPORT END]

return LobbyPopOpenLevelDataTable
