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
local GuideActionDataTable = {}

local GuideResDataTable = require("GuideResDataTable")

GuideActionDataTable.szFileName = "client/guide/guide_action.tab"

function GuideActionDataTable:OnEditorDefine(Parser)
    Parser:SetKey("szKey")
    Parser:Define("szKey", "key", "", Parser.TypeString)
    Parser:Define("szActionType", "action_type", "", Parser.TypeString)
    --Parser:Define("nModuleId", "module_id", "", Parser.TypeInt)
    Parser:Define("nLobbySubSystem", "lobby_sub_system", -1, Parser.TypeInt, false)
    Parser:Define("szUIName", "ui_name", "", Parser.TypeString, false)
    Parser:Define("tbPrefabName", "ui_prefab_name", "", Parser.TypeArrayString, false)
    Parser:Define("tbWidgetName", "ui_widget_name", "", Parser.TypeArrayString, false)
    Parser:Define("bEffctOnly", "effect_only", false, Parser.TypeBool, false)
    Parser:Define("tbScaleParent", "ui_scale_parent", "", Parser.TypeArrayString, false)
    Parser:Define("nMediaId", "media_id", 0, Parser.TypeInt, false)
    Parser:Define("l10nGuideText", "guide_text", "", Parser.TypeL10N, false)
    Parser:Define("nGuidePos", "guide_pos", 0, Parser.TypeInt, false)
    Parser:Define("bMaskEffect", "mask_effect", true, Parser.TypeBool, false)
    Parser:Define("szSelectWidgetName", "highlight_effect", "", Parser.TypeString, false)
    Parser:Define("nDragAngle", "drag_angle", -1, Parser.TypeInt, false)
    Parser:Define("nDragDirection", "drag_direction", 0, Parser.TypeInt, false)
    Parser:Define("bClickAnywhere", "click_anywhere", false, Parser.TypeBool, false)
    Parser:Define("bDoubleClick", "double_click", false, Parser.TypeBool, false)
    Parser:Define("nMatineeId", "matinee_id", -1, Parser.TypeInt, false)
    Parser:Define("tbQTEId", "qte_id", nil, Parser.TypeArrayInt, false)
    Parser:Define("nDialogId", "dialog_id", -1, Parser.TypeInt, false)
    Parser:Define("bDialogState", "is_dialog_state", true, Parser.TypeBool, false)
    Parser:Define("nOptionType", "option_type", -1, Parser.TypeInt, false)
    Parser:Define("nOptionUIId", "option_ui_id", -1, Parser.TypeInt, false)
    Parser:Define("tbListIndex", "list_index", 1, Parser.TypeArrayInt, false)
    Parser:Define("tbListData", "list_data", nil, Parser.TypeArrayInt, false)
    Parser:Define("nDelayTime", "delay_time", 0.1, Parser.TypeInt, false)
    Parser:Define("nAngleOffset", "angle_offset", 30, Parser.TypeInt, false)
    Parser:Define("nShowDuration", "show_duration", 0, Parser.TypeInt, false)
    Parser:Define("bEnable", "enable", true, Parser.TypeBool, false)
    Parser:Define("szVisibility", "visibility", "Visible", Parser.TypeString, false)
    Parser:Define("nSoundEffectId", "sound_effect_id", nil, Parser.TypeInt, false)
    Parser:Define("nRelatedTabIndex", "related_tab_index", nil, Parser.TypeInt, false)
    Parser:Define("tbUIAnim", "ui_anim", "", Parser.TypeArrayString, false)
    Parser:Define("tbParam", "param", nil, Parser.TypeArrayString, false)
    Parser:Define("bEnableEnd", "enable_end", true, Parser.TypeBool, false)
end

function GuideActionDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nGuidePictureId = Parser:Get("guide_pic_id", nil, Parser.TypeInt, false)
    if(nGuidePictureId ~= nil)then
        tbNewTemplate.szGuidePicPath = GuideResDataTable:GetTemplate(nGuidePictureId).szResPath
    end
    return true;
end

-- [EXPORT BEGIN]
function GuideActionDataTable:GetTemplate(szKey)
    return self.tbContainer[szKey]
end
-- [EXPORT END]

return GuideActionDataTable