-----------------------------------------------------
--File Name    : GuideTriggerCheckPlayerType.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerCheckPlayerType   = luaclass("GuideTriggerCheckPlayerType", GuideTrigger)

local GamePlayerSelfHelper          = require("GamePlayerSelfHelper")
-----------------------------------------------------

function GuideTriggerCheckPlayerType:CheckPlayerType()
    self:DebugLog("CheckPlayerType ")
    local tbParam = self.tbTemplate.tbParam
    if not tbParam then
        return
    end
    local tbPlayer = GamePlayerSelfHelper:Get()
    if tbParam[1] == "ship" and tbPlayer:IsShip() then
        self:DebugLog("CheckPlayerType ship Trigger")
        self:Trigger()
    elseif tbParam[1] == "human" and tbPlayer:IsHuman() then
        self:DebugLog("CheckPlayerType human Trigger")
        self:Trigger()
    else
        self:Break()
    end
end

--override
function GuideTriggerCheckPlayerType:Begin()
    GuideTriggerCheckPlayerType.super.Begin(self)
    self:CheckPlayerType()
end

return GuideTriggerCheckPlayerType