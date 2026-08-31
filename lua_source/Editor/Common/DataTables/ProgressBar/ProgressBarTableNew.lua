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

local ProgressBarTableNew = {}

ProgressBarTableNew.szFileName = "common/progress_bar/progress_bar_new.tab"

function ProgressBarTableNew:OnEditorDefine(Parser)
    Parser:SetKey("nID")
    Parser:Define("nID", "id", -1, Parser.TypeInt)
    Parser:Define("nTime", "time", -1, Parser.TypeInt)
    Parser:Define("nResId", "res_id", -1, Parser.TypeInt)
    Parser:Define("nHumanSoundId", "huamn_sound_id", -1, Parser.TypeInt)
    Parser:Define("nHumanSoundDelay", "huamn_sound_delay", -1, Parser.TypeFloat)
    Parser:Define("nShipSoundId", "ship_sound_id", -1, Parser.TypeInt)
    Parser:Define("nShipSoundDelay", "ship_sound_delay", -1, Parser.TypeFloat)
    Parser:Define("l10nText", "text", nil, Parser.TypeL10N)
    Parser:Define("nTextType", "text_type", -1,  Parser.TypeInt)
    Parser:Define("nHumanStandActionKey", "human_stand_action_key", nil, Parser.TypeString)
    Parser:Define("nHumanCrouchActionKey", "human_crouch_action_key", nil, Parser.TypeString)
    Parser:Define("nHumanCrawlActionKey", "human_crawl_action_key", nil, Parser.TypeString)
    Parser:Define("nHumanCarrierActionKey", "human_carrier_action_key", nil, Parser.TypeString)
    Parser:Define("nShipActionKey", "ship_action_key", nil, Parser.TypeString)
    Parser:Define("nHumanEffectId", "human_effect_id", -1, Parser.TypeInt)
    Parser:Define("nShipEffectId", "ship_effect_id", -1, Parser.TypeInt)
    Parser:Define("nHumanAbortId", "human_abort_id", -1, Parser.TypeInt)
    Parser:Define("nShipAbortId", "ship_abort_id", -1, Parser.TypeInt)
    Parser:Define("nHumanProhibitId", "human_prohibit_id", -1, Parser.TypeInt)
    Parser:Define("nShipProhibitId", "ship_prohibit_id", -1, Parser.TypeInt)
    Parser:Define("szAttachedActor", "attached_actor", nil, Parser.TypeString)
    Parser:Define("bHumanCrawlToCrouch", "human_crawl_to_crouch", false, Parser.TypeBool)
    Parser:Define("nShipInterruptedDamage", "ship_interrupted_damage", 0, Parser.TypeFloat)
    Parser:Define("bStartInDying", "start_in_dying", false, Parser.TypeBool)
    Parser:Define("bStartInShipFiring", "start_in_ship_firing", false, Parser.TypeBool)
    Parser:Define("bStopMoveImmediately", "stop_move_immediately", false, Parser.TypeBool)
    Parser:Define("bIgnoreAbortByMove", "ignore_abort_by_move", false, Parser.TypeBool)
    Parser:Define("nAbortByMovementType", "abort_by_movement_type", 0, Parser.TypeInt)
    Parser:Define("bRefreshPickList", "refresh_list", false, Parser.TypeBool)
    Parser:Define("nHumanBuffId", "human_buff_id", -1, Parser.TypeInt)
    Parser:Define("nShipBuffId", "ship_buff_id", -1, Parser.TypeInt)
    Parser:Define("nVehicleBuffId", "vehicle_buff_id", -1, Parser.TypeInt)
    Parser:Define("nUseParentBoneMode", "use_parent_bone_mode", 0, Parser.TypeInt)
    Parser:Define("szFinishUIName", "finish_ui_name", nil, Parser.TypeString)
    Parser:Define("nFinishSoundId", "finish_sound_id", -1, Parser.TypeInt)
    Parser:Define("nAbortEffectId", "abort_effect_id", -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function ProgressBarTableNew:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

return ProgressBarTableNew
