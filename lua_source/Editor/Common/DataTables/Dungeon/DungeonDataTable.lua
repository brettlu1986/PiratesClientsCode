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
local DungeonDataTable = {}
local L10N = require("L10N")

local DescriptorExporter = require("DescriptorExporter")
-- local StringUtil = require("StringUtil")

DungeonDataTable.szFileName = "common/dungeon/dungeon.tab"
DungeonDataTable.bEnableIterateKey = true

function DungeonDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nID")
    Parser:Define("l10nName", "name", L10N.NullString, Parser.TypeL10N)
    Parser:Define("szName", "name", "Unknown", Parser.TypeString)
    Parser:Define("nID", "id", -1, Parser.TypeInt)
    Parser:Define("nResID", "res_id", -1, Parser.TypeInt)
    Parser:Define("szLogicLevelName", "logic_level_name", "", Parser.TypeString)
    Parser:Define("nSubId", "sub_id", -1, Parser.TypeInt)
    Parser:Define("tbModes", "modes", {}, Parser.TypeArrayInt)
    Parser:Define("nUIRadarMapId", "ui_radar_map_id", -1, Parser.TypeInt)
    Parser:Define("nUIMapId", "ui_map_id", -1, Parser.TypeInt)
    Parser:Define("nBGMId", "bgm_id", -1, Parser.TypeInt)
    Parser:Define("nType", "type", 0, Parser.TypeInt)
    Parser:Define("bCollisionDamage", "collision_damage", false, Parser.TypeBool)
    Parser:Define("bTeammateDamage", "teammate_damage", false, Parser.TypeBool)
    Parser:Define("tbObjectiveToast", "objective_toast", {}, Parser.TypeArrayInt)
    Parser:Define("tbObjectivePanel", "objective_panel", {}, Parser.TypeArrayInt)
    Parser:Define("szLoadingTopUI", "loading_top_ui", nil, Parser.TypeString)
    Parser:Define("nCountDownTime", "countdown_time", 0, Parser.TypeInt)
    Parser:Define("nShipPlayerAI", "ship_player_ai", -1, Parser.TypeInt)
    Parser:Define("nPlayerAIPath", "player_ai_path", -1, Parser.TypeInt)
    Parser:Define("nNpcDialogBoardID", "dialog_board_id", -1, Parser.TypeInt, false)
    Parser:Define("bControlHeadInfo", "control_head_info", false, Parser.TypeBool)
    -- Parser:Define("nNoobParachutingAreaId", "noob_parachuting_area_id", -1, Parser.TypeInt, false)
    -- Parser:Define("szNoobResource", "noob_resource", "", Parser.TypeString)
    Parser:Define("nInitItem", "init_item", 1, Parser.TypeInt)      -- 不填默认1
    Parser:Define("szUIThumbnail", "ui_thumbnail", "", Parser.TypeString)
end

function DungeonDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if #tbNewTemplate.tbObjectiveToast ~= #tbNewTemplate.tbObjectivePanel then
        logerror("Battle Objective config is error, template id =", tbNewTemplate.nID)
    end
    -- local tbNoobResource = StringUtil.Split(tbNewTemplate.szNoobResource, ',')
    -- tbNewTemplate.tbNoobResource = tbNoobResource
    tbNewTemplate.szName = L10N:ToString(tbNewTemplate.l10nName)
    return true
end

function DungeonDataTable:OnEditorParseFinished()
    DescriptorExporter:ExportDungeonSceneData(self.tbContainer, "szLuaDescriptorPath")

    local DungeonModeDataTable = require("DungeonModeDataTable")
    local tbContainer = self.tbContainer
    for nId, tbTemplate in pairs(tbContainer) do
        for _, nMode in ipairs(tbTemplate.tbModes) do
            if DungeonModeDataTable:GetTemplate(nMode) == nil then
                error("DungeonDataTable:OnEditorParseFinished failed, can not find dungeon mode id: "..nMode..". Dungeon id: "..nId)
                return
            end
            if nMode <= 0 then
                error("DungeonDataTable:OnEditorParseFinished failed, can not set dungeon mode id less than or equal to zero: "..nMode..". Dungeon id: "..nId)
                return
            end
        end

        if #tbTemplate.tbModes > 0 then
            tbTemplate.tbLuaDescriptorPaths = {}
            for _, nMode in ipairs(tbTemplate.tbModes) do
                local tbAllDescriptors = {}
                tbTemplate.tbLuaDescriptorPaths[nMode] = {}
                local singleModeData = tbTemplate.tbLuaDescriptorPaths[nMode]
                local tbModeTemplate = DungeonModeDataTable:GetTemplate(nMode)
                singleModeData.nResID = tbModeTemplate.nResID
                singleModeData.szLogicLevelName = tbModeTemplate.szLogicLevelName
                DescriptorExporter:ExportSingleDungeonSceneData(tbTemplate.tbLuaDescriptorPaths[nMode], tbAllDescriptors, "szLuaDescriptorPath")
            end
        end
    end
end

-- [EXPORT BEGIN]
function DungeonDataTable:SetMode(nId, nMode)
    local tbTemplate = self.tbContainer[nId]
    local DungeonModeDataTable = require("DungeonModeDataTable")
    nMode = nMode or -1
    local tbModeTemplate = DungeonModeDataTable:GetTemplate(nMode)
    if tbModeTemplate then
        tbTemplate.nResID = tbModeTemplate.nResID
        tbTemplate.szLogicLevelName = tbModeTemplate.szLogicLevelName
        tbTemplate.nUIRadarMapId = tbModeTemplate.nUIRadarMapId
        tbTemplate.nUIMapId = tbModeTemplate.nUIMapId
        tbTemplate.nMode = nMode
    else
        tbTemplate.nMode = nil
    end
    log("DungeonDataTable:SetMode set mode", tbTemplate.nMode, "to dungeon", nId)
end

function DungeonDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end

function DungeonDataTable:GetDescriptor(nId)
    local tbData = self.tbContainer[nId]
    if tbData == nil then
        return nil
    end
    if #tbData.tbModes > 0 then
        local nMode = tbData.nMode
        tbData = tbData.tbLuaDescriptorPaths
        if nMode == nil or tbData == nil then
            return nil
        end
        tbData = tbData[nMode]
    end
    local tbRet = tbData.tbDescriptor
    if(tbRet == nil and tbData.szLuaDescriptorPath ~= nil) then
        tbRet = require(tbData.szLuaDescriptorPath)
        tbData.tbDescriptor = tbRet
    end
    return tbRet
end
-- [EXPORT END]

-- function DungeonDataTable:OnGameRequired()
--     local SceneResDataTable = require("SceneResDataTable")
--     local tbContainer = self.tbContainer
--     local szFolderName

--     for nId, tbTemplate in pairs(tbContainer) do
--         local tbSceneResData = SceneResDataTable:GetTemplate(tbTemplate.nResID)
--         if(tbSceneResData == nil) then
--             error("DungeonDataTable:OnGameRequired failed, can not find scene res id", tbTemplate.nResID)
--             return
--         end
--         szFolderName = szSceneJsonRootPath .. tbSceneResData.szMapName
--     end
-- end

return DungeonDataTable
