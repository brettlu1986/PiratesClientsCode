-----------------------------------------------------
--File Name    : GuideAction.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFunctional     = require("GuideActionFunctional")
local GuideActionRotateToNpc    = luaclass("GuideActionRotateToNpc", GuideActionFunctional)

local GameObjectSystem      = dynamic_require("GameObjectSystem")
local GameObjectTypeDef     = require("GameObjectTypeDef")
local CameraGameHelper     = require("CameraGameHelper")
-----------------------------------------------------
--member veriable
GuideActionRotateToNpc.nObjectType = GameObjectTypeDef.Undefined
GuideActionRotateToNpc.nTemplateId = 0
GuideActionRotateToNpc.nDuration   = 1
-----------------------------------------------------

local function RotateToNpc(self)
    local tbGameObjectList = GameObjectSystem:GetAllGameObjects()
    for _, GameObject in pairs(tbGameObjectList) do
        self:DebugLog("###GameObject Type = " .. tostring(GameObject:GetObjectType()))
        if GameObject:GetObjectType() == self.nObjectType and GameObject.nTemplateId == self.nTemplateId and GameObject.pUEActor and not GameObject.pUEActor.bHidden then 
            self:DebugLog("###GameObject nTemplateId = " .. GameObject.nTemplateId)
            local pActorL = GameObject.pUEActor:K2_GetActorLocation()
            CameraGameHelper.RotateToTarget(pActorL, self.nDuration)
        end 
    end
end

function GuideActionRotateToNpc:DoAction(tbTemplate)
    GuideActionRotateToNpc.super.DoAction(self, tbTemplate)
    local tbParam = tbTemplate.tbParam
    if not tbParam then
        return
    end
    self.nObjectType = tonumber(tbParam[1])
    self.nTemplateId = tonumber(tbParam[2])
    self.nDuration = tonumber(tbParam[3])
    self:DebugLog("Params ObjectType = " .. self.nObjectType .. " TemplateId = " .. self.nTemplateId .. " Duration = " .. self.nDuration)
    RotateToNpc(self)
end

function GuideActionRotateToNpc:End()
    GuideActionRotateToNpc.super.End(self)
end

return GuideActionRotateToNpc
