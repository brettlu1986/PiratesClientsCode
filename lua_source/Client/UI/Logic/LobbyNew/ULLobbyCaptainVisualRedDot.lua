local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")

local ULLobbyCaptainVisualRedDot = luaclass("ULLobbyCaptainVisualRedDot", UILogicBase)

local UILobbyCaptainHelper  = require("UILobbyCaptainHelper")
local ClientEventDef        = require("ClientEventDef")


local function RefreshRedDot(self)
    local bNewHumanFashion = UILobbyCaptainHelper.HasNewHumanFashion()
    self.Owner.tbTabBarHelper:SetTipIconVisible(2, bNewHumanFashion)
    local bNewWeaponFashion = UILobbyCaptainHelper.HasNewHumanWeaponFashion()
    self.Owner.tbTabBarHelper:SetTipIconVisible(1, bNewWeaponFashion)
end



-- lifecycle callback

-- function ULLobbyCaptainVisualRedDot:OnCreate()
-- end

-- function ULLobbyCaptainVisualRedDot:OnDestroy()
-- end

-- function ULLobbyCaptainVisualRedDot:OnLoad()
-- end

-- function ULLobbyCaptainVisualRedDot:OnUnload()
-- end

-- function ULLobbyCaptainVisualRedDot:OnEnter()
-- end

function ULLobbyCaptainVisualRedDot:OnShow()
    RefreshRedDot(self)
end

-- function ULLobbyCaptainVisualRedDot:OnHide()
-- end

-- function ULLobbyCaptainVisualRedDot:OnExit()
-- end

function ULLobbyCaptainVisualRedDot:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_NEW_ITEM_RECORD_STATE_CHANGED, self, RefreshRedDot)
end

-- function ULLobbyCaptainVisualRedDot:OnUnbindEvent(EventHelper)
-- end


return ULLobbyCaptainVisualRedDot