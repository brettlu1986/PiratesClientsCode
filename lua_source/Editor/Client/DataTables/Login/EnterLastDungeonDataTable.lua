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
local EnterLastDungeonDataTable = {}

EnterLastDungeonDataTable.szFileName = "client/login/enter_last_dungeon.tab"


function EnterLastDungeonDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nDungeonId")
    Parser:Define("nDungeonId", "dungeonid", -1, Parser.TypeInt)
    Parser:Define("Title", "title", "", Parser.TypeString, false)
    Parser:Define("Message", "message", "", Parser.TypeString, false)
    Parser:Define("bForceDialog", "force_dialog", false, Parser.TypeBool, false)
end

-- [EXPORT BEGIN]
function EnterLastDungeonDataTable:GetTemplate(nDungeonId)
    return self.tbContainer[nDungeonId]
end

function EnterLastDungeonDataTable:GetTitle(nDungeonId)
    if self:GetTemplate(nDungeonId) then
        return self:GetTemplate(nDungeonId).Title
    end

    return ""
end

function EnterLastDungeonDataTable:GetMessage(nDungeonId)
    if self:GetTemplate(nDungeonId) then
        return self:GetTemplate(nDungeonId).Message
    end

    return ""
end

function EnterLastDungeonDataTable:IsForceDialog(nDungeonId)
    if self:GetTemplate(nDungeonId) then
        return self:GetTemplate(nDungeonId).bForceDialog
    end

    return false
end
-- [EXPORT END]

return EnterLastDungeonDataTable