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
local BattleResultAvatarPositionDataTable = {}

BattleResultAvatarPositionDataTable.szFileName = "client/battleresult/avatar_position.tab"

function BattleResultAvatarPositionDataTable:OnEditorDefine(Parser)
    --Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nPosition", "position", -1, Parser.TypeInt)
    Parser:Define("szShowAnimation", "show_animation", nil, Parser.TypeString)
end

function BattleResultAvatarPositionDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if not tbContainer[tbNewTemplate.nId] then
        tbContainer[tbNewTemplate.nId] = {}
    end
    local tbSubContainer = tbContainer[tbNewTemplate.nId]
    if not tbSubContainer[tbNewTemplate.nPosition] then
        tbSubContainer[tbNewTemplate.nPosition] = tbNewTemplate
    end
    return true;
end

-- [EXPORT BEGIN]
function BattleResultAvatarPositionDataTable:GetShowAnimation(nId, nPosition)
    if self.tbContainer[nId] then
        local tbTemplate = self.tbContainer[nId][nPosition]
        if tbTemplate then
            return tbTemplate.szShowAnimation
        end
        return nil
    end
    return nil
end
-- [EXPORT END]

return BattleResultAvatarPositionDataTable
