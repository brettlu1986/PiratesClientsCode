
local luaclass = require("luaclass")
local ULSailorEquippingBase = require("ULSailorEquippingBase")
local ULSailorEquippingCanon = luaclass("ULSailorEquippingCanon", ULSailorEquippingBase)
local SailorCategoryDef = require("SailorCategoryDef")

function ULSailorEquippingCanon:Activate()
    ULSailorEquippingCanon.super.Activate(self)
end

function ULSailorEquippingCanon:Deactivate()
    ULSailorEquippingCanon.super.Deactivate(self)
end

function ULSailorEquippingCanon:OnCreate()
    self.nSailorCategory = SailorCategoryDef.Cannon
    self.szSailorItemBdrName = "bdrCanon%d"
    -- self.szSailorItemLineName = "canonLine%d"
end

function ULSailorEquippingCanon:OnLoad()
    ULSailorEquippingCanon.super.OnLoad(self)
end

function ULSailorEquippingCanon:OnEnter()
    ULSailorEquippingCanon.super.OnEnter(self)
end

function ULSailorEquippingCanon:OnBindEvent( EventHelper )
    ULSailorEquippingCanon.super.OnBindEvent(self, EventHelper)
end

return ULSailorEquippingCanon