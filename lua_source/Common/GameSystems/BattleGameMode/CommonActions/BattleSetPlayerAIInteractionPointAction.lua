local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSetPlayerAIInteractionPointAction = luaclass("BattleSetPlayerAIInteractionPointAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleTransformPointHelper = require("BattleTransformPointHelper")

BattleSetPlayerAIInteractionPointAction.szTag = nil
BattleSetPlayerAIInteractionPointAction.nTemplateId = nil
BattleSetPlayerAIInteractionPointAction.nTransformId = nil
BattleSetPlayerAIInteractionPointAction.bEnable = nil
BattleSetPlayerAIInteractionPointAction.nRadius = nil

function BattleSetPlayerAIInteractionPointAction:Parse(tbJsonData)
    self.szTag = tbJsonData.Tag
    self.nTemplateId = tbJsonData.TemplateId
    self.nTransformId = tbJsonData.TransformId
    self.bEnable = tbJsonData.Enable
    self.nRadius = tbJsonData.Radius
    return true
end

local function GetNpcLocationByTag(self, szTag)
    local tbGameObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.Npc)
    for Object, _ in pairs(tbGameObjects) do
        if Object.szTag == szTag then
            return Object:GetLocation()
        end
    end
    return nil
end

local function GetNpcLocationByTemplateId(self, nTemplateId)
    local tbGameObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.Npc)
    for Object, _ in pairs(tbGameObjects) do
        if Object.nTemplateId == nTemplateId then
            return Object:GetLocation()
        end
    end
    return nil
end

function BattleSetPlayerAIInteractionPointAction:GetLocation()
    local tbLocation = nil
    -- 指向NPC
    if self.szTag and string.len(self.szTag) > 0 then
        tbLocation = GetNpcLocationByTag(self, self.szTag)
    elseif self.nTemplateId and self.nTemplateId > 0 then 
        tbLocation = GetNpcLocationByTemplateId(self, self.nTemplateId)
    elseif self.nTransformId and self.nTransformId > 0 then 
        -- 指向点
        local tbTransform = BattleTransformPointHelper:Find(self.nTransformId)
        tbLocation = Vector{X = tbTransform.X, Y = tbTransform.Y, Z = tbTransform.Z}
    end
    return tbLocation
end

function BattleSetPlayerAIInteractionPointAction:Execute()
    BattleOperationHelper:PrintLog(self, 
    "Tag: "..self.szTag..
    ", TransformId: "..self.nTransformId..
    ", Radius: "..(self.nRadius and self.nRadius or 0)..
    ", Enable: "..(self.bEnable and "true" or "false"))

    local tbLocation = self:GetLocation()
    if tbLocation then 
        local tbGameObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
        for Object, _ in pairs(tbGameObjects) do
            if Object.BattleAIComponent then
                if self.bEnable then
                    Object.BattleAIComponent:SetInteractionPosition(tbLocation, self.nRadius)
                else
                    Object.BattleAIComponent:SetInteractionPosition(nil, self.nRadius)
                end
            end
        end
    end

    return true
end

return BattleSetPlayerAIInteractionPointAction