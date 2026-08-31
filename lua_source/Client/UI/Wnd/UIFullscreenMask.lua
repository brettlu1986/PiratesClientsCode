-----------------------------------------------------
--File Name    : UIFullscreenMask.lua
--Author       : Song Fuhao
--Create Time  : 2019-04-12
--Description  : 全屏透明遮罩，可用于部分时候屏蔽所有点击使用
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIFullscreenMask = luaclass("UIFullscreenMask", WndBase)

local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")

local function OnClickedBtnMask(self)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_CLICK_FULLSCREEN_MASK)
end

function UIFullscreenMask:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnMask.OnClicked, self, OnClickedBtnMask)
end

return UIFullscreenMask