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
local NPCDataTable = {}
local StringUtil = require("StringUtil")
local DataTableExporter = require("DataTableExporter")
local TemplateTypeDef = require("TemplateTypeDef")
local BattleItemDataTable = require("BattleItemDataTable")
local L10N = require("L10N")
-- local NPCIni = require("NPCIni")

NPCDataTable.szFileName = "common/npc/index.tab"
NPCDataTable.tbSubTable = {}
NPCDataTable.bLoadingSubFile = false

NPCDataTable.NPC_TYPE_COMMON = 1
NPCDataTable.NPC_TYPE_BOSS = 2

local function ParseDialog(szDialog)
    if not szDialog or string.len( szDialog ) <= 0 then
        return  nil
    end
    local tbTemp = StringUtil.Split(szDialog, "|")
    if #tbTemp <= 0 then
        return nil
    end
    local tbRet = {}
    for _,v in ipairs(tbTemp) do
        table.insert(tbRet, tonumber(v))
    end
    return tbRet
end

local function ParseUI(szUI)
    if(szUI == nil) then
        return nil
    end

    local nPos = string.find(szUI, ',')
    if(nPos == nil or nPos < 0) then
        return tonumber(szUI)
    end

    local tbRet = StringUtil.Split(szUI, ",")
    local nCount = #tbRet
    for i=1, nCount do
        tbRet[i] = tonumber(tbRet[i])
    end
    return tbRet
end

function NPCDataTable:OnEditorSubTableDefine(Parser)
    Parser:Define("l10nName", "name", L10N.NullString, Parser.TypeL10N)
    Parser:Define("szName", "name", "Unknown", Parser.TypeString)
    Parser:Define("nTemplateID", "id", -1, Parser.TypeInt)
    Parser:Define("nTypeID", "type_id", -1, Parser.TypeInt, false)
    Parser:Define("nInitialHpPercent", "initial_hp_percent", 1, Parser.TypeInt, false)
    Parser:Define("nInteractionType", "interaction", 0, Parser.TypeInt, false)
    Parser:Define("nAITemplateGradeId", "npc_template_grade", -1, Parser.TypeInt, false)
    Parser:Define("nPartnerAIId", "partner_ai_template", -1, Parser.TypeInt, false)
    Parser:Define("nHeadIcon", "head_icon", -1, Parser.TypeInt, false)
    Parser:Define("nDistance", "distance", -1, Parser.TypeInt, false)
    Parser:Define("nType", "type", 0, Parser.TypeInt)
    Parser:Define("nWorldMapDisplay", "world_map_display", 0, Parser.TypeInt, false)
    Parser:Define("nRadarMapDisplay", "radar_map_display", 0, Parser.TypeInt, false)
    Parser:Define("nIconIdInMap", "icon_id_in_map", 0, Parser.TypeInt, false)
    Parser:Define("szNameInMap", "name_in_map", nil, Parser.TypeString, false)
    Parser:Define("bIsShowUIEnergy", "showui_energy", true, Parser.TypeBool, false)
    Parser:Define("bUnbeatable", "unbeatable", false, Parser.TypeBool, false)
    Parser:Define("bKeyTarget", "is_key_target", false, Parser.TypeBool, false)
    Parser:Define("nShipItemId", "ship_item_id", -1, Parser.TypeInt, false)
    Parser:Define("nInitItemRandomGroupId", "init_item_random_group", -1, Parser.TypeInt, false)
    Parser:Define("nInitState", "init_state", 1, Parser.TypeInt, false)
    Parser:Define("szHeadNameColor", "head_name_color", nil, Parser.TypeString, false)
    Parser:Define("nHeadNameFontSize", "head_name_font_size", nil, Parser.TypeInt, false)
    Parser:Define("nHideDelayTimeAfterDeath", "hide_delay_time_after_death", 0, Parser.TypeInt, false)
end

local function OnEditorParseSubTableLine(self, Parser, tbContainer, tbNewTemplate)
    local nTemplateID = tbNewTemplate.nTemplateID
    --本地化，先临时这样写，代码里有很多调用szName的地方，不确定是用FString还是FText
    tbNewTemplate.szName = L10N:ToString(tbNewTemplate.l10nName)
    --这里要修改 因为没有填写表格 所以要这要转换一下
    local nBoosType = Parser:Get("is_boss", 0, Parser.TypeInt, false);

    if nBoosType == 2 then
        tbNewTemplate.bIsBoos = true
    else
        tbNewTemplate.bIsBoos = false
    end

    tbNewTemplate.bIsBattleNPC = Parser:Get("is_battle_npc", false, Parser.TypeBool, false);

    tbNewTemplate.UI = ParseUI(Parser:Get("ui", nil, Parser.TypeString, false))
    tbNewTemplate.tbDialogs = ParseDialog(Parser:Get("dialog_id", nil, Parser.TypeString, false))
    tbNewTemplate.tbWorldMapDisplayLevel = StringUtil.ParseDataByComma(Parser:Get("world_map_display_level", nil, Parser.TypeString, false))

    -- 设置船的类型id
    local nShipItemId = tbNewTemplate.nShipItemId
    if nShipItemId ~= nil and nShipItemId > 0 then
        local tbItemTemplate = BattleItemDataTable:GetTemplate(nShipItemId)
        if tbItemTemplate then
            tbNewTemplate.nShipTypeId = tbItemTemplate.nShipId
        else
            error("Cannot find ship item id!".. nShipItemId)
        end
    end

    -- 船的npc战斗属性，如果填了就覆盖原有的船基础值，不填就不覆盖
    if tbNewTemplate.nType == TemplateTypeDef.SHIP and tbNewTemplate.nTypeID > 0 then
        local tbNpcFightData = {}
        tbNpcFightData.nShipHp = Parser:Get("ship_hp", -1, Parser.TypeInt, false);
        tbNpcFightData.nMainGunDamage = Parser:Get("main_gun_damage", -1, Parser.TypeInt, false);
        tbNpcFightData.nNoseGunDamage = Parser:Get("nose_gun_damage", -1, Parser.TypeInt, false);
        tbNpcFightData.nSternGunDamage = Parser:Get("stern_gun_damage", -1, Parser.TypeInt, false);
        tbNpcFightData.nTorpedoDamage = Parser:Get("torpedo_damage", -1, Parser.TypeInt, false);
        tbNpcFightData.nMainGunLoadingTime = Parser:Get("main_gun_loading_time", -1, Parser.TypeInt, false);
        tbNpcFightData.nNoseGunLoadingTime = Parser:Get("nose_gun_loading_time", -1, Parser.TypeInt, false);
        tbNpcFightData.nSternGunLoadingTime = Parser:Get("stern_gun_loading_time", -1, Parser.TypeInt, false);
        tbNpcFightData.nTorpedoLoadingTime = Parser:Get("torpedo_loading_time", -1, Parser.TypeInt, false);
        tbNpcFightData.nHalfSailLinearSpeed = Parser:Get("half_sail_linear_speed", -1, Parser.TypeInt, false);
        tbNpcFightData.nFullSailLinearSpeed = Parser:Get("full_sail_linear_speed", -1, Parser.TypeInt, false);
        tbNpcFightData.nAngularSpeed = Parser:Get("angular_speed", -1, Parser.TypeInt, false);

        tbNewTemplate.tbNpcFightData = tbNpcFightData
    end

    -- --携带物品
    -- local szItems = Parser:Get("items", nil, Parser.TypeString, false)
    -- if szItems then
    --     local tbItemList = {}
    --     local tbItems = StringUtil.Split(szItems, "|")
    --     if tbItems then
    --         for k, v in ipairs(tbItems) do
    --             local tbItem = StringUtil.Split(v, ",")
    --             tbItem[1] = tonumber(tbItem[1])
    --             tbItem[2] = tonumber(tbItem[2])
    --             if not tbItem[1] or not tbItem[2] then
    --                 logerror("NPCDataTable item parse failed ", nTemplateID)
    --             end
    --             table.insert(tbItemList, tbItem)
    --         end
    --     end
    --     tbNewTemplate.tbItemList = tbItemList
    -- end

    if(nTemplateID < self.nMinId or nTemplateID > self.nMaxId) then
        logerror("NPCDataTable parse failed, the range of id is invalid", nTemplateID)
        return false
    end
    if(self.tbContainer[nTemplateID] ~= nil) then
        logerror("NPCDataTable parse failed, the id is duplicated", nTemplateID)
        return false
    end
    tbContainer[nTemplateID] = tbNewTemplate
    return true;
end

function NPCDataTable:OnEditorDefine(Parser)
    Parser:Define("nMinId", "id_begin", -1, Parser.TypeInt)
    Parser:Define("nMaxId", "id_end", -1, Parser.TypeInt)
    Parser:Define("szPath", "path", nil, Parser.TypeString)
end

function NPCDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if(self.bLoadingSubFile) then
        return OnEditorParseSubTableLine(self, Parser, tbContainer, tbNewTemplate)
    end

    table.insert(self.tbSubTable, tbNewTemplate)
    return true;
end

-- [EXPORT BEGIN]
function NPCDataTable:GetTemplate(ID)
    return self.tbContainer[ID]
end
-- [EXPORT END]

function NPCDataTable:OnEditorParseFinished()
    if(self.bLoadingSubFile) then
        return
    end

    local szOldPath = self.szFileName
    self.bLoadingSubFile = true
    local fnOldDefine = self.OnEditorDefine

    local tbData
    local tbDatas = self.tbSubTable
    local nCount = #tbDatas
    for i=1, nCount do
        tbData = tbDatas[i]
        self.nMinId = tbData.nMinId
        self.nMaxId = tbData.nMaxId
        self.szFileName = tbData.szPath

        self.OnEditorDefine = self.OnEditorSubTableDefine
        if(not DataTableExporter:Load(self)) then
            logerror("NPCDataTable load sub table failed", self.szFileName)
            assert(false)
            return
        end
    end

    self.nMinId = nil
    self.nMaxId = nil
    self.bLoadingSubFile = false
    self.szFileName = szOldPath
    self.tbSubTable = {}

    self.OnEditorDefine = fnOldDefine
end

return NPCDataTable
