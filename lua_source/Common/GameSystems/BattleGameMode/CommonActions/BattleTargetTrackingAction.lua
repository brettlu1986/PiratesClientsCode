local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleTargetTrackingAction = luaclass("BattleTargetTrackingAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleTransformPointHelper = require("BattleTransformPointHelper")
local BattleTargetTrackHelper = require("BattleTargetTrackHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleBlackboard = require("BattleBlackboard")

BattleTargetTrackingAction.szTag = nil
BattleTargetTrackingAction.nTransformId = nil
BattleTargetTrackingAction.bVisible = nil
BattleTargetTrackingAction.szSetObjKey = nil

function BattleTargetTrackingAction:Parse(tbJsonData)
    self.bVisible = tbJsonData.Visible
    self.szTag = tbJsonData.Tag
    self.nTransformId = tbJsonData.TransformId    
    self.szSetObjKey = tbJsonData.SetObjKey    
    return self.bVisible == false or ( self.szTag ~= nil and string.len( self.szTag ) > 0 ) or self.nTransformId > 0
end

function BattleTargetTrackingAction:Execute()
    BattleOperationHelper:PrintLog(self, 
        "szTag: "..self.szTag..
        ", TransformId: "..self.nTransformId..
        ", Visible: "..(self.bVisible and "true" or "false"))
    
    local nEffectInstanceId = nil
    if self.szSetObjKey and string.len(self.szSetObjKey) > 0 then 
        local tbObject = BattleBlackboard:GetTable(self.szSetObjKey)
        if tbObject then
            nEffectInstanceId = tbObject.nServerInstanceId
        end
    end

    local tbTransform
    if(self.bVisible) then
        if( self.szTag == nil or string.len(self.szTag) == 0 ) then
            tbTransform = BattleTransformPointHelper:Find(self.nTransformId)
            if(tbTransform == nil) then
                BattleOperationHelper:PrintError(self, "Cannot find transform id: "..self.nTransformId)
                return false
            end
            BattleTargetTrackHelper:ShowTargetTrackPos(nEffectInstanceId, tbTransform.X, tbTransform.Y, tbTransform.Z)
        elseif ( self.szTag ~= nil and string.len(self.szTag) > 0 ) then
            local tbGameObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.Npc)
            for v, _ in pairs(tbGameObjects) do
                if ( v.szTag == self.szTag ) then
                    BattleTargetTrackHelper:ShowWithTargetTrackActor(nEffectInstanceId, v.nServerInstanceId )
                    return true
                end
            end

            BattleOperationHelper:PrintError(self, "Cannot find NPC szTag: "..self.szTag)    
            return false
        end
    else
        BattleTargetTrackHelper:SetTargetTrackVisible(nEffectInstanceId, false)
    end

    return true
end

return BattleTargetTrackingAction