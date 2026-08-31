-----------------------------------------------------
--File Name    : UPLobbyExpression.lua
--Author       : Edward J
--Create Time  : 2019-04-10
--Description  : lobby Chat Expression Panel
-----------------------------------------------------
local luaclass              = require("luaclass")
local ListItemBase          = require("ListItemBase")
local UPLobbyExpression     = luaclass("UPLobbyExpression", ListItemBase)

local UISetUtils        = require("UISetUtils")
local ClientEventDef    = require("ClientEventDef")
local EventManager      = require("EventManager") 
-----------------------------------------------------
UPLobbyExpression.nExpressionId = 1
-----------------------------------------------------

local function OnClickedExpression(self)
    EventManager:OnFireEvent(ClientEventDef.EV_CLICK_EXPRESSION, self.nExpressionId)
end

function UPLobbyExpression:OnRefresh(tbData)
    if not tbData then
        return
    end
    local pWidgetRef = self.pWidgetRef
    self.nExpressionId = tbData.nId
    local szRes = tbData.szRes
    UISetUtils.SetImageBrushRes(pWidgetRef.imgExpression, szRes:load())
end

function UPLobbyExpression:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnExpression.OnClicked, self, OnClickedExpression)
end

return UPLobbyExpression