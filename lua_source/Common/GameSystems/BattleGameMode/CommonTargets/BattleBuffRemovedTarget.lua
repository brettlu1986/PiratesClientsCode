local luaclass = require("luaclass")
local BattleTargetBase = require("BattleTargetBase")
local BattleBuffRemovedTarget = luaclass("BattleBuffRemovedTarget", BattleTargetBase)

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local BattleBlackboard = require("BattleBlackboard")

BattleBuffRemovedTarget.szSetObjKey  = nil
BattleBuffRemovedTarget.nBuffTemplateId = 0

function BattleBuffRemovedTarget:Init()
    BattleBuffRemovedTarget.super.Init(self)
    self.szName = "BattleBuffRemovedTarget"
end

function BattleBuffRemovedTarget:Parse(tbJsonData)
    self.szSetObjKey = tbJsonData.SetObjKey or ""
    self.nBuffTemplateId = tbJsonData.BuffTemplateId or 0

    return true
end

function BattleBuffRemovedTarget:OnBuffRemoved(tbPlayer,nBuffTemplateId)
    if nBuffTemplateId == self.nBuffTemplateId then
        if self.szSetObjKey and string.len(self.szSetObjKey) > 0 then
            BattleBlackboard:SetTable(self.szSetObjKey, tbPlayer)
        end
    
        self:Complete()
    end
end

function BattleBuffRemovedTarget:RegisterEvent()
    EventManager:BindEventMethod(CommonEventDef.EV_ON_BUFF_REMOVE, self, self.OnBuffRemoved)
end

function BattleBuffRemovedTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_ON_BUFF_REMOVE, self, self.OnBuffRemoved)   
end

function BattleBuffRemovedTarget:Start()
    BattleBuffRemovedTarget.super.Start(self)
end

return BattleBuffRemovedTarget
