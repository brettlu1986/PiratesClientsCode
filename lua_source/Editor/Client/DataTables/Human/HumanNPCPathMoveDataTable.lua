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
local HumanNPCPathMoveDataTable = {}

HumanNPCPathMoveDataTable.szFileName = "client/human/human_npc_path_move.tab"

function HumanNPCPathMoveDataTable:OnEditorDefine(Parser)
    Parser:Define("nId", "id", 0, Parser.TypeInt)
    Parser:Define("nMaxAngle", "max_angle", 180, Parser.TypeFloat)
    Parser:Define("nYawRate", "yaw_rate", -1, Parser.TypeFloat)
end

function HumanNPCPathMoveDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbGears = self.tbContainer[tbNewTemplate.nId];
    if (not tbGears) then
        tbGears = {}
        tbContainer[tbNewTemplate.nId] = tbGears;
    end

    table.insert(tbGears, tbNewTemplate)
    table.insert(self.tbContainer, tbNewTemplate)
    return true;
end

return HumanNPCPathMoveDataTable