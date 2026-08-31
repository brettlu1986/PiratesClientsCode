-----------------------------------------------------
--File Name    : UIHomeWeaponResearch.lua
--Author       : zhiyuan
--Create Time  : 2019-05-21
--Description  : 家园武器研发
-----------------------------------------------------
local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIHomeWeaponResearch = luaclass("UIHomeWeaponResearch", WndBase)

local LandmarkTypeDef = require("LandmarkTypeDef")

UIHomeWeaponResearch.pbWindowFrame = nil
UIHomeWeaponResearch.pbHomeResearchSub = nil

UIHomeWeaponResearch.ulHomeWeaponResearchChoose = nil

function UIHomeWeaponResearch:OnLoad()
   local UILogicHelper = self.UILogicHelper
   self.ulHomeWeaponResearchChoose = UILogicHelper:CreateUILogic("ULHomeShipWeaponResearchChoose")

    local PrefabHelper = self.PrefabHelper
    local pWidgetRef = self.pWidgetRef
    self.pbWindowFrame = PrefabHelper:BindPrefab(pWidgetRef.pbWindowFrame)
    self.pbHomeResearchSub = PrefabHelper:BindPrefab(pWidgetRef.pbHomeResearchSub)
end

function UIHomeWeaponResearch:OnShow()
    self.pbHomeResearchSub:SetData(LandmarkTypeDef.ARSENAL)
end

function UIHomeWeaponResearch:OnBindEvent(EventHelper)
end

return UIHomeWeaponResearch