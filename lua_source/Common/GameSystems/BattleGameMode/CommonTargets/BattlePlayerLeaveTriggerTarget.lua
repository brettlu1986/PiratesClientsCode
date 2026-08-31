-- 玩家离开指定的Trigger

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattlePlayerLeaveTriggerTarget = luaclass("BattlePlayerLeaveTriggerTarget", BattleTargetBaseClass)

local BattleTriggerHelper = require("BattleTriggerHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local CampDef = require("CampDefine")
local BattleBlackboard = require("BattleBlackboard")


BattlePlayerLeaveTriggerTarget.nTriggerId = nil
BattlePlayerLeaveTriggerTarget.nCampType = nil
BattlePlayerLeaveTriggerTarget.fnCallback = nil
BattlePlayerLeaveTriggerTarget.szSetObjKey = nil

function BattlePlayerLeaveTriggerTarget:Init()
    BattlePlayerLeaveTriggerTarget.super.Init(self)
    self.szName = "BattlePlayerLeaveTriggerTarget"    
end

function BattlePlayerLeaveTriggerTarget:Parse(tbJsonData)    
    self.nTriggerId = tbJsonData.TriggerId
    self.nCampType = tbJsonData.CampType
    self.szSetObjKey = tbJsonData.SetObjKey
    return self.nTriggerId ~= nil
end

local function OnLeaveTrigger(self, GameObject)
    if GameObject.ObjectType == GameObjectTypeDef.PlayerSelf  then            
        if self.nCampType ~= CampDef.Type.CAMP_NONE then
            if GameObject.BattleCampComponent then
                if self.nCampType == GameObject.BattleCampComponent:GetCampType() then
                    if self.szSetObjKey and string.len(self.szSetObjKey) > 0 then
                        BattleBlackboard:SetTable(self.szSetObjKey, GameObject)
                    end
                    self:Complete()
                end
            end
        else
            if self.szSetObjKey and string.len(self.szSetObjKey) > 0 then
                BattleBlackboard:SetTable(self.szSetObjKey, GameObject)
            end
            self:Complete()
        end
    end
end

function BattlePlayerLeaveTriggerTarget:RegisterEvent()
    self.fnCallback = function(nTriggerId, GameObject, bEnter)
        if not bEnter then
            OnLeaveTrigger(self, GameObject)
        end
    end
    BattleTriggerHelper:AddCallback(self.nTriggerId, self.fnCallback)
end

function BattlePlayerLeaveTriggerTarget:UnregisterEvent()
    if(self.fnCallback) then
        BattleTriggerHelper:RemoveCallback(self.nTriggerId, self.fnCallback)
        self.fnCallback = nil
    end
end

function BattlePlayerLeaveTriggerTarget:Start()
    BattlePlayerLeaveTriggerTarget.super.Start(self)

end


return BattlePlayerLeaveTriggerTarget
