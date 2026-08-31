-----------------------------------------------------
--File Name    : BlackScreenHelper.lua
--Author       : Ran Jie
--Create Time  : 2020-05-26
--Description  : 黑屏帮助类
-----------------------------------------------------
local BlackScreenHelper = {}

local UIManager = require("UIManager")
local UIDef = require("UIDef")


BlackScreenHelper.nBlackScreenInSpeed = 0
BlackScreenHelper.nBlackScreenOutSpeed = 0
---------------------------外部接口---------------------------
function BlackScreenHelper:ShowBlackScreen(bAutoClose, FullDisplayCallback, CloseCallback)
    local tbParams = {}
    tbParams.bAutoClose = bAutoClose
    tbParams.FullDisplayCallback = FullDisplayCallback
    tbParams.CloseCallback = CloseCallback
    if self.nBlackScreenInSpeed == 0 and self.nBlackScreenOutSpeed == 0 then
        if FullDisplayCallback then
            FullDisplayCallback()
        end
        if CloseCallback then
            CloseCallback()
        end
    else
        UIManager:OpenWnd(UIDef.UI_BLACKSCREEN, tbParams)
    end
end

function BlackScreenHelper:CloseBlackScreen()
    UIManager:CloseWnd(UIDef.UI_BLACKSCREEN)
end

return BlackScreenHelper