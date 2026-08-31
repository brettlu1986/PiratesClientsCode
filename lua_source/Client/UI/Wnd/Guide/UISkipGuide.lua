-----------------------------------------------------
--File Name    : UISkipGuide.lua
--Author       : Ran Jie
--Create Time  : 2018-03-20
--Description  : 跳过新手副本
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UISkipGuide = luaclass("UISkipGuide", WndBase)


local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")


local function OnSkipClick(self)
	log("UISkipGuide:OnSkipClick")
	self:CloseSelf()
	EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_SKIP_DUNGEON)
end

function UISkipGuide:OnLoad()
    self.PrefabHelper:BindPrefab(self.pWidgetRef.pbCutoutScreenAdapter)
end

function UISkipGuide:OnBindEvent(Helper)
	local pWidgetRef = self.pWidgetRef
	Helper:RegisterCppDelegate(pWidgetRef.btnSkip.OnClicked, self, OnSkipClick)
end

return UISkipGuide
