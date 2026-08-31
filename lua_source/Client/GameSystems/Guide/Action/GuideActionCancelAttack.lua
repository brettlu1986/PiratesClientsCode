-----------------------------------------------------
--File Name    : GuideActionCancelAttack.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFunctional     = require("GuideActionFunctional")
local GuideActionCancelAttack   = luaclass("GuideActionCancelAttack", GuideActionFunctional)

--import
local BattleHumanWeaponSystemNew = require("BattleHumanWeaponSystemNew_C")
local ClientEventDef             = require("ClientEventDef")

function GuideActionCancelAttack:DoAction(tbTemplate)
    GuideActionCancelAttack.super.DoAction(self, tbTemplate)
    BattleHumanWeaponSystemNew:RequestCancelAttack()
    self.EventHelper:FireEvent(ClientEventDef.EV_RELEASE_FIGHT_BTN)
end

return GuideActionCancelAttack
