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
local IAPResultToastDataTable = {}

local L10N = require("L10N")

IAPResultToastDataTable.szFileName = "client/iap/iap_result_toast.tab"

function IAPResultToastDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nResultCode")
    Parser:Define("nResultCode" , "result_code" , -1                , Parser.TypeInt)
    Parser:Define("bShowToast"  , "show_toast"  , false             , Parser.TypeBool)
    Parser:Define("l10nMessage" , "message"     , L10N.NullString   , Parser.TypeL10N)
end

-- [EXPORT BEGIN]
function IAPResultToastDataTable:GetTemplate(nResultCode)
    return self.tbContainer[nResultCode]
end

-- 获取对应结果码时是否弹出Toast
function IAPResultToastDataTable:IsShowToast(nResultCode)
    local tbTemplate = self:GetTemplate(nResultCode)
    if tbTemplate then
        return tbTemplate.bShowToast
    end
    return false
end

-- 获取对应结果码时弹出的Toast内容
function IAPResultToastDataTable:GetMessage(nResultCode)
    local tbTemplate = self:GetTemplate(nResultCode)
    if tbTemplate then
        return tbTemplate.l10nMessage
    end
    return L10N.NullString
end
-- [EXPORT END]

return IAPResultToastDataTable
