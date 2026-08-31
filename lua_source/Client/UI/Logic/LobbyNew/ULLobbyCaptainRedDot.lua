local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")

local ULLobbyCaptainRedDot = luaclass("ULLobbyCaptainRedDot", UILogicBase)

local UILobbyCaptainHelper  = require("UILobbyCaptainHelper")
local LobbyCaptainMiscDef   = require("LobbyCaptainMiscDef")
local ClientEventDef        = require("ClientEventDef")

local FeatureType = LobbyCaptainMiscDef.FeatureType

local function RefreshVisualRedDot(self)
    local bRed = UILobbyCaptainHelper.HasNewHumanVisualItem()
    self.Owner.tbTabBarHelper:SetTipIconVisible(FeatureType.Visual, bRed)
end

local function RefreshRedDot(self)
    RefreshVisualRedDot(self)
end

-- lifecycle callback

-- function ULLobbyCaptainRedDot:OnCreate()
-- end

-- function ULLobbyCaptainRedDot:OnDestroy()
-- end

-- function ULLobbyCaptainRedDot:OnLoad()
-- end

-- function ULLobbyCaptainRedDot:OnUnload()
-- end

-- function ULLobbyCaptainRedDot:OnEnter()
-- end

function ULLobbyCaptainRedDot:OnShow()
    RefreshRedDot(self)
end

-- function ULLobbyCaptainRedDot:OnHide()
-- end

-- function ULLobbyCaptainRedDot:OnExit()
-- end

function ULLobbyCaptainRedDot:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_NEW_ITEM_RECORD_STATE_CHANGED, self, RefreshRedDot)
end

-- function ULLobbyCaptainRedDot:OnUnbindEvent(EventHelper)
-- end


return ULLobbyCaptainRedDot