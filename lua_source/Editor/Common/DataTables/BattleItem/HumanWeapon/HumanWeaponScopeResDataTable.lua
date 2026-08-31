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
local HumanWeaponScopeResDataTable = {}

HumanWeaponScopeResDataTable.szFileName = "common/ffa/res/human_weapon_scope_res.tab"

function HumanWeaponScopeResDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nResId")
    Parser:Define("nResId"  , "res_id", -1, Parser.TypeInt)
    
end

-- [EXPORT BEGIN]
function HumanWeaponScopeResDataTable:GetTemplate(nResId)
    return self.tbContainer[nResId]
end
-- [EXPORT END]

return HumanWeaponScopeResDataTable
