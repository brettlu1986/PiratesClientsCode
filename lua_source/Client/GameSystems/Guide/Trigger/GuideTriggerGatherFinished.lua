-----------------------------------------------------
--File Name    : GuideTriggerGatherFinished.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerGatherFinished = luaclass("GuideTriggerGatherFinished",GuideTrigger)

local GatherSystem = require("GatherSystem")

GuideTriggerGatherFinished.bIsPlayerSelfReady = false



local function CheckGatherFinished(self)
    local GatherComponent = GatherSystem:GetComponent()
    if(GatherComponent:IsGatherFinished() == self.tbTemplate.bIsEnable)then
        return true
    end
    return false
end

--override
function GuideTriggerGatherFinished:Begin()
    GuideTriggerGatherFinished.super.Begin(self)
    if(CheckGatherFinished(self))then
        self:Trigger()
    end
    
end

function GuideTriggerGatherFinished:IsTrigger()
    self.bIsTrigger = CheckGatherFinished(self)
    return self.bIsTrigger
end

return GuideTriggerGatherFinished
