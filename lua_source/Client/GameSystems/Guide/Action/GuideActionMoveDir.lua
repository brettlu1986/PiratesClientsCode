-----------------------------------------------------
--File Name    : GuideActionMoveDir.lua
--Author       : Edward J
--Create Time  : 2019-09-18
--Description  : 指引向前走
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFunctional     = require("GuideActionFunctional")
local GuideActionMoveDir        = luaclass("GuideActionMoveDir", GuideActionFunctional)

local UIManager                 = require("UIManager")
local UIDef                     = require("UIDef")
local UPHumanVirtualJoystick    = require("UPHumanVirtualJoystick")
-----------------------------------------------------
GuideActionMoveDir.pJoystick = nil
-----------------------------------------------------

local function SetVirtualJoystickEnable(self)
    local tbTemplate = self.tbTemplate
    local bP1 = tonumber(tbTemplate.tbParam[1]) >= 1
    local bP2 = tonumber(tbTemplate.tbParam[2]) >= 1
    local bP3 = tonumber(tbTemplate.tbParam[3]) >= 1
    local bP4 = tonumber(tbTemplate.tbParam[4]) >= 1
    UPHumanVirtualJoystick.LockDirections(bP1, bP2, bP3, bP4)
end

function GuideActionMoveDir:Begin()
    self:DebugLog(" GuideActionMoveDir:Begin()")
    GuideActionMoveDir.super.Begin(self)
    local pMainWnd = UIManager:GetWnd(UIDef.UI_FFA_MAIN)
    if not pMainWnd then
        self:EndAction()
        return
    end
    local pJoystick = pMainWnd.pWidgetRef.pbVirtualJoystick
    if not pJoystick then
        self:EndAction()
        return
    end
    SetVirtualJoystickEnable(self)
end

return GuideActionMoveDir