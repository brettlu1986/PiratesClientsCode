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
local AvatarDataTable = {}

AvatarDataTable.szFileName = "common/human/avatar.tab"

function AvatarDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nID")
    Parser:Define("nID", "id", -1, Parser.TypeInt)
    Parser:Define("nHumanId", "human_id", -1, Parser.TypeInt)
    Parser:Define("nHeadIconId", "head_icon_id", -1, Parser.TypeInt)
    Parser:Define("szShowAnimation", "show_animation", nil, Parser.TypeString)
end

-- [EXPORT BEGIN]
function AvatarDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function AvatarDataTable:GetHumanId(nId)
    local tbTemplate = self:GetTemplate(nId)
    if(tbTemplate) then
        return tbTemplate.nHumanId
    end
    return nil
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function AvatarDataTable:OnGameRequired()
    local HumanDataTable = require("HumanDataTable")
    local tbContainer = self.tbContainer
    for k,v in pairs(tbContainer) do
        v.tbHumanData = HumanDataTable:GetTemplate(v.nHumanId)
        if(v.tbHumanData == nil) then
            logwarning("AvatarDataTable find human id failed: ", v.nHumanId)
        end
    end
end
-- [EXPORT END]

return AvatarDataTable
