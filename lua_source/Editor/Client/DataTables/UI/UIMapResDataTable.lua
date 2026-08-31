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
local UIMapResDataTable = {}

--local StringUtil = require("StringUtil")

-- [EXPORT]
--local nResCount = 2


UIMapResDataTable.szFileName = "client/ui/map/ui_map_res.tab"
-- [EXPORT]
UIMapResDataTable.MapType = { WorldMap = "WorldMap", RadarMap = "RadarMap" }

function UIMapResDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nResId")
    Parser:Define("nResId", "id", -1, Parser.TypeInt)
    Parser:Define("szMapType", "map_type", "", Parser.TypeString)
    Parser:Define("nMode", "mode", 1, Parser.TypeInt, false)
    Parser:Define("szPath", "path", "", Parser.TypeString)
    Parser:Define("szCommonPath", "common_path", "", Parser.TypeString, false)
    Parser:Define("nSplitNum", "split_num", 16, Parser.TypeInt, false)
    Parser:Define("nScope", "scope", 0, Parser.TypeInt)
    Parser:Define("nLandScope", "land_scope", 0, Parser.TypeInt, false)
    Parser:Define("nTransportScope", "transport_scope", 0, Parser.TypeInt, false)
    Parser:Define("nTransportMaxScope", "transport_max_scope", 0, Parser.TypeInt, false)
    Parser:Define("nCoordInterval", "coordinate_interval", 0, Parser.TypeInt)
    Parser:Define("nMapSizeX", "map_size_x", 1, Parser.TypeInt)
    Parser:Define("nMapSizeY", "map_size_y", 1, Parser.TypeInt)
    Parser:Define("nUIMapOffsetX", "ui_map_offset_x", 1, Parser.TypeInt)
    Parser:Define("nUIMapOffsetY", "ui_map_offset_y", 1, Parser.TypeInt)
    Parser:Define("nUIMapSizeX", "ui_map_size_x", 1820, Parser.TypeInt, false)
    Parser:Define("nUIMapSizeY", "ui_map_size_y", 1024, Parser.TypeInt, false)
    Parser:Define("bIsShowShotRange", "is_show_shot_range", false, Parser.TypeBool)
    Parser:Define("bIsShowVisibleRange", "is_show_visible_range", false, Parser.TypeBool)
    Parser:Define("bIsSlideToZoom", "is_slide_to_zoom", false, Parser.TypeBool)
    Parser:Define("nCoreAreaSizeX", "core_area_size_x", -1, Parser.TypeInt, false)
    Parser:Define("nCoreAreaSizeY", "core_area_size_y", -1, Parser.TypeInt, false)
    Parser:Define("nDialogId", "dialog_id", -1, Parser.TypeInt, false)
end

function UIMapResDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    -- tbNewTemplate.tbResPath = {}
    -- for i=1,nResCount do
    --     local path = Parser:Get("path_"..i, "", Parser.TypeString)
    --     if(path ~= nil and path ~= "")then
    --         table.insert(tbNewTemplate.tbResPath,path)
    --         if(GWithEditor)then
    --             local tbFileInfo = StringUtil.Split(path, '\'')
    --             local StartIndex, _ = string.find(tbFileInfo[2], ".", 1, true)
    --             local SubString = string.sub(tbFileInfo[2], 1, StartIndex - 1)
    --             SubString = string.gsub(SubString..".uasset", "/Game/", "")
    --             if not tbFileInfo or not tbFileInfo[2] or not file_exists(SubString) then
    --                 logerror("[UI] map_res tab, ui map res is nil,path="..tostring(path))
    --                 return false
    --             end
    --         end
    --     end
        
    -- end
    if tbNewTemplate.nLandScope == 0 then
        tbNewTemplate.nLandScope = tbNewTemplate.nScope
    end
    if tbNewTemplate.nTransportScope == 0 then
        tbNewTemplate.nTransportScope = tbNewTemplate.nScope
    end
    if tbNewTemplate.szCommonPath == "" then
        tbNewTemplate.szCommonPath = tbNewTemplate.szPath
    end
    return true;
end

-- [EXPORT BEGIN]
function UIMapResDataTable:GetTemplate(nResId)
  
    return self.tbContainer[nResId] 
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function UIMapResDataTable:LoadMapRes(nResId)
    --local Template = self.tbContainer[nResId]
    local tbMapRes = {}
    -- local nCount = #Template.tbResPath
    -- -- local nSizeX = 0
    -- -- local nSizeY
    -- for i=1,nCount do
    --     local Tex = Template.tbResPath[i]:load()
    --     if(Tex ~= nil)then
    --         table.insert(tbMapRes, Tex)
    --         -- nSizeX = nSizeX + Tex:Blueprint_GetSizeX()
    --         -- nSizeY = Tex:Blueprint_GetSizeY()
    --     end
    -- end
    -- --Template.nUIMapSizeX = math.max(nSizeX,DefaultImageSize.X)
    -- --Template.nUIMapSizeY = math.max(nSizeY,DefaultImageSize.Y)
    return tbMapRes
end
-- [EXPORT END]

return UIMapResDataTable
