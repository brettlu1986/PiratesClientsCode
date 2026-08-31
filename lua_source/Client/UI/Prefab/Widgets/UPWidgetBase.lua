-----------------------------------------------------
--File Name    : UPWidgetBase.lua
--Author       : Zuo Kun
--Create Time  : 2017-05-10
-----------------------------------------------------
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPWidgetBase = luaclass("UPWidgetBase", PrefabBase)

UPWidgetBase.Owner = nil 
UPWidgetBase.OwnerGameObject = nil 
UPWidgetBase.pWidgetComponent = nil 

function UPWidgetBase:WidgetCreated(Owner)
    self.Owner = Owner
    self.OwnerGameObject = Owner:GetOwner()
    self.pWidgetComponent = Owner.pWidgetComponent

    self:OnWidgetCreated()
end 

function UPWidgetBase:OnActorDestroyed(pUEActor)
end

function UPWidgetBase:OnWidgetCreated()
end 

function UPWidgetBase:RefreshWidget(tbParams)
end 


return UPWidgetBase
