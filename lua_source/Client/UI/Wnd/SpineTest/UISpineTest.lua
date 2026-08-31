local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UISpineTest = luaclass("UISpineTest", WndBase)

local function OnMouseButtonUpEvent(self, pGeometry, pMouseEvent)
    self:CloseSelf()
    return WidgetBlueprintLibrary.Unhandled()
end

function UISpineTest:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.bdrBg.OnMouseButtonUpEvent, self, OnMouseButtonUpEvent)
end

function UISpineTest:OnShow()
    self.pWidgetRef.spTest1:SetAnimation(0, "animation", true)
    self.pWidgetRef.spTest2:SetAnimation(0, "walk", true)
end



return UISpineTest