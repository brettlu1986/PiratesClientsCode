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

-- [EXPORT]
local L10N = require("L10N")

local ToastTextDataTable = {}

ToastTextDataTable.szFileName = "client/text/toast.tab"

function ToastTextDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("szText", "text", L10N.NullString, Parser.TypeL10N)
end

-- [EXPORT BEGIN]
function ToastTextDataTable:GetText(nID)
    local tbToast = self.tbContainer[nID]
    if tbToast ~= nil then
        return tbToast.szText -- 逻辑已经是l10n了，但是命名没改
    else
        logwarning("Dialog text not found. Id", nID)
        return L10N.NullString
    end
end
-- [EXPORT END]

return ToastTextDataTable