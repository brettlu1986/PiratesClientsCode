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
local GuideTriggerDataTable = {}

GuideTriggerDataTable.szFileName = "client/guide/guide_trigger.tab"
-- [EXPORT]
GuideTriggerDataTable.tbUIAnimEnd = {}


function GuideTriggerDataTable:OnEditorDefine(Parser)
    Parser:SetKey("szKey")
    Parser:Define("szKey", "key", "", Parser.TypeString)
    Parser:Define("szTriggerType", "trigger_type", "", Parser.TypeString)
    Parser:Define("szOpenUIName", "ui_name", "", Parser.TypeString, false)
    Parser:Define("tbPrefabName", "ui_prefab_name", "", Parser.TypeArrayString, false)
    Parser:Define("tbWidgetName", "ui_widget_name", nil, Parser.TypeArrayString, false)
    Parser:Define("szEventName", "event_name", nil, Parser.TypeString, false)
    Parser:Define("tbObjTemplateId", "obj_template_id", -1, Parser.TypeArrayInt, false)
    Parser:Define("nEnterBattleCount", "enter_battle_count", -1, Parser.TypeInt, false)
    Parser:Define("nModuleId", "module_id", -1, Parser.TypeInt, false)
    Parser:Define("nItemRoom", "item_room", -1, Parser.TypeInt, false)
    Parser:Define("tbItemId", "item_id", {}, Parser.TypeArrayInt, false)
    Parser:Define("bInteractionVisible", "interaction_visible", true, Parser.TypeBool, false)
    Parser:Define("bIsShipDurabilityFull", "ship_durability_full", true, Parser.TypeBool, false)
    Parser:Define("bIsShipSupplyFull", "ship_supply_full", true, Parser.TypeBool, false)
    Parser:Define("bIsEnable", "enable", true, Parser.TypeBool, false)
    Parser:Define("tbParam", "param", nil, Parser.TypeArrayString, false)
    Parser:Define("nSelectedTabIndex", "select_tab_index", nil, Parser.TypeInt, false)
    Parser:Define("nDungeonStepIndex", "dungeon_step_index", nil, Parser.TypeInt, false)
    Parser:Define("nInteractionId", "interaction_id", nil, Parser.TypeInt, false)
    Parser:Define("nSceneId", "scene_id", nil, Parser.TypeInt, false)
    Parser:Define("nLevel", "level", nil, Parser.TypeInt, false)
    Parser:Define("szNext", "next", "", Parser.TypeString, false)
    Parser:Define("bBreakWhenDissatisfy", "break_when_dissatisfy", false, Parser.TypeBool, false) 
end

function GuideTriggerDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local szTriggerType = Parser:Get("trigger_type", nil, Parser.TypeString)
    
    if szTriggerType == "UIAnimationEnd" then
        local szOpenUIName = Parser:Get("ui_name", nil, Parser.TypeString)
        local tbWidgetName = Parser:Get("tbWidgetName", "ui_widget_name", nil, Parser.TypeArrayString, false)
        local tbAnimEnd = self.tbUIAnimEnd[szOpenUIName]
        if not tbAnimEnd then
            tbAnimEnd = {}
            self.tbUIAnimEnd[szOpenUIName] = tbAnimEnd
        end
        if tbWidgetName then
            table.insert(tbAnimEnd, tbWidgetName[1])
        end
    end
    return true;
end

-- [EXPORT BEGIN]
function GuideTriggerDataTable:GetTemplate(szKey)
    return self.tbContainer[szKey]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function GuideTriggerDataTable:GetUIAnimEndTriggers()
    return self.tbUIAnimEnd
end
-- [EXPORT END]

return GuideTriggerDataTable