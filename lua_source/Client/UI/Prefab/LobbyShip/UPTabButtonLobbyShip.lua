-----------------------------------------------------
--File Name    : UPTabButtonLobbyShip.lua
--Author       : chenyixin
--Description  : 船战图鉴界面名称up
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPTabButtonLobbyShip = luaclass("UPTabButtonLobbyShip", PrefabBase)

-- local UISetUtils = require("UISetUtils")
-- local L10N = require("L10N")
-- local UITextDef = require("UITextDef")
-- local UIResourceDef= require("UIResourceDef")


UPTabButtonLobbyShip.fnOnTabClicked = nil
UPTabButtonLobbyShip.nSlot = nil

local function OnTabClicked(self)
    if self.pWidgetRef.IsSelected then
        return
    end
    if self.fnOnTabClicked then
        self.fnOnTabClicked(self.nSlot, self)
    end
end

function UPTabButtonLobbyShip:OnLoad()
    self.OwnerSub = self.Owner.OwnerSub
end

function UPTabButtonLobbyShip:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnTab.OnClicked, self, OnTabClicked)
end

function UPTabButtonLobbyShip:Init(nSlot)
    self.nSlot = nSlot
end

function UPTabButtonLobbyShip:BindCallback(fnOnTabClicked)
    self.fnOnTabClicked = fnOnTabClicked
end

function UPTabButtonLobbyShip:SetSelected(bSelected)
    self.pWidgetRef:SetIsSelected(bSelected)
end

function UPTabButtonLobbyShip:SetShowTips(bShow)
    local pVisibility = bShow and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed
    self.pWidgetRef.imgTipIcon:SetVisibility(pVisibility)
end

return UPTabButtonLobbyShip