-- 占圈状态变为目标状态完成

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleOccupyStateChangeTarget = luaclass("BattleOccupyStateChangeTarget", BattleTargetBaseClass)

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local BattleBlackboard = require("BattleBlackboard")

BattleOccupyStateChangeTarget.nOccupyType = true
BattleOccupyStateChangeTarget.szSaveCampTypeKey = nil

function BattleOccupyStateChangeTarget:Init()
    BattleOccupyStateChangeTarget.super.Init(self)
    self.szName = "BattleOccupyStateChangeTarget"    
end

function BattleOccupyStateChangeTarget:Parse(tbJsonData)
    self.nOccupyType = tbJsonData.OccupyType
    self.szSaveCampTypeKey = tbJsonData.SaveCampTypeKey
    return true
end

function BattleOccupyStateChangeTarget:OnOccupyStateChange(nOccupyType, nCampType)
    if nOccupyType == self.nOccupyType then
        
        if self.szSaveCampTypeKey then
            BattleBlackboard:SetNumber(self.szSaveCampTypeKey, nCampType)            
        end
    
        self:Complete()
    end
end

function BattleOccupyStateChangeTarget:RegisterEvent()
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_OCCUPY_TYPE_CHANGE, self, self.OnOccupyStateChange)
end

function BattleOccupyStateChangeTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_OCCUPY_TYPE_CHANGE, self, self.OnOccupyStateChange)
end

function BattleOccupyStateChangeTarget:Start()
    BattleOccupyStateChangeTarget.super.Start(self)    
end


return BattleOccupyStateChangeTarget
