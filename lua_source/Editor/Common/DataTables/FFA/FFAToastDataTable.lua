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
-- [EXPORT] 
local L10N = require("L10N")

local FFAToastDataTable = {}

FFAToastDataTable.szFileName = "client/text/ffatoast.tab"
-- [EXPORT BEGIN]
FFAToastDataTable.tbContainerNew = {}
-- [EXPORT END]

function FFAToastDataTable:OnEditorDefine(Parser)
    --Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nWeaponId", "weapon_id", 0, Parser.TypeInt, false)
    --Parser:Define("l10nKillerToast", "killer_toast", L10N.NullString, Parser.TypeL10N)
    --Parser:Define("l10nDeadToast", "dead_toast", L10N.NullString, Parser.TypeL10N)
    Parser:Define("l10nDamageText", "damage_text", L10N.NullString, Parser.TypeL10N)
    --Parser:Define("szText", "text", "", Parser.TypeString)
    Parser:Define("szIcon", "icon", "", Parser.TypeString)
end

function FFAToastDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbToastType = self.tbContainerNew[tbNewTemplate.nId]
    if not tbToastType then
        tbToastType = {}
        self.tbContainerNew[tbNewTemplate.nId] = tbToastType
    end
    tbToastType[tbNewTemplate.nWeaponId] = tbNewTemplate
    return true;
end

-- [EXPORT BEGIN]
function FFAToastDataTable:GetTemplate(nId, nWeaponId)
    local tbToastType = self.tbContainerNew[nId]
    if tbToastType then
        if nWeaponId then
            local tbTemplate = tbToastType[nWeaponId]
            if not tbTemplate then
                tbTemplate = tbToastType[0]
            end
            return tbTemplate
        else
            return tbToastType[0]
        end
    end
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function FFAToastDataTable:GetContainer()
    return self.tbContainer
end
-- [EXPORT END]

return FFAToastDataTable
