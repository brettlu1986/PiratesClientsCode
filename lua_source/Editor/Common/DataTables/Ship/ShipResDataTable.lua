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
local ShipResDataTable = {}

ShipResDataTable.szFileName = "common/res/ship_res.tab"

local function GetModelClassName(szPawnClassName)
    local pShipClass = szPawnClassName:load()
    local tbComponents = ExtendBlueprintFunctions.GetComponentsInCDOByClass(pShipClass, ChildActorComponent, true, false);
    local pModelClass = tbComponents[1].ChildActorClass -- 一定会有，没有的话直接导出时报错就好
    return ExtendBlueprintFunctions.GetClassPathName(pModelClass)
end

function ShipResDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nResId")
    Parser:Define("nResId", "res_id", -1, Parser.TypeInt)
    Parser:Define("szPawnClassName", "pawn_class_name", "", Parser.TypeString)
    Parser:Define("tbModelLocationOffset", "model_location_offset", {0,0,0}, Parser.TypeArrayInt)
    Parser:Define("tbModelRotationOffset", "model_rotation_offset", {0,0,0}, Parser.TypeArrayInt)
    Parser:Define("szBigPicPath", "ship_pic_path", nil, Parser.TypeString)
    Parser:Define("szPortrait", "portrait", nil, Parser.TypeString)
    Parser:Define("szIconPath", "ship_icon_path", nil, Parser.TypeString)
    Parser:Define("nFlag1", "flag1", -1, Parser.TypeInt)
    Parser:Define("nFlag2", "flag2", -1, Parser.TypeInt)
    Parser:Define("nFlag3", "flag3", -1, Parser.TypeInt)
    Parser:Define("nSail", "sail", -1, Parser.TypeInt)
    Parser:Define("nBody", "body", -1, Parser.TypeInt)
    Parser:Define("nFigureHead", "figure_head", -1, Parser.TypeInt)
    Parser:Define("nLight", "light", -1, Parser.TypeInt)
    Parser:Define("nAnchor", "anchor", -1, Parser.TypeInt)
    Parser:Define("nSailPattern", "sail_pattern", -1, Parser.TypeInt)
    Parser:Define("nModelScale", "model_scale", 1, Parser.TypeFloat)
    Parser:Define("tbDisplayRotationOffset", "display_rotation_offset", {0,0,0}, Parser.TypeArrayInt)
end

function ShipResDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    tbNewTemplate.szModelClassName = GetModelClassName(tbNewTemplate.szPawnClassName)
    return true
end

-- [EXPORT BEGIN]
function ShipResDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

return ShipResDataTable
