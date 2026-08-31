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

-- 加载界面Tips表

local LoadingTipsDataTable = {}

local L10N = require("L10N")

LoadingTipsDataTable.szFileName = "client/ui/loading_tips.tab"

function LoadingTipsDataTable:OnEditorDefine(Parser)
    Parser:SetKey("szKey")
    Parser:Define("szKey", "key", "", Parser.TypeString)
    Parser:Define("l10nTip", "tip", L10N.NullString, Parser.TypeL10N)
    Parser:Define("nMinLevel", "min_level", -1, Parser.TypeInt)
    Parser:Define("nMaxLevel", "max_level", -1, Parser.TypeInt)
    Parser:Define("nDuration", "duration", -1, Parser.TypeInt)
end


-- [EXPORT BEGIN]
function  LoadingTipsDataTable:GetContainer()
    return self.tbContainer
end

function LoadingTipsDataTable:GetTemplateByPlayerLevel(nPlayerLevel)
    local tbTips = {}
    for i, v in pairs(self.tbContainer) do
        if (v.nMinLevel < 0 or v.nMinLevel <= nPlayerLevel) and (v.nMaxLevel < 0 or v.nMaxLevel >= nPlayerLevel) then
            table.insert(tbTips, v)
        end
    end
    return tbTips
end
-- [EXPORT END]

return LoadingTipsDataTable