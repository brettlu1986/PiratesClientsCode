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

local SceneDataTable = {}
local L10N = require("L10N")

local DescriptorExporter = require("DescriptorExporter")

SceneDataTable.szFileName = "common/scene/scene.tab"

function SceneDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nID")
    Parser:Define("l10nName", "name", L10N.NullString, Parser.TypeL10N)
    Parser:Define("szName", "name", "Unknown", Parser.TypeString)
    Parser:Define("nID", "id", -1, Parser.TypeInt)
    Parser:Define("nResID", "res_id", -1, Parser.TypeInt)
    Parser:Define("nType", "type", -1, Parser.TypeInt)
    Parser:Define("szDescriptorPath", "descriptors", nil, Parser.TypeString)
    Parser:Define("szNavDataDir", "nav_data_dir", "", Parser.TypeString)
    Parser:Define("nUIMapId", "ui_map_id", -1, Parser.TypeInt)
    Parser:Define("nUIRadarMapId", "ui_radar_map_id", -1, Parser.TypeInt)
    Parser:Define("nFactionID", "faction_id", -1, Parser.TypeInt)
    Parser:Define("nBGMId", "bgm_id", -1, Parser.TypeInt)
    Parser:Define("bTownPortal", "town_portal", false, Parser.TypeBool)
end

function SceneDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    --本地化，先临时这样写，代码里有很多调用szName的地方，不确定是用FString还是FText
    tbNewTemplate.szName = L10N:ToString(tbNewTemplate.l10nName)
    return true
end

function SceneDataTable:OnEditorParseFinished()
    DescriptorExporter:ExportWildSceneData(self.tbContainer, "szLuaDescriptorPath")
end

function SceneDataTable:OnAllTablesExported()
    DescriptorExporter:OnAllDataTablesExported()
end

-- [EXPORT BEGIN]
function SceneDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end

function SceneDataTable:GetDescriptor(nId)
    local tbData = self.tbContainer[nId]
    if(tbData == nil or tbData.szLuaDescriptorPath == nil) then
        return nil
    end
    local tbRet = tbData.tbDescriptor
    if(tbRet == nil) then
        tbRet = require(tbData.szLuaDescriptorPath)
        tbData.tbDescriptor = tbRet
    end
    return tbRet
end
-- [EXPORT END]

return SceneDataTable
