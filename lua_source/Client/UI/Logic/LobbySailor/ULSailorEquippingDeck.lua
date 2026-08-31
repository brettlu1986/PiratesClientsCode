local luaclass = require("luaclass")
local ULSailorEquippingBase = require("ULSailorEquippingBase")
local ULSailorEquippingDeck = luaclass("ULSailorEquippingDeck", ULSailorEquippingBase)
local SailorCategoryDef = require("SailorCategoryDef")

function ULSailorEquippingDeck:Activate()
    ULSailorEquippingDeck.super.Activate(self)
end

function ULSailorEquippingDeck:Deactivate()
    ULSailorEquippingDeck.super.Deactivate(self)
end

function ULSailorEquippingDeck:OnCreate()
    self.nSailorCategory = SailorCategoryDef.Deck
    self.szSailorItemBdrName = "bdrDeck%d"
    -- self.szSailorItemLineName = "deckLine%d"
end

function ULSailorEquippingDeck:OnLoad()
    ULSailorEquippingDeck.super.OnLoad(self)
end

function ULSailorEquippingDeck:OnEnter()
    ULSailorEquippingDeck.super.OnEnter(self)
end

function ULSailorEquippingDeck:OnBindEvent( EventHelper )
    ULSailorEquippingDeck.super.OnBindEvent(self, EventHelper)
end


return ULSailorEquippingDeck