-----------------------------------------------------
--File Name    : ULFFAHumanThrownItem.lua
--Author       : WuJizhou
--Create Time  : 3/18/2019, 9:48:59 PM
--Description  : ULFFAHumanThrownItem
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")

local ULFFAHumanThrownItem = luaclass("ULFFAHumanThrownItem", UILogicBase)
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemSystemClient = require("BattleItemSystemClient")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleHumanWeaponSystemNew = require("BattleHumanWeaponSystemNew_C")
local HumanWeaponMisc = require("HumanWeaponMisc")
local UIDef = require("UIDef")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
-- local GlobalVariableSystem = require("GlobalVariableSystem_C")
-- local BattleHumanWeaponSystemClient = require("BattleHumanWeaponSystemClient")
local ClientEventDef = require("ClientEventDef")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local WeaponRequestFailReasonDef = require("WeaponRequestFailReasonDef")

local HumanWeaponType = HumanWeaponMisc.Type

ULFFAHumanThrownItem.pbProgressBarBoom = nil

local function OnTryCancelExplosive(self)
    BattleHumanWeaponSystemNew:RequestCancelAttack()
end

--扔手雷，高抛/低抛
local function OnThrowStateChanged(self, bIsChecked)
    local bHigh = not bIsChecked
    BattleHumanWeaponSystemNew:RequestChangeThrowType(bHigh)
end

-- new throw item
local function HideThrowCountDownUI(self)
    self.pbProgressBarBoom:StopProgress()
end

local function ShowThrowCountDownUI(self, nTime)
    HideThrowCountDownUI(self)
    self.pbProgressBarBoom:StartProgress(math.tointeger(nTime))
end

local function OnThrowReady(self, Owner, tbWeapon)
    self.pWidgetRef.btnBoomCancel:SetVisibility(ESlateVisibility.Visible)

    local tbProperty = tbWeapon:GetProperty()
    if(tbProperty.nPreExplodeTime > 0) then
        ShowThrowCountDownUI(self, tbProperty.nPreExplodeTime)
    end
end

local function OnThrowed(self, Owner)
    self.pWidgetRef.btnBoomCancel:SetVisibility(ESlateVisibility.Collapsed)
    self.Owner:SetThrowTrojectoryVisible(false)
end

local function OnThrowCancel(self, Owner)
    self.pWidgetRef.btnBoomCancel:SetVisibility(ESlateVisibility.Collapsed)
    HideThrowCountDownUI(self)
end

local function SelectStateChecker(nItemTemplateId)
    local bSelected = false
    local tbPlayer = GamePlayerSelfHelper:Get()
    if tbPlayer:IsHuman() and tbPlayer.HumanWeaponComponent then
        local nCurrentWeaponId = tbPlayer.HumanWeaponComponent:GetCurrentWeaponInstanceId()
        local tbItem = BattleItemSystemClient:GetItem(nCurrentWeaponId)
        if tbItem ~= nil and tbItem:GetTemplateId() == nItemTemplateId then
            bSelected = true
        end
    end
    return bSelected
end

local function SelectGridOperator(nItemTemplateId)
    local nInstanceId = BattleItemSystemClient:GetUnequippedLeastStackCountInstanceId(nItemTemplateId)
    if not nInstanceId then
        return
    end
    if BattleHumanWeaponSystemNew:RequestHoldThrownWeapon(nInstanceId) == WeaponRequestFailReasonDef.IsAttacking then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("CANNOT_CHANGE_WEAPON_WHILE_ATTACKING"))
    end
end

local function DataProvider()
    local nCategory = BattleItemCategoryDef.HUMAN_THROWN_ITEM
    local tbItems = BattleItemSystemClient:GetUnequippedItemsByCategory(nCategory)
    local tbTemplateIds = {}
    local tbRetList = {}
    for _, v in pairs(tbItems) do
        local nTemplateId = v:GetTemplateId()
        local tbTemplatePair = tbTemplateIds[nTemplateId]
        if not tbTemplatePair then
            tbTemplatePair = {}
            tbTemplateIds[nTemplateId] = tbTemplatePair
            table.insert(tbRetList, tbTemplatePair)
            tbTemplatePair.nTemplateId = nTemplateId
            tbTemplatePair.nCount = v:GetStackCount()
        else
            tbTemplatePair.nCount = tbTemplatePair.nCount + v:GetStackCount()
        end
    end
    return tbRetList, nCategory
end

local function ShortcutOperator(nItemTemplateId)
    local nInstanceId = BattleItemSystemClient:GetUnequippedLeastStackCountInstanceId(nItemTemplateId)
    if not nInstanceId then
        return
    end
    local Component = GamePlayerSelfHelper:Get().HumanWeaponComponent
    if(Component) then
        local tbCurrentWeapon = Component:GetCurrentWeapon()
        if(tbCurrentWeapon and tbCurrentWeapon:GetInstanceId() == nInstanceId) then
            assert(tbCurrentWeapon:IsType(HumanWeaponType.THROW))
            BattleHumanWeaponSystemNew:RequestUnholdThrownWeapon()
        else
            if BattleHumanWeaponSystemNew:RequestHoldThrownWeapon(nInstanceId) == WeaponRequestFailReasonDef.IsAttacking then
                UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("CANNOT_CHANGE_WEAPON_WHILE_ATTACKING"))
            end
        end
    end
end

local function InitThrownItemShortcut(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.chkThrow:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.chkThrow:SetCheckedState(ECheckBoxState.Unchecked)
    local pbThrowItemShortcut
    pbThrowItemShortcut = self.PrefabHelper:BindPrefab(pWidgetRef["pbFFAHumanItemSub01"],  UIDef.UP_HUMAN_SHORTCUT_IN_MAIN)
    pbThrowItemShortcut:SetDataProvider(DataProvider)
    pbThrowItemShortcut:SetShortcutOperate(ShortcutOperator)
    pbThrowItemShortcut:SetSelectGridOperate(SelectGridOperator)
    pbThrowItemShortcut:SetSelectStateChecker(SelectStateChecker)
    --设置首选快捷按钮的位置，1为左下角格子，2为右下角格子
    pbThrowItemShortcut:SetMainGridPosition(1)
    self.pbThrowItemShortcut = pbThrowItemShortcut
end

local function OnCurrentWeaponChanged(self, nNewWeaponId, nLastWeaponId, nPlayerInstanceId)
    if GamePlayerSelfHelper:Get():GetServerInstanceId() ~= nPlayerInstanceId then
        return
    end
    local tbNewItem = BattleItemSystemClient:GetItem(nNewWeaponId)
    if tbNewItem then
        local nCategory = tbNewItem:GetCategory()
        local _, nCurCategory = DataProvider()
        if nCategory ~= nCurCategory then
            self.pbThrowItemShortcut:SelectMainGrid(false)
        else
            local nItemTemplateId = tbNewItem:GetTemplateId()
            BattleHumanWeaponSystemNew:SaveThrownWeaponInfo(nItemTemplateId)
            EventManager:OnFireEvent(ClientEventDef.EV_FFA_HUMAN_SHORT_CUT_ITEM_SELECTED, nItemTemplateId)
            self.pbThrowItemShortcut:SelectMainGrid(true)
        end
    else
        self.pbThrowItemShortcut:SelectMainGrid(false)
    end
end

function ULFFAHumanThrownItem:SetShortcutVisibility(bVisible)
    if bVisible then
        self.pbThrowItemShortcut.pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.pbThrowItemShortcut.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    end
end


----------life cycle----------
function ULFFAHumanThrownItem:Deactivate()
    HideThrowCountDownUI(self)
    local EventHelper = self.EventHelper
    EventHelper:UnregisterEvent(ClientEventDef.EV_HUMAN_WEAPON_THROW_READY)
    EventHelper:UnregisterEvent(ClientEventDef.EV_HUMAN_WEAPON_THROWED)
    EventHelper:UnregisterEvent(ClientEventDef.EV_HUMAN_WEAPON_THROW_CANCEL)
end

function ULFFAHumanThrownItem:Activate()
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_WEAPON_THROW_READY, self, OnThrowReady)
    EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_WEAPON_THROWED, self, OnThrowed)
    EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_WEAPON_THROW_CANCEL, self, OnThrowCancel)
end

function ULFFAHumanThrownItem:OnLoad()
    InitThrownItemShortcut(self)

    self.pbProgressBarBoom = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbProgressBarBoom)
    self.pbProgressBarBoom:SetFinishCallback(function()
        HideThrowCountDownUI(self)
    end)
end

function ULFFAHumanThrownItem:OnShow()
    self.pbThrowItemShortcut:Show()
end

function ULFFAHumanThrownItem:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED, self, OnCurrentWeaponChanged)
    EventHelper:RegisterCppDelegate(pWidgetRef.chkThrow.OnCheckStateChanged, self, OnThrowStateChanged)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnBoomcancel.OnClicked, self, OnTryCancelExplosive)
end

return ULFFAHumanThrownItem