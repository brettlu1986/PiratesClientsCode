-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideTriggerPoisonCircleCount     = require("GuideTriggerPoisonCircleCount")
local GuideTriggerThrowWeapon           = luaclass("GuideTriggerThrowWeapon", GuideTriggerPoisonCircleCount)

local UIManager             = require("UIManager")
local UIDef                 = require("UIDef")
local ControlModeDef        = require("ControlModeDef")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
-----------------------------------------------------

function GuideTriggerThrowWeapon:Execute()
    self:DebugLog("Execute")
    local Wnd = UIManager:GetWnd(UIDef.UI_FFA_MAIN)
    if not Wnd then
        self:LogError("FFAMain is nil")
        return
    end
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if not PlayerSelf:IsHuman() then
        self:LogError("player is ship")
        return
    end
    local pHumanControl = Wnd.tbControlModePrefab[ControlModeDef.HUMAN]
    if not pHumanControl then
        self:LogError("humanControl is nil")
        return
    end
    local ulFFAHumanThrownItem = pHumanControl.ulFFAHumanThrownItem
    local pbThrowItemShortcut = ulFFAHumanThrownItem.pbThrowItemShortcut
    local tbItems = pbThrowItemShortcut:GetAllShortcutItems()
    self:DebugLog("ntbItems = " .. tostring(#tbItems))
    if #tbItems ~= 0 then
        self:Trigger()
    end
end

--override
function GuideTriggerThrowWeapon:Begin()
    GuideTriggerThrowWeapon.super.Begin(self)
end

return GuideTriggerThrowWeapon
