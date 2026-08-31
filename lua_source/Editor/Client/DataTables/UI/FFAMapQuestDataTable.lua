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
local FFAMapQuestDataTable = {}

FFAMapQuestDataTable.szFileName = "client/ui/map/ui_ffa_map_quest.tab"


function FFAMapQuestDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nType", "type", -1, Parser.TypeInt)
    Parser:Define("nTemplateId", "templateid", -1, Parser.TypeInt, false)
    Parser:Define("szIconResPath", "icon_res", "", Parser.TypeString, false)
end

-- [EXPORT BEGIN]
function FFAMapQuestDataTable:GetTemplate(nId)
    return self.tbContainer[nId] 
end

function FFAMapQuestDataTable:GetNPCData()
    local tbRet = {}

    for _,v in pairs(self.tbContainer) do
        if v.nType == 1 then 
            tbRet[v.nTemplateId] = v.szIconResPath
        end
    end

    return tbRet
end

function FFAMapQuestDataTable:GetItemData()
    local tbRet = {}

    for _,v in pairs(self.tbContainer) do
        if v.nType == 0 then 
            tbRet[v.nTemplateId] = v.szIconResPath
        end
    end

    return tbRet
end
-- [EXPORT END]



return FFAMapQuestDataTable
