-----------------------------------------------------
--File Name    : UIBuildItem.lua
--Author       : zhiyuan
--Create Time  : 2019-03-18
--Description  : 新的建造UI
-----------------------------------------------------

local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIBuildItem = luaclass("UIBuildItem", WndBase)

local UIDef = require("UIDef")
local UIManager = require("UIManager")
local UISetUtils = require("UISetUtils")
local ClientEventDef = require("ClientEventDef")
local ControlModeDef = require("ControlModeDef")
local BuildTipsHelper = require("BuildTipsHelper")
local SelfTabBarHelper = require("SelfTabBarHelper")
local BattleItemDataTable = require("BattleItemDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemSystemClient = require("BattleItemSystemClient")
local CheckCanBuildItemHelper = require("CheckCanBuildItemHelper")

UIBuildItem.ulBuildShip = nil
UIBuildItem.ulBuildShipPart = nil
UIBuildItem.ulBuildShipWeapon = nil
UIBuildItem.ulBuildHumanWeapon = nil
UIBuildItem.ulBuildHumanArmor = nil

UIBuildItem.nCurrentTopTabIndex = nil
UIBuildItem.nCurrentRightTabIndex = nil

UIBuildItem.tbTopTabBarHelper = nil
UIBuildItem.tbRightTabBarHelper = nil

local HUMAN_TOP_TAB_INDEX = 1
local SHIP_TOP_TAB_INDEX = 2

local SHIP_RIGHT_TAB_INDEX = 1
local SHIP_PART_RIGHT_TAB_INDEX = 2
local SHIP_WEAPON_RIGHT_TAB_INDEX = 3

local HUMAN_WEAPON_RIGHT_TAB_INDEX = 1
local HUMAN_ARMOR_RIGHT_TAB_INDEX = 2

local SHIP_TYPE = 1
local SHIP_PART_TYPE = 2
local SHIP_WEAPON_TYPE = 3
local HUMAN_WEAPON_TYPE = 4
local HUMAN_ARMOR_TYPE = 5

local function GetTabIndexes(self)
    if self.nCurrentTopTabIndex == nil or self.nCurrentRightTabIndex == nil then
        local tbPlayerSelf = GamePlayerSelfHelper:Get()
        if tbPlayerSelf:IsShip() then
            return SHIP_TOP_TAB_INDEX, SHIP_RIGHT_TAB_INDEX
        else
            return HUMAN_TOP_TAB_INDEX, HUMAN_WEAPON_RIGHT_TAB_INDEX
        end
    end
    return self.nCurrentTopTabIndex, self.nCurrentRightTabIndex
end

local function GetCurrentType(self)
    local nType = nil
    local nCurrentTopTabIndex = self.nCurrentTopTabIndex
    local nCurrentRightTabIndex = self.nCurrentRightTabIndex
    if nCurrentTopTabIndex == HUMAN_TOP_TAB_INDEX then
        if nCurrentRightTabIndex == HUMAN_WEAPON_RIGHT_TAB_INDEX then
            nType = HUMAN_WEAPON_TYPE
        elseif nCurrentRightTabIndex == HUMAN_ARMOR_RIGHT_TAB_INDEX then
            nType = HUMAN_ARMOR_TYPE
        end
    elseif nCurrentTopTabIndex == SHIP_TOP_TAB_INDEX then
        if nCurrentRightTabIndex == SHIP_RIGHT_TAB_INDEX then
            nType = SHIP_TYPE
        elseif nCurrentRightTabIndex == SHIP_PART_RIGHT_TAB_INDEX then
            nType = SHIP_PART_TYPE
        elseif nCurrentRightTabIndex == SHIP_WEAPON_RIGHT_TAB_INDEX then
            nType = SHIP_WEAPON_TYPE
        end
    end
    return nType
end

local function GetULByType(self, nType)
    if nType == SHIP_TYPE then
        return self.ulBuildShip
    elseif nType == SHIP_PART_TYPE then
        return self.ulBuildShipPart
    elseif nType == SHIP_WEAPON_TYPE then
        return self.ulBuildShipWeapon
    elseif nType == HUMAN_WEAPON_TYPE then
        return self.ulBuildHumanWeapon
    elseif nType == HUMAN_ARMOR_TYPE then
        return self.ulBuildHumanArmor
    end
    return nil
end

local function CloseWnd(self)
    UIManager:CloseWnd(UIDef.UI_BUILD_ITEM)
end

local function OnCloseBtnClicked(self)
    CloseWnd(self)
end

local function RefreshRightTabNames(self)
    local tbRightTabBarHelper = self.tbRightTabBarHelper
    if self.nCurrentTopTabIndex == HUMAN_TOP_TAB_INDEX then
        tbRightTabBarHelper:SetTabText(1, UISetUtils.GetL10NTextByKey("UI_BUILD_ITEM_TAB_HUMAN_WEAPON"))
        tbRightTabBarHelper:SetTabText(2, UISetUtils.GetL10NTextByKey("UI_BUILD_ITEM_TAB_HUMAN_ARMOR"))
        self.pWidgetRef.pbTab3:SetVisibility(ESlateVisibility.Collapsed)
    elseif self.nCurrentTopTabIndex == SHIP_TOP_TAB_INDEX then
        tbRightTabBarHelper:SetTabText(1, UISetUtils.GetL10NTextByKey("UI_BUILD_ITEM_TAB_SHIP"))
        tbRightTabBarHelper:SetTabText(2, UISetUtils.GetL10NTextByKey("UI_BUILD_ITEM_TAB_SHIP_PART"))
        self.pWidgetRef.pbTab3:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        tbRightTabBarHelper:SetTabText(3, UISetUtils.GetL10NTextByKey("UI_BUILD_ITEM_TAB_SHIP_WEAPON"))
    end
end

local function RefreshUL(self)
    local nType = GetCurrentType(self)
    self.pWidgetRef.wsContent:SetActiveWidgetIndex(nType - 1)
    GetULByType(self, nType):Refresh()
end

local function RefreshTabContent(self, nTopTabIndex, nRightTabIndex)
    local nOldTopTabIndex = self.nCurrentTopTabIndex
    self.nCurrentTopTabIndex = nTopTabIndex
    self.nCurrentRightTabIndex = nRightTabIndex
    self.tbTopTabBarHelper:SelectByIndex(nTopTabIndex)
    self.tbRightTabBarHelper:SelectByIndex(nRightTabIndex)
    if nOldTopTabIndex ~= nTopTabIndex then
        RefreshRightTabNames(self)
    end
    RefreshUL(self)
    self:CloseTips()
end

local function RefreshCurrentTabContent(self)
    RefreshTabContent(self, self.nCurrentTopTabIndex, self.nCurrentRightTabIndex)
end

local function SetTopTabRedState(self, nTabIndex, bRedVisible)
    self.tbTopTabBarHelper:SetTipIconVisible(nTabIndex, bRedVisible)
end

local function SetRightTabRedState(self, nTabIndex, bRedVisible)
    self.tbRightTabBarHelper:SetTipIconVisible(nTabIndex, bRedVisible)
end

local function RefreshTabRedStates(self)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local bBuildShipRedVisible = CheckCanBuildItemHelper.CanBuildShip(nCharacterInstanceId, true)
    local bBuildShipPartRedVisible = CheckCanBuildItemHelper.CanBuildShipPart(nCharacterInstanceId, true)
    local bBuildShipWeaponRedVisible = CheckCanBuildItemHelper.CanBuildShipWeapon(nCharacterInstanceId, true)
    local bBuildHumanWeaponRedVisible = CheckCanBuildItemHelper.CanBuildHumanWeapon(nCharacterInstanceId, true)
    local bBuildHumanArmorRedVisible = CheckCanBuildItemHelper.CanBuildHumanArmor(nCharacterInstanceId, true)

    if bBuildShipRedVisible or bBuildShipPartRedVisible or bBuildShipWeaponRedVisible then
        SetTopTabRedState(self, SHIP_TOP_TAB_INDEX, true)
    else
        SetTopTabRedState(self, SHIP_TOP_TAB_INDEX, false)
    end

    if bBuildHumanWeaponRedVisible or bBuildHumanArmorRedVisible then
        SetTopTabRedState(self, HUMAN_TOP_TAB_INDEX, true)
    else
        SetTopTabRedState(self, HUMAN_TOP_TAB_INDEX, false)
    end

    if self.nCurrentTopTabIndex == HUMAN_TOP_TAB_INDEX then
        SetRightTabRedState(self, HUMAN_WEAPON_RIGHT_TAB_INDEX, bBuildHumanWeaponRedVisible)
        SetRightTabRedState(self, HUMAN_ARMOR_RIGHT_TAB_INDEX, bBuildHumanArmorRedVisible)
    elseif self.nCurrentTopTabIndex == SHIP_TOP_TAB_INDEX then
        SetRightTabRedState(self, SHIP_RIGHT_TAB_INDEX, bBuildShipRedVisible)
        SetRightTabRedState(self, SHIP_PART_RIGHT_TAB_INDEX, bBuildShipPartRedVisible)
        SetRightTabRedState(self, SHIP_WEAPON_RIGHT_TAB_INDEX, bBuildShipWeaponRedVisible)
    end

end

local function OnTopTabSelected(self, nTopTabIndex)
    if self.nCurrentTopTabIndex == nTopTabIndex then
        return
    end
    RefreshTabContent(self, nTopTabIndex, 1)
    RefreshTabRedStates(self)
end

local function OnRightTabSelected(self, nRightTabIndex)
    if self.nCurrentRightTabIndex == nRightTabIndex then
        return
    end
    RefreshTabContent(self, self.nCurrentTopTabIndex, nRightTabIndex)
end

local function OnBeginItemBuild(self)
    CloseWnd(self)
end

local function OnFFAControlModeActivate(self, nControlMode)
    if nControlMode == ControlModeDef.TRANSPORTNEW then
        CloseWnd(self)
    end
end

local function OnItemAdded(self, NewItem)
    local nCategory = NewItem:GetCategory()
    local nType = GetCurrentType(self)
    if nCategory == BattleItemCategoryDef.SHIP and nType == SHIP_TYPE then
        RefreshCurrentTabContent(self)
    elseif nCategory == BattleItemCategoryDef.SHIP_PART and nType == SHIP_PART_TYPE then
        RefreshCurrentTabContent(self)
    elseif nCategory == BattleItemCategoryDef.SHIP_WEAPON and nType == SHIP_WEAPON_TYPE then
        RefreshCurrentTabContent(self)
    elseif nCategory == BattleItemCategoryDef.HUMAN_WEAPON and nType == HUMAN_WEAPON_TYPE then
        RefreshCurrentTabContent(self)
    elseif nCategory == BattleItemCategoryDef.HUMAN_ARMOR and nType == HUMAN_ARMOR_TYPE then
        RefreshCurrentTabContent(self)
    end
    RefreshTabRedStates(self)
end

local function OnItemRemoved(self, _, nItemTemplateId)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    local nType = GetCurrentType(self)
    if nCategory == BattleItemCategoryDef.SHIP_PART and nType == SHIP_PART_TYPE then
        RefreshCurrentTabContent(self)
    elseif nCategory == BattleItemCategoryDef.SHIP_WEAPON and nType == SHIP_WEAPON_TYPE then
        RefreshCurrentTabContent(self)
    elseif nCategory == BattleItemCategoryDef.HUMAN_WEAPON and nType == HUMAN_WEAPON_TYPE then
        RefreshCurrentTabContent(self)
    elseif nCategory == BattleItemCategoryDef.HUMAN_ARMOR and nType == HUMAN_ARMOR_TYPE then
        RefreshCurrentTabContent(self)
    end
    RefreshTabRedStates(self)
end

local function OnItemChangeStackCount(self)
    RefreshTabRedStates(self)
end

local function OnShipBuildGradeChanged(self, tbPlayer, _)
    local nType = GetCurrentType(self)
    if GamePlayerSelfHelper:GetServerInstanceId() == tbPlayer:GetServerInstanceId() and nType == SHIP_TYPE then
        RefreshCurrentTabContent(self)
    end
end

local function OnItemChangeStorageLocation(self, nItemInstanceId)
    local tbItem = BattleItemSystemClient:GetItem(nItemInstanceId)
    local nCategory = tbItem:GetCategory()
    local nType = GetCurrentType(self)
    if nCategory == BattleItemCategoryDef.HUMAN_WEAPON and nType == HUMAN_WEAPON_TYPE then
        RefreshCurrentTabContent(self)
    end
end

local function OnItemExchangeStorageLocation(self, Item1, _)
    local nCategory = Item1:GetCategory()
    local nType = GetCurrentType(self)
    if nCategory == BattleItemCategoryDef.HUMAN_WEAPON and nType == HUMAN_WEAPON_TYPE then
        RefreshCurrentTabContent(self)
    end
end

function UIBuildItem:CloseTips()
    BuildTipsHelper.CloseTipsWnd()
end

function UIBuildItem:ShowBuildShipTips(nSelectedItemTemplateId)
    BuildTipsHelper.ShowBuildTips(BattleItemCategoryDef.SHIP, nSelectedItemTemplateId)
end

function UIBuildItem:ShowBuildItemTips(nSelectedItemTemplateId, nSlotIndex)
    BuildTipsHelper.ShowBuildTips(BattleItemCategoryDef.SHIP_PART, nSelectedItemTemplateId, nSlotIndex)
end

function UIBuildItem:ShowBuildItemTipsNew(nSelectedItemTemplateId, nSlotIndex)
    -- Common item
    BuildTipsHelper.ShowBuildTips(BattleItemCategoryDef.HUMAN_WEAPON, nSelectedItemTemplateId, nSlotIndex)
end

function UIBuildItem:OnLoad()
    log("[DEBUG_UI] UIBuildItem:OnLoad")
    local UILogicHelper = self.UILogicHelper
    self.ulBuildShip = UILogicHelper:CreateUILogic("ULBuildShip")
    self.ulBuildShipPart = UILogicHelper:CreateUILogic("ULBuildShipPart")
    self.ulBuildShipWeapon = UILogicHelper:CreateUILogic("ULBuildShipWeapon")
    self.ulBuildHumanWeapon = UILogicHelper:CreateUILogic("ULBuildHumanWeapon")
    self.ulBuildHumanArmor = UILogicHelper:CreateUILogic("ULBuildHumanArmor")

    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    PrefabHelper:BindPrefab(pWidgetRef.pbCutoutScreenAdapter)

    self.tbTopTabBarHelper = SelfTabBarHelper()
    self.tbTopTabBarHelper:Init(self, pWidgetRef.hboxTopTab)
    self.tbTopTabBarHelper.OnSelectedChangedDelegate:Bind(OnTopTabSelected, self)

    self.tbRightTabBarHelper = SelfTabBarHelper()
    self.tbRightTabBarHelper:Init(self, pWidgetRef.vboxRightTab)
    self.tbRightTabBarHelper.OnSelectedChangedDelegate:Bind(OnRightTabSelected, self)
end

function UIBuildItem:OnUnload()
    if self.tbTopTabBarHelper then
        self.tbTopTabBarHelper:Uninit()
        self.tbTopTabBarHelper = nil
    end

    if self.tbRightTabBarHelper then
        self.tbRightTabBarHelper:Uninit()
        self.tbRightTabBarHelper = nil
    end
end

function UIBuildItem:OnShow()
    log("[DEBUG_UI] UIBuildItem:OnShow")
    local nCurrentTopTabIndex, nCurrentRightTabIndex = GetTabIndexes(self)
    RefreshTabContent(self, nCurrentTopTabIndex, nCurrentRightTabIndex)
    RefreshTabRedStates(self)
end

function UIBuildItem:OnEnter()
    log("[DEBUG_UI] UIBuildItem:OnEnter")
end


function UIBuildItem:OnExit()
    self:CloseTips()
end

function UIBuildItem:OnBindEvent(EventHelper)
    log("[DEBUG_UI] UIBuildItem:OnBindEvent begin")
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.kmbtnClose.OnClicked, self, OnCloseBtnClicked)

    EventHelper:RegisterEvent(ClientEventDef.EV_BEGIN_ITEM_BUILD, self, OnBeginItemBuild)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_CONTROL_MODE_ACTIVATE, self, OnFFAControlModeActivate)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT, self, OnItemAdded)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_REMOVE_CLIENT, self, OnItemRemoved)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT, self, OnItemChangeStackCount)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STORAGE_LOCATION_CLIENT, self, OnItemChangeStorageLocation)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_EXCHANGE_STORAGE_LOCATION_CLIENT, self, OnItemExchangeStorageLocation)
    EventHelper:RegisterEvent(ClientEventDef.EV_SHIP_BUILD_GRADE_CHANGED_CLIENT, self, OnShipBuildGradeChanged)
end

return UIBuildItem
