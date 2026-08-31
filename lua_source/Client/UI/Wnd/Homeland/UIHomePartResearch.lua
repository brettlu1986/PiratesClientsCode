-----------------------------------------------------
--File Name    : UIHomePartResearch.lua
--Author       : zhiyuan
--Create Time  : 2019-05-15
--Description  : 家园的零件研发界面
-----------------------------------------------------
local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIHomePartResearch = luaclass("UIHomePartResearch", WndBase)

local LandmarkTypeDef = require("LandmarkTypeDef")

UIHomePartResearch.pbWindowFrame = nil
UIHomePartResearch.pbHomeResearchSub = nil

UIHomePartResearch.ulHomePartResearchChoose = nil

function UIHomePartResearch:OnLoad()
    local UILogicHelper = self.UILogicHelper
    self.ulHomePartResearchChoose = UILogicHelper:CreateUILogic("ULHomeShipPartResearchChoose")

    local PrefabHelper = self.PrefabHelper
    local pWidgetRef = self.pWidgetRef
    self.pbWindowFrame = PrefabHelper:BindPrefab(pWidgetRef.pbWindowFrame)
    self.pbHomeResearchSub = PrefabHelper:BindPrefab(pWidgetRef.pbHomeResearchSub)
end

function UIHomePartResearch:OnShow()
    self.pbHomeResearchSub:SetData(LandmarkTypeDef.SHIPYARD)
end

function UIHomePartResearch:OnBindEvent(EventHelper)
end

return UIHomePartResearch