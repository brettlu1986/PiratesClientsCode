-----------------------------------------------------
--File Name    : UILobbyShowShip.lua
--Author       : chenyixin
--Description  : 舰船图鉴
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbyShowShip = luaclass("UILobbyShowShip", WndBase)

local UIShipDataTable = require("UIShipDataTable")
local ItemDataTable = require("ItemDataTable")
local ItemCategoryDef = require("ItemCategoryDef")
local DisplayItemHelper = require("DisplayItemHelper")

local LobbySystem = require("LobbySystem")

local SHIP_WND_KEY = "Handbook"
local SHIP_UI_KEY = "lobbyshowship"     -- ui_ship.tab

UILobbyShowShip.tbShipDetail = nil
UILobbyShowShip.tbShipTitle = nil

UILobbyShowShip.nShipTemplateId = nil
UILobbyShowShip.nShipSkinTemplateId = nil

UILobbyShowShip.pbWindowFrame = nil
UILobbyShowShip.ulLobbyShipHandbook = nil

--------- Widget设置 ------------------------------------------------------------

local function UpdateShipDisplay(self)
    if not self:IsVisible() then
        return
    end
    local nShipId = self.nShipTemplateId
    local tbItemTemplate = ItemDataTable:GetTemplate(nShipId)
    local ShipPreparationComponent = self.OwnerSub:GetShipPreparationComponent()

    local tbShipData = self.ulLobbyShipHandbook:GetShipData(tbItemTemplate, ShipPreparationComponent)
    tbShipData.bShowWnd = true
    if self.nShipSkinTemplateId then
        local tbSkinTemplate = ItemDataTable:GetTemplate(self.nShipSkinTemplateId)
        tbShipData.tbSkinTemplate = tbSkinTemplate
        nShipId = self.nShipSkinTemplateId
    end

    local tbModify = nil
    local nIndex = nil

    if self.tbOpenArgs.nCategory == ItemCategoryDef.SHIP then
        tbModify = self.OwnerSub:GetShipModelModifyByKey("Handbook", nShipId)
        nIndex = 1
    else
        local tbShipResTemplate = DisplayItemHelper.GetShipResTemplate(nShipId)
        local tbUIShipTemp = UIShipDataTable:GetTemplate(tbShipResTemplate.nResId, SHIP_UI_KEY)
        
        tbModify = tbUIShipTemp and self.OwnerSub:MakeModify(tbUIShipTemp.tbLocation[1], tbUIShipTemp.tbLocation[2], tbUIShipTemp.tbLocation[3],
                                                                    0, 0, tbUIShipTemp.nYaw,
                                                                    tbUIShipTemp.nScale)
        nIndex = 2
    end

    self.OwnerSub:CreateShipActorById(nShipId, nIndex, tbModify, self:GetWndName())

    self.ulLobbyShipHandbook:UpdateShipDisplay(nShipId, tbShipData, nIndex)
end

---------- widget事件 -----------------------------------------------------------

local function OnBackClicked(self)
    LobbySystem:ReturnToPrevSub()
end

--------- 初始化 -----------------------------------------------------------------

local function InitShipTitle(self)
    local tbShipTitle = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbShipTitle)
    self.tbShipTitle = tbShipTitle
end

----------------- overrides ---------------------------------------------------

function UILobbyShowShip:OnLoad()
    local tbOpenArgs = self.tbOpenArgs
    self.OwnerSub = tbOpenArgs.OwnerSub
    self.OwnerSub.szCurOpenWndKey = SHIP_WND_KEY

    self.nShipTemplateId = tbOpenArgs.nShipTemplateId
    self.nShipSkinTemplateId = tbOpenArgs.nShipSkinTemplateId

    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetBackDelegate(OnBackClicked, self)

    local tbShipDetail = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbLobbyShipDetail)
    self.tbShipDetail = tbShipDetail

    self.ulLobbyShipHandbook = self.UILogicHelper:CreateUILogic("ULLobbyShipHandbook")

    InitShipTitle(self)
end

function UILobbyShowShip:OnUnload()
    self.OwnerSub.szCurOpenWndKey = nil
end

function UILobbyShowShip:OnShow()
    local nCategory = self.tbOpenArgs.nCategory
    local pWidgetRef = self.pWidgetRef
    if nCategory == ItemCategoryDef.SHIP then
        pWidgetRef.vboxDetailContent:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    elseif nCategory == ItemCategoryDef.SHIP_SKIN then
        pWidgetRef.vboxDetailContent:SetVisibility(ESlateVisibility.Collapsed)
    end
    UpdateShipDisplay(self)
    self:PlayAnimation("animStart", 0, 1, EUMGSequencePlayMode.Forward, 1)
    self.tbShipTitle:PlayAnimation("anim_LobbyShipNameIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UILobbyShowShip:OnExit()
    self.OwnerSub:DestroyAllShipActors()
end

return UILobbyShowShip