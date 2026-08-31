-- 玩家存在指定buff进入trigger

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattlePlayerInTriggerWithBuffTarget = luaclass("BattlePlayerInTriggerWithBuffTarget", BattleTargetBaseClass)

local BattleTriggerHelper = require("BattleTriggerHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local CampDef = require("CampDefine")
local BattleBlackboard = require("BattleBlackboard")


BattlePlayerInTriggerWithBuffTarget.nTriggerId = nil
BattlePlayerInTriggerWithBuffTarget.nCampType = nil
BattlePlayerInTriggerWithBuffTarget.nBuffId = nil
BattlePlayerInTriggerWithBuffTarget.fnCallback = nil
BattlePlayerInTriggerWithBuffTarget.szSetObjKey = nil

function BattlePlayerInTriggerWithBuffTarget:Init()
    BattlePlayerInTriggerWithBuffTarget.super.Init(self)
    self.szName = "BattlePlayerInTriggerWithBuffTarget"    
end

function BattlePlayerInTriggerWithBuffTarget:Parse(tbJsonData)    
    self.nTriggerId = tbJsonData.TriggerId
    self.nBuffId = tbJsonData.BuffId
    self.nCampType = tbJsonData.CampType
    self.szSetObjKey = tbJsonData.SetObjKey
    return self.nTriggerId ~= nil
end

local function OnEnterTrigger(self, GameObject)
    if GameObject.BuffComponentServer:IsExistBuffById(self.nBuffId) then 
        if(not GameObject:IsDead() and GameObject.ObjectType == GameObjectTypeDef.PlayerSelf) then            
            if self.nCampType ~= CampDef.Type.CAMP_NONE then
                if self.nCampType == GameObject.BattleCampComponent:GetCampType() then
                    BattleBlackboard:SetTable(self.szSetObjKey, GameObject)
                    self:Complete()
                end
            else
                self:Complete()
            end
        end
    end
end

function BattlePlayerInTriggerWithBuffTarget:RegisterEvent()
    self.fnCallback = function(nTriggerId, GameObject, bEnter)
        if(bEnter) then
            OnEnterTrigger(self, GameObject)
        end
    end
    BattleTriggerHelper:AddCallback(self.nTriggerId, self.fnCallback)
end

function BattlePlayerInTriggerWithBuffTarget:UnregisterEvent()
    if(self.fnCallback) then
        BattleTriggerHelper:RemoveCallback(self.nTriggerId, self.fnCallback)
        self.fnCallback = nil
    end
end

function BattlePlayerInTriggerWithBuffTarget:Start()
    BattlePlayerInTriggerWithBuffTarget.super.Start(self)

end


return BattlePlayerInTriggerWithBuffTarget
