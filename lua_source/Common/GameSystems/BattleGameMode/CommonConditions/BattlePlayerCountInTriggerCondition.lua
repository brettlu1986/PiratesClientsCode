local luaclass = require("luaclass")
local BattleConditionBase = require("BattleConditionBase")
local BattlePlayerCountInTriggerCondition = luaclass("BattlePlayerCountInTriggerCondition", BattleConditionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local CampDef = require("CampDefine")
local BattleTriggerHelper = require("BattleTriggerHelper")

BattlePlayerCountInTriggerCondition.nCount = nil
BattlePlayerCountInTriggerCondition.szOperator = nil

function BattlePlayerCountInTriggerCondition:Parse(tbJsonData)
    self.nTriggerId = tbJsonData.TriggerId
    self.szOperator = tbJsonData.Operator
    self.nCount = tbJsonData.Count
    self.nCampType = tbJsonData.CampType
    return true
end

BattlePlayerCountInTriggerCondition.StaticCheck = function(nTriggerId, szOperator, nCount, nCampType)
    local tbObjects = BattleTriggerHelper:GetObjects(nTriggerId)
    if(tbObjects == nil) then
        return false
    end
    
    local nCurrentCount = 0
    local nNoneCamp = CampDef.Type.CAMP_NONE
    for i, Object in ipairs(tbObjects) do
        if(not Object:IsDead() and Object.ObjectType == GameObjectTypeDef.PlayerSelf) then            
            if(nCampType ~= nNoneCamp) then
                if(nCampType == Object.BattleCampComponent:GetCampType()) then
                    nCurrentCount = nCurrentCount + 1
                end
            else
                nCurrentCount = nCurrentCount + 1
            end
        end
    end
    return BattleOperationHelper:CallOperator(szOperator, nCurrentCount, nCount)
end

function BattlePlayerCountInTriggerCondition:Execute()
    return self.StaticCheck(self.nTriggerId, self.szOperator, self.nCount, self.nCampType)
end

return BattlePlayerCountInTriggerCondition