local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleInteractionDialogTarget = luaclass("BattleInteractionDialogTarget", BattleTargetBaseClass)

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")


function BattleInteractionDialogTarget:Init()
    BattleInteractionDialogTarget.super.Init(self)
    self.szName = "BattleInteractionDialogTarget"
end

function BattleInteractionDialogTarget:RegisterEvent()
    BattleInteractionDialogTarget.super.RegisterEvent(self)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_INTERACTIONDLG_END, self, self.OnDlgEnd)
end

function BattleInteractionDialogTarget:Parse(tbJsonData)
   return true
end

function BattleInteractionDialogTarget:OnDlgEnd()
    self:Complete()
end

function BattleInteractionDialogTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_INTERACTIONDLG_END, self, self.OnDlgEnd)
end

return BattleInteractionDialogTarget