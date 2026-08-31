-----------------------------------------------------
--File Name    : GuideTriggerOpenUI.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerGroupIsFinish      = luaclass("GuideTriggerGroupIsFinish",GuideTrigger)

local GuideSystem           = require("GuideSystem")
-----------------------------------------------------
GuideTriggerGroupIsFinish.nModuleId  = nil
GuideTriggerGroupIsFinish.nGroupId   = nil
-----------------------------------------------------

local function IsGroupFinish(self)
    local bFinish = GuideSystem:IsGroupFinish(self.nModuleId, self.nGroupId)
    self:DebugLog("IsGroupFinish, bFinish = " .. tostring(bFinish))
    return bFinish
end

--override
function GuideTriggerGroupIsFinish:Begin()
    GuideTriggerGroupIsFinish.super.Begin(self)
    local tbParam = self.tbTemplate.tbParam
    if not tbParam then
        return
    end
    self.nModuleId = tonumber(tbParam[1])
    self.nGroupId = tonumber(tbParam[2])
    local bFinish = IsGroupFinish(self)
    local bEnable = self.tbTemplate.bIsEnable
    if not bEnable then
        bFinish = not bFinish
    end
    local bResult = bEnable
    self:DebugLog("IsGroupFinish, bResult = " .. tostring(bResult))
    if bResult then
        self:Trigger()
    else
        self:Break()
    end
end

return GuideTriggerGroupIsFinish
