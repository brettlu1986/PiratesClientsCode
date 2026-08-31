-----------------------------------------------------
--File Name    : BattleBuffResDataTable.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-21
--Description  : 战斗Buff资源配置表
-----------------------------------------------------

local BattleBuffResDataTable = {}

local L10N = require("L10N")
local StringUtil = require("StringUtil")

BattleBuffResDataTable.szFileName = "common/res/battle_buff_res.tab"
BattleBuffResDataTable.bExportFunction = true

local STATUS_DESC_PARAM_PATTERN = "{((%w-):?(%w*)%.(%w*),-([^,]-))}"

function BattleBuffResDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId"                     , "id"                          , -1                , Parser.TypeInt)
    Parser:Define("l10nName"                , "name"                        , L10N.NullString   , Parser.TypeL10N)
    Parser:Define("l10nDesc"                , "desc"                        , L10N.NullString   , Parser.TypeL10N)
    Parser:Define("szIconRes"               , "icon_res"                    , nil               , Parser.TypeString)
    Parser:Define("szLensEffectRes"         , "lens_effect_res"             , nil               , Parser.TypeString)
    Parser:Define("szBeginSoundRes"         , "begin_sound_res"             , nil               , Parser.TypeString)
    Parser:Define("szPersistentSoundRes"    , "persistent_sound_res"        , nil               , Parser.TypeString)
    Parser:Define("nPersistentSoundEffectId", "persistent_sound_effect_id"  , -1                , Parser.TypeInt)
    Parser:Define("szEndSoundRes"           , "end_sound_res"               , nil               , Parser.TypeString)
    Parser:Define("tbHumanBeginFxIds"       , "human_begin_fx_id_list"      , nil               , Parser.TypeArrayInt)
    Parser:Define("tbHumanPersistentFxIds"  , "human_persistent_fx_id_list" , nil               , Parser.TypeArrayInt)
    Parser:Define("tbHumanEndFxIds"         , "human_end_fx_id_list"        , nil               , Parser.TypeArrayInt)

    Parser:Define("tbShipBeginFxIds"        , "ship_begin_fx_id_list"       , nil               , Parser.TypeArrayInt)
    Parser:Define("tbShipPersistentFxIds"   , "ship_persistent_fx_id_list"  , nil               , Parser.TypeArrayInt)
    Parser:Define("tbShipEndFxIds"          , "ship_end_fx_id_list"         , nil               , Parser.TypeArrayInt)

    Parser:Define("nMaterialEffectType"     , "material_effect_type"        , -1                , Parser.TypeInt)
    Parser:Define("nDialogId"               , "dialog_id"                   , -1                , Parser.TypeInt)
    Parser:Define("nPostProcessEffectId"    , "post_process_effect_id"      , -1                , Parser.TypeInt)
end

local function ParseDescInfos(l10nDesc)
    local tbDescInfos = {}
    local iteratorFunc = string.gmatch(L10N:ToString(l10nDesc), STATUS_DESC_PARAM_PATTERN)
    for szPlaceholder, szVariableName, szMainKey, szSubKey, szExpression in iteratorFunc do
        local tbDescInfo = {}
        tbDescInfo.szPlaceholder = szPlaceholder
        tbDescInfo.szMainKey = szMainKey
        tbDescInfo.szSubKey = szSubKey
        if not (StringUtil.IsEmptyString(szVariableName) or StringUtil.IsEmptyString(szExpression)) then
            tbDescInfo.fnCalcValue = function ()
                return string.format("function(%s) return %s end", szVariableName, szExpression)
            end
        end
        table.insert(tbDescInfos, tbDescInfo)
    end
    return (#tbDescInfos > 0) and tbDescInfos or nil
end

function BattleBuffResDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    tbNewTemplate.tbDescInfos = ParseDescInfos(L10N:ToString(tbNewTemplate.l10nDesc))
    return true
end

-- [EXPORT BEGIN]
function BattleBuffResDataTable:GetTemplate( nTemplateId )
    return self.tbContainer[nTemplateId]
end
-- [EXPORT END]

return BattleBuffResDataTable
