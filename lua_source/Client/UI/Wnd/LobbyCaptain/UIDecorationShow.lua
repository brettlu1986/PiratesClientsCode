-----------------------------------------------------
--File Name    : UIDecorationShow.lua
--Author       : lzheng
--Create Time  : 6/30/2020
--Description  : UIDecorationShow
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")

local UIDef = require("UIDef")
local UIDecorationShow = luaclass("UIDecorationShow", WndBase)
local UILobbyCaptainHelper = require("UILobbyCaptainHelper")

UIDecorationShow.ulDecoration = nil
UIDecorationShow.pDecorationInfo = nil
UIDecorationShow.pbWindowFrame = nil  

function UIDecorationShow:OnLoad()
    local PrefabHelper = self.PrefabHelper
    local pWidgetRef = self.pWidgetRef

    self.pDecorationInfo = PrefabHelper:BindPrefab(pWidgetRef.pbLobbyCaptain03, UIDef.UP_CAPTAIN_ITEM_INFO)
    self.pbWindowFrame = PrefabHelper:BindPrefab(pWidgetRef.pbWindowFrame)

    local UILogicHelper = self.UILogicHelper
    self.ulDecoration = UILogicHelper:CreateUILogic("ULLobbyDecoration")
end

function UIDecorationShow:OnShow()
    self.ulDecoration:Activate(UILobbyCaptainHelper.DecorationUIType.SHOW, self.tbOpenArgs)
end

function UIDecorationShow:OnUnload()
    self.ulDecoration:Deactivate()
end

return UIDecorationShow