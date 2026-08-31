-- 玩家进入指定的trigger

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattlePlayerEnterTriggerTarget = luaclass("BattlePlayerEnterTriggerTarget", BattleTargetBaseClass)

local BattleTriggerHelper = require("BattleTriggerHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local CampDef = require("CampDefine")
local BattleBlackboard = require("BattleBlackboard")


BattlePlayerEnterTriggerTarget.nTriggerId = nil
BattlePlayerEnterTriggerTarget.nCampType = nil
BattlePlayerEnterTriggerTarget.fnCallback = nil
BattlePlayerEnterTriggerTarget.szSetObjKey = nil

function BattlePlayerEnterTriggerTarget:Init()
    BattlePlayerEnterTriggerTarget.super.Init(self)
    self.szName = "BattlePlayerEnterTriggerTarget"    
end

function BattlePlayerEnterTriggerTarget:Parse(tbJsonData)    
    self.nTriggerId = tbJsonData.TriggerId
    self.nCampType = tbJsonData.CampType
    self.szSetObjKey = tbJsonData.SetObjKey
    return self.nTriggerId ~= nil
end

local function OnEnterTrigger(self, GameObject)
    if GameObject.ObjectType == GameObjectTypeDef.PlayerSelf and not GameObject:IsDead() then            
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

function BattlePlayerEnterTriggerTarget:RegisterEvent()
    self.fnCallback = function(nTriggerId, GameObject, bEnter)
        if(bEnter) then
            OnEnterTrigger(self, GameObject)
        end
    end
    BattleTriggerHelper:AddCallback(self.nTriggerId, self.fnCallback)
end

function BattlePlayerEnterTriggerTarget:UnregisterEvent()
    if(self.fnCallback) then
        BattleTriggerHelper:RemoveCallback(self.nTriggerId, self.fnCallback)
        self.fnCallback = nil
    end
end

function BattlePlayerEnterTriggerTarget:Start()
    BattlePlayerEnterTriggerTarget.super.Start(self)

end


return BattlePlayerEnterTriggerTarget
