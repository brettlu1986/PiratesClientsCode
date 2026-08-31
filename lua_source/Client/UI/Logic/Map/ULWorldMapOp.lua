-----------------------------------------------------
--File Name    : ULWorldMapOp.lua
--Author       : Ran Jie
--Create Time  : 2019-9-9
--Description  : ULWorldMapOp
-----------------------------------------------------
local luaclass = require("luaclass")
local ULMapOp = require("ULMapOp")
local ULWorldMapOp = luaclass("ULWorldMapOp", ULMapOp)
--import
local FlagMapLocationSystem = require("FlagMapLocationSystem")
local ClientEventDef = require("ClientEventDef")




--------------------------------------------------------------
local function OnClearAllFlagPoint(self)
    self:UnregisterOperation("MapOpFFAFlagLine")
end


-- --override
function ULWorldMapOp:OnLoad()
    self.Owner.Owner.pWidgetRef.btnSymbol:SetVisibility(ESlateVisibility_Collapsed)
    self.Owner.Owner.pWidgetRef.bdrSymbol:SetVisibility(ESlateVisibility_Collapsed)
end

function ULWorldMapOp:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_CLEAR_ALL_FLAG_POINT, self, OnClearAllFlagPoint) 
end

function ULWorldMapOp:OnClickMapWorldPos(nWorldPosX, nWorldPosY)
    FlagMapLocationSystem:SetFlagPos(true, nWorldPosX, nWorldPosY)
end

return ULWorldMapOp
