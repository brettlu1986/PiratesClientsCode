-----------------------------------------------------
--File Name    : GuideTriggerOpenUI.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerUIIsOpened        = luaclass("GuideTriggerUIIsOpened",GuideTrigger)

local GuideSystem           = require("GuideSystem")
-----------------------------------------------------
-----------------------------------------------------

local function IsUIOpened(self, szUIName)
    local bOpened = GuideSystem:LobbyUIIsOpened(szUIName)
    self:DebugLog("GuideTriggerUIIsOpened, bOpened = " .. tostring(bOpened))
    return bOpened
end

--override
function GuideTriggerUIIsOpened:Begin()
    GuideTriggerUIIsOpened.super.Begin(self)
    local szUIName = self.tbTemplate.szOpenUIName
    self:DebugLog("target ui name = " .. szUIName)
    if not szUIName then
        return
    end
    local bOpened = IsUIOpened(self, szUIName)
    local bEnable = self.tbTemplate.bIsEnable
    if not bEnable then
        bOpened = not bOpened
    end
    local bResult = bOpened
    self:DebugLog("bResult = " .. tostring(bResult))
    if bResult then
        self:Trigger()
    else
        self:Break()
    end
end

return GuideTriggerUIIsOpened
