
local SkillCastFailedText = {}

local UISetUtils = require("UISetUtils")
local GetL10NTextByKey = UISetUtils.GetL10NTextByKey

local L10N_UNKNOWN_TEXT         = GetL10NTextByKey("SkillCastFailedDef_UNKNOWN")
local L10N_UNKNOWN_SKILL_TEXT   = GetL10NTextByKey("SkillCastFailedDef_UNKNOWN_SKILL")

local L10N_TEXT = {
    GetL10NTextByKey("SkillCastFailedDef_SKILL_IN_CD"),
    GetL10NTextByKey("SkillCastFailedDef_CONSUMABLE_NOT_ENOUGH"),
    GetL10NTextByKey("SkillCastFailedDef_CAST_COUNT_NOT_ENOUGH"),
    GetL10NTextByKey("SkillCastFailedDef_HP_NOT_ENOUGH"),
    GetL10NTextByKey("SkillCastFailedDef_CHARGE_NOT_ENOUGH"),
    GetL10NTextByKey("SkillCastFailedDef_PROB_NOT_ENOUGH"),
    GetL10NTextByKey("SkillCastFailedDef_SKILL_CASTING"),
    GetL10NTextByKey("SkillCastFailedDef_CAN_NOT_FOUND_TRAGET_SHIP"),
    GetL10NTextByKey("SkillCastFailedDef_CAN_NOT_FOUND_TRAGET_IN_NEARBY"),
    GetL10NTextByKey("SkillCastFailedDef_BUFF_CONDITION_NOT_ENOUGH"),
    GetL10NTextByKey("SkillCastFailedDef_DONT_HAVE_BROKEN_PART"),
    GetL10NTextByKey("SkillCastFailedDef_SKILL_IS_DISABLED")
}

function SkillCastFailedText:GetText( nCastFailedReasonID )
    if nCastFailedReasonID == -1 then
        return L10N_UNKNOWN_TEXT
    elseif nCastFailedReasonID == 0 then
        return L10N_UNKNOWN_SKILL_TEXT
    end
    return L10N_TEXT[nCastFailedReasonID]
end

return SkillCastFailedText
