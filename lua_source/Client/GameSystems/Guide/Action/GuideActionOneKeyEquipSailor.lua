-----------------------------------------------------
--File Name    : GuideActionOneKeyEquipSailor.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionFunctional         = require("GuideActionFunctional")
local GuideActionOneKeyEquipSailor  = luaclass("GuideActionOneKeyEquipSailor",GuideActionFunctional)

local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
----------------------------------------------------------
function GuideActionOneKeyEquipSailor:DoAction(tbTemplate)
    GuideActionOneKeyEquipSailor.super.DoAction(self, tbTemplate)
    local SailorComponent = GamePlayerSelfHelper:Get().SailorComponent
    if SailorComponent then
        self:DebugLog(" GuideActionOneKeyEquipSailor RequestSailorEquipOneKey")
		SailorComponent:RequestSailorEquipOneKey(0)
    end
end

return GuideActionOneKeyEquipSailor
