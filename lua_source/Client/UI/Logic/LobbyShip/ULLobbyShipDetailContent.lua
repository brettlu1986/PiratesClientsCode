-----------------------------------------------------
--File Name    : ULLobbyShipDetailContent.lua
--Author       : chenyixin
--Description  : 舰船界面详情UP
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULLobbyShipDetailContent = luaclass("ULLobbyShipDetailContent", UILogicBase)

local ShipDataDisplayHelper = require("ShipDataDisplayHelper")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local UISetUtils = require("UISetUtils")
-- local UIResourceDef = require("UIResourceDef")
local UITextDef = require("UITextDef")

local DISPLAY_CATEGORY = ShipDataDisplayHelper.DISPLAY_CATEGORY

-- 四维图参数
local SCALAR_PARAMETER = {
    [DISPLAY_CATEGORY.CONCEAL]      = "a",
    [DISPLAY_CATEGORY.VITALITY]     = "b",
    [DISPLAY_CATEGORY.FIRE_POWER]   = "c",
    [DISPLAY_CATEGORY.MOVEMENT]     = "d",
}

-- local LOBBY_COMMON_TIPS_TITLE_RES = UIResourceDef.LOBBY_COMMON.TIPS_TITLE
local SHIP_DETAIL_SWITCH_BTN_RES = {
    ["Basic"] = "PaperSprite'/Game/UI/Textures/LobbyShip/Frames/Spr_LobbyShip10.Spr_LobbyShip10'",
    ["Detailed"] = "PaperSprite'/Game/UI/Textures/LobbyShip/Frames/Spr_LobbyShip09.Spr_LobbyShip09'",
}

ULLobbyShipDetailContent.ListHelper = nil
ULLobbyShipDetailContent.tbRawPropertiesData = nil
ULLobbyShipDetailContent.bShowDetailedInfo = false

ULLobbyShipDetailContent.fnOnBtnDetailClicked = nil
ULLobbyShipDetailContent.bBuild = false

-- 获取四维图数据和详细信息
local function GetPropertyData(tbRawPropertiesData)
    local tbDimensionalUnits = {}
    local tbDetailedInfo = {}
    for _, tbCategoryData in pairs(tbRawPropertiesData) do
        local szDimentionName = SCALAR_PARAMETER[tbCategoryData.nCategoryIndex]
        if szDimentionName then
            tbDimensionalUnits[szDimentionName] = tbCategoryData.nScore / 100 * 1.15
        end
        for _, tbProperty in pairs(tbCategoryData.tbProperties) do
            table.insert(tbDetailedInfo, tbProperty)
        end
    end

    return tbDimensionalUnits, tbDetailedInfo
end

local function SetDetailedInfo(self, tbRawPropertiesData)
    local tbDimensionalUnits, tbDetailedInfo = GetPropertyData(tbRawPropertiesData)

    local pWidgetRef = self.pWidgetRef
    pWidgetRef:Set4DGraphParamValue(tbDimensionalUnits["a"], tbDimensionalUnits["b"], tbDimensionalUnits["c"], tbDimensionalUnits["d"])
    self.ListHelper:SetData(tbDetailedInfo)
end

local function SetShowDetailedInfo(self, bShowDetailedInfo)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.WidgetSwitcher_0:SetActiveWidgetIndex(bShowDetailedInfo and 1 or 0)
    local szBtnImg = bShowDetailedInfo and SHIP_DETAIL_SWITCH_BTN_RES.Detailed or SHIP_DETAIL_SWITCH_BTN_RES.Basic
    UISetUtils.SetButtonBrushRes(pWidgetRef.KMButton_0, szBtnImg:load())
    if not self.bBuild then
        local l10nTitle = bShowDetailedInfo and UITextDef.UI_STATIC_LOBBY_SHIP_DETAIL_DETAILED_INFO or UITextDef.UI_STATIC_LOBBY_SHIP_DETAIL_BASIC_INFO
        pWidgetRef.ktxtTitle:SetText(l10nTitle)
    end
    self.bShowDetailedInfo = bShowDetailedInfo
end

local function OnDetailBtnClicked(self)
    self:ToggleShowDetailedInfo()
    if self.fnOnBtnDetailClicked then
        self.fnOnBtnDetailClicked(self.bShowDetailedInfo and 2 or 1)
    end
end

function ULLobbyShipDetailContent:OnLoad()
    self.OwnerSub = self.Owner.OwnerSub
    local pWidgetRef = self.pWidgetRef

    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, pWidgetRef.KMVerticalList_0)

end

function ULLobbyShipDetailContent:OnUnload()
    self.ListHelper:Uninit()
    self.ListHelper = nil
end

function ULLobbyShipDetailContent:OnShow()
end

function ULLobbyShipDetailContent:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.KMButton_0.OnClicked, self, OnDetailBtnClicked)
end

function ULLobbyShipDetailContent:SetShipTemplateId(nBattleItemId)
    if not nBattleItemId then
        self.tbRawPropertiesData = nil
        return
    end
    local tbDataDisplayHelper = ShipDataDisplayHelper.New(nBattleItemId)
    self.tbRawPropertiesData = tbDataDisplayHelper:GetDisplayDataGroup()
    SetDetailedInfo(self, self.tbRawPropertiesData)

    local pWidgetRef = self.pWidgetRef

    local tbTemplate = tbDataDisplayHelper:GetTemplate()

    if pWidgetRef.ktxtDesc then
        local l10nDesc = tbDataDisplayHelper:GetDescription()
        if l10nDesc then
            pWidgetRef.ktxtDesc:SetText(l10nDesc)
        end
    end

    if self.bBuild then
        pWidgetRef.ktxtTitle:SetText(tbTemplate.l10nName)
    end
    -- SetShowDetailedInfo(self, false)
end

function ULLobbyShipDetailContent:BindOnBtnDetailClicked(fnOnBtnDetailClicked)
    self.fnOnBtnDetailClicked = fnOnBtnDetailClicked
end

function ULLobbyShipDetailContent:CanShow()
    return self.tbRawPropertiesData ~= nil
end

function ULLobbyShipDetailContent:ToggleShowDetailedInfo()
    SetShowDetailedInfo(self, not self.bShowDetailedInfo)
end

function ULLobbyShipDetailContent:SetShowDetailedInfo(bShow)
    SetShowDetailedInfo(self, bShow)
end

return ULLobbyShipDetailContent