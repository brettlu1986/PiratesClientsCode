-----------------------------------------------------
--File Name    : UPSelfShip.lua
--Author       : Xu Weihua
--Create Time  : 2018-09-18
--Description  : The ship building UI element showing the ship the self player currently owns.
-----------------------------------------------------
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPSelfShip = luaclass("UPSelfShip", PrefabBase)
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local ShipResDataTable = require("ShipResDataTable")

UPSelfShip.OnSelfShipPressedDelegate = nil

local function Refresh(self)
    -- Get the self player's active ship item.
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local ActiveShipItem = BattleItemSystemHelper:GetEquippedItem(
        nCharacterInstanceId, BattleItemCategoryDef.SHIP, nCharacterInstanceId, 1, true)

    if not ActiveShipItem then
        return
    end

    local tbItemTemplate = ActiveShipItem:GetTemplate()
    -- Set the icon for the ship item.
    local nShipId = tbItemTemplate.nShipId
    local tbShipResTemplate = ShipResDataTable:GetTemplate(nShipId)
    local szIconPath = tbShipResTemplate.szIconPath
    local pWidgetRef = self.pWidgetRef
    UISetUtils.SetImageBrushRes(pWidgetRef.imgPackItemBg, szIconPath:load())

    -- Refresh stars
    local nGrade = tbItemTemplate.nGrade
    local szGradeIcon = UIResourceDef.SHIP_GRADE_ICON[nGrade]
    UISetUtils.SetImageBrushRes(pWidgetRef.imgShipGrade, szGradeIcon:load())

    pWidgetRef.txtDesc:SetText(tbItemTemplate.l10nName)
end

local function OnClickedBtnSelect(self)
    if self.OnSelfShipPressedDelegate then
        self.OnSelfShipPressedDelegate:Fire()
    end
end

function UPSelfShip:OnShow()
    Refresh(self)
end

function UPSelfShip:Refresh()
    Refresh(self)
end

function UPSelfShip:SetSelected(bSelected)
    local imgSelected = self.pWidgetRef.imgSelected
    if bSelected then
        imgSelected:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        imgSelected:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UPSelfShip:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSelect.OnClicked, self, OnClickedBtnSelect)
end

function UPSelfShip:OnUnbindEvent(EventHelper)
end


return UPSelfShip
