-----------------------------------------------------
--File Name    : UIFFABackpack.lua
--Author       : Chen Jing
--Create Time  : 2018-08-16
--Description  : 背包界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIFFABackpack = luaclass("UIFFABackpack", WndBase)

local UIDef = require("UIDef")
local UIResourceDef = require("UIResourceDef")
local BattleItemSystemClient = require("BattleItemSystemClient")
local CommonEventDef = require("CommonEventDef")
local PackageDragCategoryDef = require("PackageDragCategoryDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ClientEventDef = require("ClientEventDef")
local UIDragDropUtils = require("UIDragDropUtils")
local SelfTabBarHelper = require("SelfTabBarHelper")
local BattleItemRoomDef = require("BattleItemRoomDef")
local HumanMovementStateType = require("HumanMovementStateType")
local SoundManager = require("SoundManager")

UIFFABackpack.tbShipPackages = nil
UIFFABackpack.tbULHumanPackage = nil
UIFFABackpack.tbULMaterialPackage = nil
UIFFABackpack.pbItemDetail = nil
UIFFABackpack.pbDiscardPart = nil
UIFFABackpack.nCurrentIndex = nil

local HUMAN_INDEX = 1
local SHIP_INDEX = 2
local MATERIAL_INDEX = 3

local THROW_ITEM_SOUND_EFFECT_ID = 10032 --丢弃物品音效

local tbRoomTabTextColor = {
    ["check"] = UIResourceDef.COLOR.YELLOW.SLATE_COLOR,
    ["uncheck"] = UIResourceDef.COLOR.WHITE.SLATE_COLOR,
}


local function SetChEquipChecked(self)
    local pWidgetRef = self.pWidgetRef
    -- if pWidgetRef.chClothRoom:IsVisible() then
    --     pWidgetRef.chClothRoom:SetCheckedState(ECheckBoxState.Unchecked)
    --     pWidgetRef.chClothRoom:SetVisibility(ESlateVisibility.Visible)
    --     pWidgetRef.txtClothRoom:SetColorAndOpacity(tbRoomTabTextColor["uncheck"])
    -- end
    pWidgetRef.chEquipRoom:SetVisibility(ESlateVisibility.HitTestInvisible)
    pWidgetRef.txtEquipRoom:SetColorAndOpacity(tbRoomTabTextColor["check"])
end

-- local function SetChClothChecked(self)
--     local pWidgetRef = self.pWidgetRef
--     pWidgetRef.chEquipRoom:SetCheckedState(ECheckBoxState.Unchecked)
--     pWidgetRef.chEquipRoom:SetVisibility(ESlateVisibility.Visible)
--     pWidgetRef.chClothRoom:SetVisibility(ESlateVisibility.HitTestInvisible)
--     pWidgetRef.txtEquipRoom:SetColorAndOpacity(tbRoomTabTextColor["uncheck"])
--     pWidgetRef.txtClothRoom:SetColorAndOpacity(tbRoomTabTextColor["check"])
-- end

local function OnEquipRoomCheckStateChanged(self, bChecked)
    if bChecked then
        SetChEquipChecked(self)
        if self.nCurrentIndex == HUMAN_INDEX then
            self.tbULHumanPackage:OnRoomSwitched(false)
        elseif self.nCurrentIndex == SHIP_INDEX then
            self.tbShipPackages:OnRoomSwitched(false)
        end
    end
end

-- local function OnClothRoomCheckStateChanged(self, bChecked)
--     if bChecked then
--         SetChClothChecked(self)
--         if self.nCurrentIndex == HUMAN_INDEX then
--             self.tbULHumanPackage:OnRoomSwitched(true)
--         elseif self.nCurrentIndex == SHIP_INDEX then
--             self.tbShipPackages:OnRoomSwitched(true)
--         end
--     end
-- end

local function OnHumanCheckStateChanged(self)
    self.nCurrentIndex = HUMAN_INDEX
    --local pWidgetRef = self.pWidgetRef
    --pWidgetRef.widsContent:SetActiveWidgetIndex(HUMAN_INDEX - 1)
    
    self.tbShipPackages:SetEnable(false)
    self.tbULMaterialPackage:SetEnable(false)
    self.tbULHumanPackage:SetEnable(true)
end

local function OnShipCheckStateChanged(self)
    self.nCurrentIndex = SHIP_INDEX
    --local pWidgetRef = self.pWidgetRef
    --pWidgetRef.widsContent:SetActiveWidgetIndex(SHIP_INDEX - 1)
    self.tbULHumanPackage:SetEnable(false)
    self.tbULMaterialPackage:SetEnable(false)
    self.tbShipPackages:SetEnable(true)
end

local function OnMaterialCheckStateChanged(self)
    self.nCurrentIndex = MATERIAL_INDEX
    --local pWidgetRef = self.pWidgetRef
    --pWidgetRef.widsContent:SetActiveWidgetIndex(MATERIAL_INDEX - 1)
    self.tbULHumanPackage:SetEnable(false)
    self.tbShipPackages:SetEnable(false)
    self.tbULMaterialPackage:SetEnable(true)
end

local function OnTabBarSelectedChanged(self, nIndex)
    if nIndex == HUMAN_INDEX then
        OnHumanCheckStateChanged(self)
    elseif nIndex == SHIP_INDEX then
        OnShipCheckStateChanged(self)
    elseif nIndex == MATERIAL_INDEX then
        OnMaterialCheckStateChanged(self)
    end
    self.pbItemDetail:HideDetail()
    self.pbDiscardPart:HideView()
end

function UIFFABackpack:OnLoad()
    --log("[DEBUG_UI] UIFFABackpack:OnLoad")
    local UILogicHelper = self.UILogicHelper

    self.TabBarHelper = SelfTabBarHelper()
    self.TabBarHelper:Init(self, self.pWidgetRef.hboxTopButton)
    self.TabBarHelper.OnSelectedChangedDelegate:Bind(OnTabBarSelectedChanged, self)

    self.tbShipPackages = UILogicHelper:CreateUILogic("ULShipPackage")
    self.tbULHumanPackage = UILogicHelper:CreateUILogic("ULHumanPackage")
    self.tbULMaterialPackage = UILogicHelper:CreateUILogic("ULMaterialPackage")

    self.PrefabHelper:BindPrefab(self.pWidgetRef.pbCutoutScreenAdapter)
    self.pbItemDetail =  self.PrefabHelper:BindPrefab(self.pWidgetRef.pbItemTips02, UIDef.UP_ITEM_DETAIL_IN_PACKAGE)
    self.pbDiscardPart =  self.PrefabHelper:BindPrefab(self.pWidgetRef.pbItemTips01, UIDef.UP_PACKAGE_DISCARD_PART)
end

function UIFFABackpack:OnCreate()
end

function UIFFABackpack:OnDestroy()
    self.TabBarHelper:Uninit()
end

local function OnEnterShipPackage(self)
    self.TabBarHelper:SelectByIndex(SHIP_INDEX)
    OnShipCheckStateChanged(self)
end

local function OnEnterHumanPackage(self)
    self.TabBarHelper:SelectByIndex(HUMAN_INDEX)
    OnHumanCheckStateChanged(self)
end

local function OnEnterMaterialPackage(self)
    self.TabBarHelper:SelectByIndex(MATERIAL_INDEX)
    OnMaterialCheckStateChanged(self)
end

--因为现在三个分页的listhelper绑定了一个list控件，需要处理绑定事件和解绑事件的顺序问题，
--所以把OnEnter里的逻辑暂时先放到OnShow里。有时间把背包的逻辑整理一下再改回来
-- function UIFFABackpack:OnEnter()
--     log("[DEBUG_UI] UIFFABackpack:OnEnter")
--     local tbPlayerSelf = GamePlayerSelfHelper:Get()
--     local tbOpenArgs = self.tbOpenArgs

--     if tbOpenArgs and tbOpenArgs.nOpenBattleItemRoom then
--         local nOpenBattleItemRoom = tbOpenArgs.nOpenBattleItemRoom
--         if nOpenBattleItemRoom == BattleItemRoomDef.HUMAN_INVENTORY then
--             OnEnterHumanPackage(self)
--         elseif nOpenBattleItemRoom == BattleItemRoomDef.CABIN then
--             OnEnterShipPackage(self)
--         elseif nOpenBattleItemRoom == BattleItemRoomDef.MATERIAL_ROOM then
--             OnEnterMaterialPackage(self)
--         end
--     else
--         if tbPlayerSelf:IsShip() then
--             OnEnterShipPackage(self)
--         else -- 不是船的情况下，默认都打开人的背包
--             OnEnterHumanPackage(self)
--         end
--     end
--     SetChEquipChecked(self)
-- end

function UIFFABackpack:OnShow()
    log("[DEBUG_UI] UIFFABackpack:OnShow")
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    local tbOpenArgs = self.tbOpenArgs

    if tbOpenArgs and tbOpenArgs.nOpenBattleItemRoom then
        local nOpenBattleItemRoom = tbOpenArgs.nOpenBattleItemRoom
        if nOpenBattleItemRoom == BattleItemRoomDef.HUMAN_INVENTORY then
            OnEnterHumanPackage(self)
        elseif nOpenBattleItemRoom == BattleItemRoomDef.CABIN then
            OnEnterShipPackage(self)
        elseif nOpenBattleItemRoom == BattleItemRoomDef.MATERIAL_ROOM then
            OnEnterMaterialPackage(self)
        end
    else
        if tbPlayerSelf:IsShip() then
            OnEnterShipPackage(self)
        else -- 不是船的情况下，默认都打开人的背包
            OnEnterHumanPackage(self)
        end
    end
    SetChEquipChecked(self)

    self.bHide = false
    self:PlayAnimation("animComeIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UIFFABackpack:OnHide()
    self.bHide = true
    -- self:PlayAnimation("animComeIn", 0, 1, EUMGSequencePlayMode.Reverse, 1, function()
    --     if self.bHide then
    --         self:HideFinished()
    --     end
    -- end)
    -- return false
end


local function OnClickedClose(self)
    self:CloseSelf()
end



local function OnAcceptDropAttachment(self, nDragSourceCategory, nDragSourceId)
    if nDragSourceCategory == PackageDragCategoryDef.SHIP_WEAPON_ATTACHMENT or
    PackageDragCategoryDef.HUMAN_WEAPON_ATTACHMENT then
        local tbAttachmentItem = BattleItemSystemClient:GetItem(nDragSourceId)
        if tbAttachmentItem then
            BattleItemSystemClient:RequestUnEquipItem(tbAttachmentItem.nInstanceId)
        end
    end
end

local function OnAcceptDrop(self, nDragSourceCategory, nDragSourceId)
    local nItemInstanceId = nDragSourceId
    if nDragSourceCategory == PackageDragCategoryDef.HUMAN_WEAPON
        or nDragSourceCategory == PackageDragCategoryDef.HUMAN_WEAPON_ATTACHMENT
        or nDragSourceCategory == PackageDragCategoryDef.HUMAN_PACKAGE_ITEM
        or nDragSourceCategory == PackageDragCategoryDef.HUMAN_ARMOR
        or nDragSourceCategory == PackageDragCategoryDef.HUMAN_BAG_SLOT then
        nItemInstanceId = nDragSourceId
    end

    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    local HumanMovementStateComponent = tbPlayerSelf.HumanMovementStateComponent
    if HumanMovementStateComponent then  
        local nState = HumanMovementStateComponent:GetCurrentState()
        if nState == HumanMovementStateType.Jumping_SpeelWall then  
            return 
        end 
    end 

    if nItemInstanceId > 0 then
        local tbItem = BattleItemSystemClient:GetItem(nItemInstanceId)
        if tbItem then
            BattleItemSystemClient:RequestThrowAwayItem(nItemInstanceId, tbItem.nStackCount)
            self.EventHelper:FireEvent(ClientEventDef.EV_REQUEST_THROW_AWAY_ITEM)
        end
    end
    local ContentColor = LinearColor{R = 1,G= 0, B = 0,A = 0}
    self.pWidgetRef.bdrDiscard:SetBrushColor( ContentColor )
end

local function OnDropEnter(self, nDragSourceCategory, nDragSourceId)
    local ContentColor = LinearColor{R = 1,G= 0, B = 0,A = 0.2}
    self.pWidgetRef.bdrDiscard:SetBrushColor( ContentColor )
end

local function OnDropLeave(self, nDragSourceCategory, nDragSourceId)
    local ContentColor = LinearColor{R = 1,G= 0, B = 0,A = 0}
    self.pWidgetRef.bdrDiscard:SetBrushColor( ContentColor )
end

local function OnItemAdd(self)
    if self.nCurrentIndex == HUMAN_INDEX then
        self.tbULHumanPackage:OnItemAdd()
    elseif self.nCurrentIndex == SHIP_INDEX then
        self.tbShipPackages:OnItemAdd()
    elseif self.nCurrentIndex == MATERIAL_INDEX then
        self.tbULMaterialPackage:OnItemAdd()
    end
end

local function OnItemRemove(self)
    if self.nCurrentIndex == HUMAN_INDEX then
        self.tbULHumanPackage:OnItemRemove()
    elseif self.nCurrentIndex == SHIP_INDEX then
        self.tbShipPackages:OnItemRemove()
    elseif self.nCurrentIndex == MATERIAL_INDEX then
        self.tbULMaterialPackage:OnItemRemove()
    end
    self.pbItemDetail:HideDetail()
end

local function OnItemPosChanged(self)
    if self.nCurrentIndex == HUMAN_INDEX then
        self.tbULHumanPackage:OnItemPosChanged()
    elseif self.nCurrentIndex == SHIP_INDEX then
        self.tbShipPackages:OnItemPosChanged()
    elseif self.nCurrentIndex == MATERIAL_INDEX then
        self.tbULMaterialPackage:OnItemPosChanged()
    end
end

local function OnItemStackCountChanged(self, Item)
    local nItemInstanceId = Item:GetInstanceId()
    local nStackCount = Item:GetStackCount()
    if self.nCurrentIndex == HUMAN_INDEX then
        self.tbULHumanPackage:OnItemStackCountChanged(nItemInstanceId, nStackCount)
    elseif self.nCurrentIndex == SHIP_INDEX then
        self.tbShipPackages:OnItemStackCountChanged(nItemInstanceId, nStackCount)
    elseif self.nCurrentIndex == MATERIAL_INDEX then
        self.tbULMaterialPackage:OnItemStackCountChanged(nItemInstanceId, nStackCount)
    end
end

local function OnDragStart(self, nDragSourceCategory, nDragSourceId)
    self.pbItemDetail:HideDetail()
    self.pWidgetRef.dropDetectorFull:SetVisibility(ESlateVisibility.Visible)
    if nDragSourceCategory == PackageDragCategoryDef.SHIP_WEAPON_ATTACHMENT or
    nDragSourceCategory == PackageDragCategoryDef.HUMAN_WEAPON_ATTACHMENT then
        self.pWidgetRef.pbDropAttachment:SetVisibility(ESlateVisibility.Visible)
    end
end

local function OnDragEnd(self, nDragSourceCategory, nDragSourceId)
    self.pWidgetRef.dropDetectorFull:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.pbDropAttachment:SetVisibility(ESlateVisibility.Collapsed)
end

local function OnWidgetTouchEnded(self, pGeometry, pMouseEvent)
    self.EventHelper:FireEvent(ClientEventDef.EV_USER_WIDGET_TOUCH_END, UIDef.UI_FFABACKPACK, pGeometry, pMouseEvent)
end

local function OnPlayerDie(self, Deader)
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    if Deader == tbPlayerSelf then
        self:CloseSelf()
    end
end

local function OnThrowAwayItems(self)
    SoundManager:PlaySoundEffect(THROW_ITEM_SOUND_EFFECT_ID)
end

function UIFFABackpack:OnBindEvent(EventHelper)
    --log("[DEBUG_UI] UIFFABackpack:OnBindEvent")
    local pWidgetRef = self.pWidgetRef
    --EventHelper:RegisterCppDelegate(pWidgetRef.chClothRoom.OnCheckStateChanged, self, OnClothRoomCheckStateChanged)
    EventHelper:RegisterCppDelegate(pWidgetRef.chEquipRoom.OnCheckStateChanged, self, OnEquipRoomCheckStateChanged)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnClose.OnClicked, self, OnClickedClose)
    EventHelper:RegisterCppDelegate(pWidgetRef.OnTouchEndedEvent, self, OnWidgetTouchEnded)

    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT, self, OnItemAdd)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_REMOVE_CLIENT, self, OnItemRemove)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STORAGE_LOCATION_CLIENT, self, OnItemPosChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_EXCHANGE_STORAGE_LOCATION_CLIENT, self, OnItemPosChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT, self, OnItemStackCountChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnPlayerDie)
    EventHelper:RegisterCppDelegate(pWidgetRef.dropDetector.OnAcceptDrop, self, OnAcceptDrop)
    EventHelper:RegisterCppDelegate(pWidgetRef.dropDetectorFull.OnAcceptDrop, self, OnAcceptDrop)
    EventHelper:RegisterCppDelegate(pWidgetRef.dropDetector.OnDropEnter, self, OnDropEnter)
    EventHelper:RegisterCppDelegate(pWidgetRef.dropDetector.OnDropLeave, self, OnDropLeave)
    EventHelper:RegisterCppDelegate(pWidgetRef.pbDropAttachment.OnAcceptDrop, self, OnAcceptDropAttachment)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_DRAG_START, self, OnDragStart)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_DRAG_END, self, OnDragEnd)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_GUIDE_BEGIN_STEP, self, OnClickedClose)
    EventHelper:RegisterEvent(ClientEventDef.EV_REQUEST_THROW_AWAY_ITEM, self, OnThrowAwayItems)    
    UIDragDropUtils.EnableDragStartAndEndEvent(EventHelper, pWidgetRef.dropDetector)
    UIDragDropUtils.EnableDragStartAndEndEvent(EventHelper, pWidgetRef.dropDetectorFull)
    UIDragDropUtils.EnableDragStartAndEndEvent(EventHelper, pWidgetRef.pbDropAttachment)
end

return UIFFABackpack
