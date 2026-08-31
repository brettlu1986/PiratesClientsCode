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
local GroupTriggerDataTable = {}

GroupTriggerDataTable.szFileName = "common/dungeon/group_trigger.tab"

function GroupTriggerDataTable:OnEditorDefine(Parser)
    Parser:Define("nGroupId", "group_id", -1, Parser.TypeInt)
    Parser:Define("nTriggerBuffId", "trigger_buff_id", -1, Parser.TypeInt)
end

function GroupTriggerDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    

    local tbGroupTriggerList = self.tbContainer[tbNewTemplate.nGroupId]
    if tbGroupTriggerList == nil then
        tbContainer[tbNewTemplate.nGroupId] = {}
        tbGroupTriggerList = self.tbContainer[tbNewTemplate.nGroupId]
    end

    table.insert(tbGroupTriggerList, tbNewTemplate)
    
    return true
end

-- [EXPORT BEGIN]
function GroupTriggerDataTable:GetGroup(nGroupID)
    return self.tbContainer[nGroupID]
end
-- [EXPORT END]

return GroupTriggerDataTable
