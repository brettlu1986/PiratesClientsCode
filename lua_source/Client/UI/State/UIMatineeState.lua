-----------------------------------------------------
--File Name    : UIMatineeState.lua
--Author       : Ran Jie
--Create Time  : 2017-03-07
--Description  : UIMatineeState
-----------------------------------------------------

local luaclass = require("luaclass")
local UICinematicState = require("UICinematicState")
local UIMatineeState = luaclass("UIMatineeState", UICinematicState)

local UIDef = require("UIDef")
local UIManager = require("UIManager")

function UIMatineeState:Init(szUIStateName)
    UIMatineeState.super.Init(self, szUIStateName) 
    self:AddActiveWnd(UIDef.UI_CROSSHAIRS_DEBUG)
    self:AddActiveWnd(UIDef.UI_FFA_MAIN)
    self:AddActiveWnd(UIDef.UI_HOME_MAIN)
end

function UIMatineeState:VerifyWndVisibility(Wnd)
    -- logdebug("[UI]Wnd.szWndName="..Wnd.tbTemplate.szWndName)
    -- logdebug("[UI]Wnd.tbTemplate.bIgnoreCinematicMode="..tostring(Wnd.tbTemplate.bIgnoreCinematicMode).." cinematicwnd="..tostring(self.tbCinematicWnd[Wnd.tbTemplate.szWndName]))
    local tbWndTemplate = Wnd.tbTemplate
    if(not tbWndTemplate.bIgnoreCinematicMode or tbWndTemplate.szWndName == UIDef.UI_WINDOWS_BG)then
        return false
    else
        if tbWndTemplate.bNeedBlurBG then
            local WndBg = UIManager:GetWnd(UIDef.UI_WINDOWS_BG)
            if WndBg then
                WndBg.pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            end
        end
        return true
    end
end

return UIMatineeState
