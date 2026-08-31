-----------------------------------------------------
--File Name    : ULBuildingMaterials.lua
--Author       : zhiyuan
--Create Time  : 2018-09-29
--Description  : ffa主界面上当前拥有的材料的ui逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULBuildingMaterials = luaclass("ULBuildingMaterials", UILogicBase)
local UIDef = require("UIDef")
local UIManager = require("UIManager")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local CheckCanBuildItemHelper = require("CheckCanBuildItemHelper")
local ClientEventDef = require("ClientEventDef")
local BattleItemRoomDef = require("BattleItemRoomDef")
local BattleItemDataTable = require("BattleItemDataTable")

local ANIM_NAME = "animBuildLight"
local DELAY_REFRESH_SECONDS = 0.5

ULBuildingMaterials.tbDelayCheckHandle = nil
ULBuildingMaterials.bCanBuildAnimEnable= true

local function PlayCanBuildPromptAnim(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.imgBuildLight:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    if not self.bIsPlayingCanBuildAnim then
        self.bIsPlayingCanBuildAnim = true
        self.Owner:PlayAnimation(ANIM_NAME, 0, 0, EUMGSequencePlayMode.Forward, 1)
    end
end

local function StopCanBuildPromptAnim(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.imgBuildLight:SetVisibility(ESlateVisibility.Collapsed)
    if self.bIsPlayingCanBuildAnim then
        self.bIsPlayingCanBuildAnim = false
        self.Owner:StopAnimation(ANIM_NAME)
    end
end

local function OnSetCanBuildAnimEnable(self)
    StopCanBuildPromptAnim(self)
    self.bCanBuildAnimEnable = false
end

local function ShowCanBuildPrompt(self)
    if not self.bCanBuildAnimEnable then
        return
    end
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    if CheckCanBuildItemHelper.CanBuild(nCharacterInstanceId, true) then
        PlayCanBuildPromptAnim(self)
    else
        StopCanBuildPromptAnim(self)
    end
end

local function RefreshHandleCallBack(self)
    if self.tbDelayCheckHandle ~= nil then
        self.tbDelayCheckHandle:Clear()
        self.tbDelayCheckHandle = nil
    end
    ShowCanBuildPrompt(self)
end

local function NeedShowCanBuildPrompt(self)
    if not self.tbDelayCheckHandle then
        self.tbDelayCheckHandle = self.TimerHelper:NewTimerMethod(self, function() RefreshHandleCallBack(self) end, DELAY_REFRESH_SECONDS)
    end
end

local function HasCurrentShipItem()
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local ActiveShipItem = BattleItemSystemHelper:GetEquippedItem(
        nCharacterInstanceId, BattleItemCategoryDef.SHIP, nCharacterInstanceId, 1, true)

    return ActiveShipItem ~= nil
end

local function OnBuildBtnClicked(self)
    if HasCurrentShipItem() then
        self.EventHelper:FireEvent(ClientEventDef.EV_EXIT_OPEN_AIM_CAMERA)
        UIManager:ToggleWnd(UIDef.UI_BUILD_ITEM)
        if UIManager:IsWndVisible(UIDef.UI_FFABACKPACK) then
            UIManager:CloseWnd(UIDef.UI_FFABACKPACK)
        end
    end
end

local function OnMaterialBtnClicked(self)
    UIManager:ToggleWnd(UIDef.UI_FFABACKPACK, {nOpenBattleItemRoom = BattleItemRoomDef.MATERIAL_ROOM})
    if UIManager:IsWndVisible(UIDef.UI_BUILD_ITEM) then
        UIManager:CloseWnd(UIDef.UI_BUILD_ITEM)
    end
end

local function OnCategoryItemChanged(self, nCategory)
    if nCategory == BattleItemCategoryDef.MATERIAL
        or nCategory == BattleItemCategoryDef.BUILD_KEY_ITEM
        or nCategory == BattleItemCategoryDef.SHIP_WEAPON
        or nCategory == BattleItemCategoryDef.SHIP_PART
        or nCategory == BattleItemCategoryDef.HUMAN_WEAPON
        or nCategory == BattleItemCategoryDef.HUMAN_ARMOR
        or nCategory == BattleItemCategoryDef.SHIP then
            NeedShowCanBuildPrompt(self)
    end
end

function ULBuildingMaterials:OnItemChanged()
    NeedShowCanBuildPrompt(self)
end

function ULBuildingMaterials:OnItemAdded(Item)
    local nCategory = Item:GetCategory()
    OnCategoryItemChanged(self, nCategory)
end

function ULBuildingMaterials:OnItemRemoved(nTemplateId)
    local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    local nCategory = tbTemplate.nCategory
    OnCategoryItemChanged(self, nCategory)
end

function ULBuildingMaterials:OnItemChangeStackCount(Item)
    local nCategory = Item:GetCategory()
    OnCategoryItemChanged(self, nCategory)
end

function ULBuildingMaterials:OnLoad()
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    self.pbBuildingCostMaterials = PrefabHelper:BindPrefab(pWidgetRef.pbBuildingMaterials, UIDef.UP_BUILDING_MATERIALS)
    self.bCanBuildAnimEnable = true
    ShowCanBuildPrompt(self)
end

function ULBuildingMaterials:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnBuild.OnClicked, self, OnBuildBtnClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnMaterial.OnClicked, self, OnMaterialBtnClicked)
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_CAN_BUILD_ANIM_ENABLE, self, OnSetCanBuildAnimEnable)
end

return ULBuildingMaterials