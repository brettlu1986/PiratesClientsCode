-----------------------------------------------------
--File Name    : UILobbyCaptainDecoration.lua
--Author       : lzheng
--Create Time  : 4/29/2020
--Description  : UILobbyCaptainDecoration
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")

local UIDef = require("UIDef")
local UILobbyCaptainDecoration = luaclass("UILobbyCaptainDecoration", WndBase)
local UILobbyCaptainHelper = require("UILobbyCaptainHelper")

UILobbyCaptainDecoration.ulDecoration = nil
UILobbyCaptainDecoration.pDecorationInfo = nil

local DECORATION_CURRENCY = 1400010

function UILobbyCaptainDecoration:OnLoad()
    local PrefabHelper = self.PrefabHelper
    local pWidgetRef = self.pWidgetRef

    self.pDecorationInfo = PrefabHelper:BindPrefab(pWidgetRef.pbLobbyCaptain03, UIDef.UP_CAPTAIN_ITEM_INFO)
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetSpecialCurrency(DECORATION_CURRENCY)

    local UILogicHelper = self.UILogicHelper
    self.ulDecoration = UILogicHelper:CreateUILogic("ULLobbyDecoration")
end

function UILobbyCaptainDecoration:OnShow()
    self.ulDecoration:Activate(UILobbyCaptainHelper.DecorationUIType.MAIN)
end

function UILobbyCaptainDecoration:OnUnload()
    self.ulDecoration:Deactivate()
end

return UILobbyCaptainDecoration