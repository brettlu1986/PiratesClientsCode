-----------------------------------------------------
--File Name    : SkillResDataTable.lua
--Author       : Song Fuhao
--Create Time  : 2017-04-18
--Description  : 技能资源配置表
-----------------------------------------------------
local SkillResDataTable = {}

local L10N = require("L10N")

SkillResDataTable.szFileName = "common/res/skill_res.tab"

function SkillResDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("bDisplay", "display", true, Parser.TypeBool)
    Parser:Define("l10nName", "name", L10N.NullString, Parser.TypeL10N)
    Parser:Define("l10nDesc", "desc", L10N.NullString, Parser.TypeL10N)
    Parser:Define("szIconRes", "icon_res", nil, Parser.TypeString)
    Parser:Define("szPressedIconRes", "pressed_icon_res", nil, Parser.TypeString)
    Parser:Define("szDisplayIconRes", "display_icon_res", nil, Parser.TypeString)
    Parser:Define("szDisplayBgRes", "display_bg_res", nil, Parser.TypeString)
    Parser:Define("szMontageRes", "montage_res", nil, Parser.TypeString)
    Parser:Define("tbFxIds", "fx_id_list", nil, Parser.TypeArrayInt)
    Parser:Define("tbTargetFxIds", "target_fx_id_list", nil, Parser.TypeArrayInt)
    Parser:Define("szSoundRes", "sound_res", nil, Parser.TypeString)
    Parser:Define("nDialogId", "dialog_id", -1, Parser.TypeInt)
end

-- 验证配置表填写是否正确
function SkillResDataTable:OnEditorParseFinished()
    for nId, tbTemplate in pairs(self.tbContainer) do
        if tbTemplate.bDisplay and (tbTemplate.szDisplayIconRes == nil) then
            error("cannot find skill display icon res, skill res id:" .. nId)
        end
    end
end

-- [EXPORT BEGIN]
function SkillResDataTable:GetTemplate( nTemplateId )
    return self.tbContainer[nTemplateId]
end
-- [EXPORT END]

return SkillResDataTable
