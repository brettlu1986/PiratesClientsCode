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
local IAPDataTable = {}

local L10N = require("L10N")

IAPDataTable.szFileName = "common/iap/iap.tab"
IAPDataTable.bEnableIterateKey = true

function IAPDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId"                 , "id"                  , -1                , Parser.TypeInt)
    Parser:Define("szProductId"         , "product_id"          , ""                , Parser.TypeString)
    Parser:Define("szChannel"           , "channel"             , nil               , Parser.TypeString)
    Parser:Define("szPlatform"          , "platform"            , nil               , Parser.TypeString)
    Parser:Define("nPrice"              , "price"               , 0                 , Parser.TypeInt)
    Parser:Define("szCurrencyName"      , "currency_name"       , ""                , Parser.TypeString)
    Parser:Define("nDisplayGiftCount"   , "display_gift_count"  , 0                 , Parser.TypeInt)
    Parser:Define("l10nDisplayName"     , "display_name"        , L10N.NullString   , Parser.TypeL10N)
    Parser:Define("l10nDisplayPrice"    , "display_price"       , L10N.NullString   , Parser.TypeL10N)
    Parser:Define("szIconRes"           , "icon_res"            , nil               , Parser.TypeString)
end

-- [EXPORT BEGIN]
function IAPDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end

-- 根据平台、渠道获取支付列表
-- szPlatform   平台标识，不传则获取所有平台
-- szChannel    渠道标识，不传则获取所有渠道
function IAPDataTable:GetTemplateByPlatformAndChannel(szPlatform, szChannel)
    log(string.format("[IAP] GetTemplateByPlatformAndChannel szPlatform=%s, szChannel=%s", szPlatform, szChannel))
    local tbRet = {}
    for i, v in pairs(self.tbContainer) do
        if (v.szPlatform == szPlatform) and (v.szChannel == szChannel) then
            table.insert(tbRet, v)
        end
    end
    table.sort(tbRet, function(tbTemplateA, tbTemplateB)
        return tbTemplateA.nId < tbTemplateB.nId
    end)
    return tbRet
end
-- [EXPORT END]

return IAPDataTable
