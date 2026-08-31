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
local HumanResDataTable = {}

HumanResDataTable.szFileName = "common/res/human_res.tab"

local HumanAvatarDef = require("HumanAvatarDef")

local PartTypeToConfigName = HumanAvatarDef.PartTypeToConfigName

function HumanResDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nID")
    Parser:Define("nID"                         ,   "id",                               -1,     Parser.TypeInt)
    Parser:Define("szPawnClassName"             ,   "pawn_class_name",                  "",     Parser.TypeString)
    Parser:Define("tbFashionTemplateIds"        ,   "fashion_template_ids",             {},     Parser.TypeArrayInt)
    Parser:Define("tbWeaponFashionTemplateIds"  ,   "weapon_fashion_template_ids",      {},     Parser.TypeArrayInt)
    Parser:Define("nHumanOverrideFlag"          ,   "fashion_override_flag",             0,     Parser.TypeInt)

    -- Parser:Define("nWeaponPartId", "weapon", -1, Parser.TypeInt)
    -- Parser:Define("nFishPoleId", "fishpole", -1, Parser.TypeInt)
end

function HumanResDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbData = {}
    for nPartType, szConfigName in pairs(PartTypeToConfigName) do
        local nValue = Parser:Get(szConfigName, nil, Parser.TypeInt, false)
        if nValue then
            tbData[nPartType] = nValue
        end
    end

    tbNewTemplate.tbAppearance = tbData
    return true
end

-- [EXPORT BEGIN]
function HumanResDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

return HumanResDataTable
