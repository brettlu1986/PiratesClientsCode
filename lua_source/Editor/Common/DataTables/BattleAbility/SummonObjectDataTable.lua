-----------------------------------------------------
--File Name    : SummonObjectDataTable.lua
--Author       : Song Fuhao
--Create Time  : 2017-04-18
--Description  : 召唤物配置表
-----------------------------------------------------

local SummonObjectDataTable = {}

SummonObjectDataTable.szFileName = "common/battle_ability/summon_object.tab"
SummonObjectDataTable.bEnableIterateKey = true

function SummonObjectDataTable:OnEditorDefine(Parser)
    Parser:SetKey("Id")
    Parser:Define("Id", "id", -1, Parser.TypeInt)
    Parser:Define("MaxEffectCount", "max_effect_count", 1, Parser.TypeInt)
    Parser:Define("Range", "range", 0, Parser.TypeInt)
    Parser:Define("MoveDistance", "move_distance", 0, Parser.TypeInt)
    Parser:Define("DeployTime", "deploy_time", 1, Parser.TypeInt)
    Parser:Define("DelayActiveTime", "delay_active_time", 1, Parser.TypeInt)
    Parser:Define("LifeTime", "life_time", 1, Parser.TypeInt)
    Parser:Define("VisibleDistance", "visible_distance", 1, Parser.TypeInt)
    Parser:Define("AutoTrigger", "auto_trigger", false, Parser.TypeBool)
    Parser:Define("TriggerByShot", "trigger_by_shot", false, Parser.TypeBool)
    Parser:Define("ResPath", "res_path", "", Parser.TypeString)
    Parser:Define("StatusId", "status_id", 1, Parser.TypeInt)
    Parser:Define("HideRange", "hide_range", false, Parser.TypeBool)
end

-- [EXPORT BEGIN]
function SummonObjectDataTable:GetTemplate( nTemplateId )
    return self.tbContainer[nTemplateId]
end
-- [EXPORT END]

return SummonObjectDataTable
