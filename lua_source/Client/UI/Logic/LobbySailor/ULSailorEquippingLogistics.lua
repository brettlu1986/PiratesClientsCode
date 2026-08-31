local luaclass = require("luaclass")
local ULSailorEquippingBase = require("ULSailorEquippingBase")
local ULSailorEquippingLogistics = luaclass("ULSailorEquippingLogistics", ULSailorEquippingBase)
local SailorCategoryDef = require("SailorCategoryDef")

function ULSailorEquippingLogistics:Activate()
    ULSailorEquippingLogistics.super.Activate(self)
end

function ULSailorEquippingLogistics:Deactivate()
    ULSailorEquippingLogistics.super.Deactivate(self)
end

function ULSailorEquippingLogistics:OnCreate()
    self.nSailorCategory = SailorCategoryDef.Logistics
    self.szSailorItemBdrName = "bdrLogistics%d"
    -- self.szSailorItemLineName = "logisticsLine%d"
end

function ULSailorEquippingLogistics:OnLoad()
    ULSailorEquippingLogistics.super.OnLoad(self)
end

function ULSailorEquippingLogistics:OnEnter()
    ULSailorEquippingLogistics.super.OnEnter(self)
end

function ULSailorEquippingLogistics:OnBindEvent( EventHelper )
    ULSailorEquippingLogistics.super.OnBindEvent(self, EventHelper)
end


return ULSailorEquippingLogistics