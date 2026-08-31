-----------------------------------------------------
--File Name    : UILobbyShowShipPart.lua
--Author       : chenyixin
--Description  : 商城零件纯展示界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbyShowShipPart = luaclass("UILobbyShowShipPart", WndBase)

local ItemDataTable = require("ItemDataTable")
local LobbySystem = require("LobbySystem")

local SHIP_WND_KEY = "Part"

UILobbyShowShipPart.OwnerSub = nil
UILobbyShowShipPart.tbPartTitle = nil
UILobbyShowShipPart.pbWindowFrame = nil
UILobbyShowShipPart.ulLobbyShipPart = nil

UILobbyShowShipPart.nPreSelectedCategory = nil

local function UpdateTitleData(self, nId)
    local tbTemplate = ItemDataTable:GetTemplate(nId)
    self.tbPartTitle:SetData(tbTemplate)
    self.OwnerSub:ShowShipDisplayScene(true, tbTemplate.nSubCategory)
end

local function UpdatePartDisplay(self, nId)
    self.ulLobbyShipPart:DisplayPart(nId, true)
end

local function InitPartTitle(self)
    local pWidgetRef = self.pWidgetRef
    local tbTitle = self.PrefabHelper:BindPrefab(pWidgetRef.pbPartTitle1)
    self.tbPartTitle = tbTitle
end

local function OnBackClicked(self)
    LobbySystem:ReturnToPrevSub()
end

function UILobbyShowShipPart:OnLoad()
    local tbOpenArgs = self.tbOpenArgs
    self.OwnerSub = tbOpenArgs.OwnerSub
    self.OwnerSub.szCurOpenWndKey = SHIP_WND_KEY
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetBackDelegate(OnBackClicked, self)
    InitPartTitle(self)
    self.ulLobbyShipPart = self.UILogicHelper:CreateUILogic("ULLobbyShipPart")
end

function UILobbyShowShipPart:OnUnload()
    self.OwnerSub.szCurOpenWndKey = nil
end

function UILobbyShowShipPart:OnShow()
    local nId = self.tbOpenArgs.nItemTemplateId
    UpdatePartDisplay(self, nId)
    UpdateTitleData(self, nId)
    self:PlayAnimation("anim_LobbyShipPartIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UILobbyShowShipPart:OnExit()
    self.ulLobbyShipPart:ClearDisplay()
end

function UILobbyShowShipPart:OnBindEvent(EventHelper)
    
end

return UILobbyShowShipPart