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
local PoisonCircleDataTable = {}

PoisonCircleDataTable.szFileName = "common/ffa/poison_circle/poison_circle.tab"

function PoisonCircleDataTable:OnEditorDefine(Parser)
    Parser:Define("nDungoenId", "dungeon_id", -1, Parser.TypeInt)
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nWaitTime", "wait_time", -1, Parser.TypeInt)
    Parser:Define("nShrinkTime", "shrink_time", -1, Parser.TypeInt)
    Parser:Define("nRadius", "radius", -1, Parser.TypeInt)
    Parser:Define("nBuffId", "buff_id", -1, Parser.TypeInt)
    Parser:Define("nExtendBuffId", "extend_buff_id", -1, Parser.TypeInt)
    Parser:Define("nRadiusRange", "radius_range", -1, Parser.TypeInt)
end

function PoisonCircleDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nDungeonId = tbNewTemplate.nDungoenId
    tbNewTemplate.nDungeonId = nil
    local tbDungeonInfo = tbContainer[nDungeonId]
    if(tbDungeonInfo == nil) then
        tbDungeonInfo = {}
        tbContainer[nDungeonId] = tbDungeonInfo
    end

    tbDungeonInfo[tbNewTemplate.nId] = tbNewTemplate
    return true
end

-- [EXPORT BEGIN]
function PoisonCircleDataTable:GetContainer(nDungeonId)
    return self.tbContainer[nDungeonId]
end
-- [EXPORT END]

return PoisonCircleDataTable
