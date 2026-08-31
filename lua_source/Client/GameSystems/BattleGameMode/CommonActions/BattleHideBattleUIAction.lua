local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleHideBattleUIAction = luaclass("BattleHideBattleUIAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
-- local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")

BattleHideBattleUIAction.bHide = false
BattleHideBattleUIAction.bPlayAnim = false
-- BattleHideBattleUIAction.nWeaponEnabledOverlapId = -1

function BattleHideBattleUIAction:Parse(tbJsonData)
    self.bHide = tbJsonData.HideBattleUI
    self.bPlayAnim = tbJsonData.playAnim
    return self.bHide ~= nil and  self.bPlayAnim ~= nil
end

function BattleHideBattleUIAction:Execute()
    local bVisible = not self.bHide
    BattleOperationHelper:PrintLog(self, "HideBattleUI: "..(self.bHide and "false" or "true"))
    EventManager:OnFireEvent(ClientEventDef.EV_UI_ATTACK_VISIBLE, bVisible, self.bPlayAnim)
    -- local tbPlayerSelf = GamePlayerSelfHelper:Get()
    -- local PropertyWrapperHelper = tbPlayerSelf.BattleStatusComponent.PropertyWrapperHelper
    -- if not bVisible then
    --     self.nWeaponEnabledOverlapId = PropertyWrapperHelper:Overlap_Override("bWeaponEnabled", false)
    -- elseif self.nWeaponEnabledOverlapId > -1 then
    --     PropertyWrapperHelper:RemoveOverlap("bWeaponEnabled", self.nWeaponEnabledOverlapId)
    --     self.nWeaponEnabledOverlapId = -1
    -- end
    return true
end


return BattleHideBattleUIAction
