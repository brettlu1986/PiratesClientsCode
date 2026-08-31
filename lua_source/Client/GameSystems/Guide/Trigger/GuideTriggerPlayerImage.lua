-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                    = require("luaclass")
local GuideTrigger                = require("GuideTrigger")
local GuideTriggerPlayerImage     = luaclass("GuideTriggerPlayerImage", GuideTrigger)

local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
-----------------------------------------------------

function GuideTriggerPlayerImage:CheckPlayerImage()
    self:DebugLog("CheckPlayerImage")
    local tbParam = self.tbTemplate.tbParam
    if not tbParam then
        return
    end
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local szImage = tbParam[1]
    self:DebugLog("CheckPlayerImage, szImage = " .. szImage)
    if szImage == "ship" then
        return PlayerSelf:IsShip()
    end
    if szImage == "human" then
        return PlayerSelf:IsHuman()
    end
end

--override
function GuideTriggerPlayerImage:Begin()
    GuideTriggerPlayerImage.super.Begin(self)
    local bResult = self:CheckPlayerImage()
    self:DebugLog("CheckPlayerImage, result = " .. tostring(bResult))
    if bResult then
        self:Trigger()
    else
        self:Break()
    end
end

return GuideTriggerPlayerImage
