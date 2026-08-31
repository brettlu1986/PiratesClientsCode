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
local BattleItemResDataTable = {}

BattleItemResDataTable.szFileName = "common/ffa/res/item_res.tab"

function BattleItemResDataTable:OnEditorDefine(Parser)
    -- Parser:SetKey("nResId")
    Parser:Define("nResId", "res_id", -1, Parser.TypeInt)
    Parser:Define("nDungeonId", "dungeon_id", -1, Parser.TypeInt)
    Parser:Define("szIconPath", "icon", "", Parser.TypeString)
    Parser:Define("szDisplayClassName",  "display_class_name", "", Parser.TypeString)
    Parser:Define("szDisplayMeshName",  "display_mesh_name", "", Parser.TypeString)
    Parser:Define("szOceanDisplayMeshName",  "ocean_display_mesh_name", "", Parser.TypeString)
    Parser:Define("szEquipClassName", "equip_class_name", "", Parser.TypeString)
    Parser:Define("szLaunchClassName", "launch_class_name", "", Parser.TypeString)
    Parser:Define("szSilhouettePath", "silhouette_path", nil, Parser.TypeString)
    Parser:Define("szEquipmentDisplayPath", "equipment_display_path", nil, Parser.TypeString)
    Parser:Define("nPickSoundID", "pick_sound", -1, Parser.TypeInt)
    -- Parser:Define("nResType", "res_type", -1, Parser.TypeInt)
end

function BattleItemResDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nResId = tbNewTemplate.nResId
    if self.tbContainer[nResId] == nil then
        self.tbContainer[nResId] = {}
    end
    self.tbContainer[nResId][tbNewTemplate.nDungeonId] = tbNewTemplate
    return true
end

-- [EXPORT BEGIN]
function BattleItemResDataTable:GetTemplate(nResId, nDungeonId)
    if self.tbContainer[nResId] ~= nil then
        if nDungeonId ~= nil and self.tbContainer[nResId][nDungeonId] then
            return  self.tbContainer[nResId][nDungeonId]
        else
            return self.tbContainer[nResId][-1]
        end
    else
        logerror("BattleItemResDataTable:GetTemplate failed ", nResId, nDungeonId)
    end
end
-- [EXPORT END]

return BattleItemResDataTable
