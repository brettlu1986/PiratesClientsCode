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

local LoginSdkBtnTable = {}

LoginSdkBtnTable.szFileName = "client/login/login_sdk_btn.tab"

function LoginSdkBtnTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("szSDKName", "sdk_name", "", Parser.TypeString)
    Parser:Define("bAccount", "account", false, Parser.TypeBool, false)
    Parser:Define("bAnnoce", "annoce", false, Parser.TypeBool, false)
    Parser:Define("bFb", "fb", false, Parser.TypeBool, false)
    Parser:Define("bCustomerService", "customer_service", false, Parser.TypeBool, false)
    Parser:Define("bHelper", "helper", false, Parser.TypeBool, false)
end

-- [EXPORT BEGIN]
function LoginSdkBtnTable:GetTemplateByName(szSDKName)
    for __, template in ipairs(self.tbContainer) do
        if template.szSDKName == szSDKName then
            return template
        end
    end
    return nil
end
-- [EXPORT END]

return LoginSdkBtnTable