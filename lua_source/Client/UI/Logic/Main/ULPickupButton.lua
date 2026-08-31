-----------------------------------------------------
--File Name    : ULPickupButton.lua
--Description  : ffa拾取按钮的触发逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULPickupButton = luaclass("ULPickupButton", UILogicBase)

local UIManager = require("UIManager")
local UIDef = require("UIDef")
local ClientEventDef = require("ClientEventDef")
local ControlModeDef = require("ControlModeDef")
local BattlePickupSystem = require("BattlePickupSystem")
local BattlePickTypeDef = require("BattlePickTypeDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")
local CommonEventDef = require("CommonEventDef")
local BattlePickPosDef = require("BattlePickPosDef")


local PICK_BOX_LOCAL_ID = 12
local PICK_ITEM_LOCAL_ID = 13
local CUSTOM_PICK_POS = BattlePickPosDef.CustomPos
--local DEFAULT_PICK_POS = BattlePickPosDef.DefaultPos

ULPickupButton.bOpenFightBack = false
ULPickupButton.bOpenAim = false
ULPickupButton.nRequestPickupType = nil
ULPickupButton.bIsDead = false
ULPickupButton.tbOpenWndName = nil

------------------------pick up----------------------------------


--刷新拾取按钮显示位置
local function RefreshBtnPos(self, pBtnWidget, tbBtnPosCoordinate)
    local nX = tbBtnPosCoordinate.nX
    local nY = tbBtnPosCoordinate.nY
    local szOpenWndName = BattlePickPosDef.GetFirstPriorityWnd(self.tbOpenWndName)
    if szOpenWndName then
        local tbPos = CUSTOM_PICK_POS[szOpenWndName]
        if tbPos then
            nX = nX + tbPos.ULPickupButton.X_SHIFT_OFFSET
        end
    end
    pBtnWidget.Slot:SetPosition(Vector2D{X = nX, Y = nY})
end

--关闭拾取箱子
local function ClosePickupBox(self)
    UIManager:CloseWnd(UIDef.UI_PICKUP_BOX)
end

--关闭拾取物品
local function ClosePickupItem(self)
    UIManager:CloseWnd(UIDef.UI_PICKUP_ITEM)
end

local function RefreshSceneItem(self)
    local t1 = getseconds() * 1000
    local tbRequestBoxIds = BattlePickupSystem:GetAllBoxRequestIds()
    local t2 = getseconds() * 1000
    local tbRequestItemIds = BattlePickupSystem:GetRequestIdsByPickType(BattlePickTypeDef.ITEM)
    local t3 = getseconds() * 1000
    local tbParam = {}
    tbParam.bOpenAim = self.bOpenAim
    if self.bOpenFightBack then
        tbParam.nOpenPos = 2
    else
        tbParam.nOpenPos = 1
    end
    --logdebug("RefreshSceneItem",debug.traceback())
    tbParam.tbOpenWndName = self.tbOpenWndName
    local t4 = getseconds() * 1000
    if (self.nRequestPickupType == BattlePickTypeDef.BOX or self.nRequestPickupType == BattlePickTypeDef.TREASURE_CHEST) and #tbRequestBoxIds > 0 then
        if not self.bOpenAim and not UIManager:IsWndOpen(UIDef.UI_PICKUP_BOX) then
            UIManager:OpenWnd(UIDef.UI_PICKUP_BOX, tbParam)
        end
    elseif self.nRequestPickupType == BattlePickTypeDef.ITEM and #tbRequestItemIds > 0 then
        if not self.bOpenAim and not UIManager:IsWndOpen(UIDef.UI_PICKUP_ITEM) then
            UIManager:OpenWnd(UIDef.UI_PICKUP_ITEM, tbParam)
        end
    end
    local t5 = getseconds() * 1000
    log("ULPickupButton RefreshSceneItem",t1, t2-t1, t3-t2, t4-t3, t5-t4, t5-t1)
end

--按钮事件
local function OnPickBoxClicked(self, bUseDelay)
    local bIsAlive = GamePlayerSelfHelper:Get():IsAlive()
    log("OnPickBoxClicked,self.nRequestPickupType, bUseDelay=",self.nRequestPickupType,bUseDelay,bIsAlive)
    if not bIsAlive then
        return
    end
    self.EventHelper:FireEvent(ClientEventDef.EV_ON_CLICK_PICKUP_BOX)
    if self.nRequestPickupType == BattlePickTypeDef.ITEM then
        ClosePickupItem(self)
    end
    local tbRequestId = BattlePickupSystem:GetRequestIdsByPickType(BattlePickTypeDef.BOX)
    if #tbRequestId > 0 then
        self.nRequestPickupType = BattlePickTypeDef.BOX
    else
        self.nRequestPickupType = BattlePickTypeDef.TREASURE_CHEST
    end
    BattlePickupSystem:RequestViewBegin(self.nRequestPickupType, not bUseDelay)
    RefreshSceneItem(self)
end

local function OnPickItemClicked(self, bUseDelay)
    local bIsAlive = GamePlayerSelfHelper:Get():IsAlive()
    log("OnPickItemClicked,self.nRequestPickupType, bUseDelay=",self.nRequestPickupType,bUseDelay,bIsAlive)
    if not bIsAlive then
        return
    end
    if self.nRequestPickupType == BattlePickTypeDef.BOX or self.nRequestPickupType == BattlePickTypeDef.TREASURE_CHEST then
        ClosePickupBox(self)
    end
    self.nRequestPickupType = BattlePickTypeDef.ITEM
    BattlePickupSystem:RequestViewBegin(self.nRequestPickupType, not bUseDelay)
    RefreshSceneItem(self)
end

--进入trigger
local function OnEnterPickupTrigger(self, nPickType, nInstanceId)
    local bPickupItemOpen = BattlePickupSystem:IsItemAutoOpen()
    local bPickupBoxOpen = BattlePickupSystem:IsBoxAutoOpen()
    log("OnEnterPickupTrigger,nPickType, nInstanceId,self.nRequestPickupType,bPickupItemOpen,self.bOpenAim=",nPickType, nInstanceId,self.nRequestPickupType,bPickupItemOpen, self.bOpenAim)
    if self.bIsDead then
        return
    end
    local pWidgetRef = self.pWidgetRef
    if nPickType == BattlePickTypeDef.ITEM then
        RefreshBtnPos(self, pWidgetRef.btnPickItem, self.tbItemLayoutData)
        if self.nRequestPickupType ~= nil then
            if not GamePlayerSelfHelper:Get():IsDying() then
                BattlePickupSystem:RequestViewBegin(self.nRequestPickupType)
            end
            if (self.nRequestPickupType == BattlePickTypeDef.BOX or self.nRequestPickupType == BattlePickTypeDef.TREASURE_CHEST) and not self.bOpenAim then
                pWidgetRef.btnPickItem:SetVisibility(ESlateVisibility.Visible)
            end
        elseif bPickupItemOpen then
            if not self.bOpenAim then
                log("OnEnterPickupTrigger,btnPickItem visible")
                pWidgetRef.btnPickItem:SetVisibility(ESlateVisibility.Visible)
            end
            OnPickItemClicked(self, true)
        else
            if not self.bOpenAim then
                log("OnEnterPickupTrigger,btnPickItem visible")
                pWidgetRef.btnPickItem:SetVisibility(ESlateVisibility.Visible)
            end
        end
    elseif nPickType == BattlePickTypeDef.BOX then
        RefreshBtnPos(self, pWidgetRef.btnPickBox, self.tbBoxLayoutData)
        if self.nRequestPickupType == BattlePickTypeDef.BOX or self.nRequestPickupType == BattlePickTypeDef.TREASURE_CHEST then
            if not GamePlayerSelfHelper:Get():IsDying() then
                BattlePickupSystem:RequestViewBegin(self.nRequestPickupType)
            end
        elseif not self.bOpenAim then
            log("OnEnterPickupTrigger,btnPickBox visible")
            pWidgetRef.btnPickBox:SetVisibility(ESlateVisibility.Visible)
        end
    elseif nPickType == BattlePickTypeDef.TREASURE_CHEST then
        if self.nRequestPickupType == BattlePickTypeDef.BOX or self.nRequestPickupType == BattlePickTypeDef.TREASURE_CHEST then
            if not GamePlayerSelfHelper:Get():IsDying() then
                BattlePickupSystem:RequestViewBegin(self.nRequestPickupType)
            end
        else
            if not self.bOpenAim then
                log("OnEnterPickupTrigger,btnPickBox visible")
                pWidgetRef.btnPickBox:SetVisibility(ESlateVisibility.Visible)
            end
            local tbRequestId = BattlePickupSystem:GetRequestIdsByPickType(BattlePickTypeDef.BOX)
            if self.nRequestPickupType == nil and #tbRequestId == 0 and bPickupBoxOpen then
                OnPickBoxClicked(self, true)
            end
        end
    end
end

--走出trigger
local function OnLeavePickupTrigger(self, nPickType, nInstanceId)
    local pWidgetRef = self.pWidgetRef
    if nPickType == BattlePickTypeDef.ITEM then
        local tbRequestItemIds = BattlePickupSystem:GetRequestIdsByPickType(BattlePickTypeDef.ITEM)
        if #tbRequestItemIds == 0 then
            pWidgetRef.btnPickItem:SetVisibility(ESlateVisibility.Collapsed)
        end
    elseif nPickType == BattlePickTypeDef.BOX or nPickType == BattlePickTypeDef.TREASURE_CHEST then
        local tbRequestBoxIds = BattlePickupSystem:GetAllBoxRequestIds()
        if #tbRequestBoxIds == 0 then
            pWidgetRef.btnPickBox:SetVisibility(ESlateVisibility.Collapsed)
            self.EventHelper:FireEvent(ClientEventDef.EV_ON_LEAVE_PICKUP_BOX)
        end
    end
end

local function OnCloseUI(self, szWndName)
    local pWidgetRef = self.pWidgetRef
    --logdebug("OnCloseUI",szWndName,debug.traceback())
    if szWndName == UIDef.UI_PICKUP_BOX then
        self.nRequestPickupType = nil
        RefreshBtnPos(self, pWidgetRef.btnPickBox, self.tbBoxLayoutData)
        local tbRequestBoxIds = BattlePickupSystem:GetAllBoxRequestIds()
        if #tbRequestBoxIds == 0 then
            pWidgetRef.btnPickBox:SetVisibility(ESlateVisibility.Collapsed)
        else
            pWidgetRef.btnPickBox:SetVisibility(ESlateVisibility.Visible)
        end
        BattlePickupSystem:RequestViewEnd()
    elseif szWndName == UIDef.UI_PICKUP_ITEM then
        self.nRequestPickupType = nil
        RefreshBtnPos(self, pWidgetRef.btnPickItem, self.tbItemLayoutData)
        local tbRequestItemIds = BattlePickupSystem:GetRequestIdsByPickType(BattlePickTypeDef.ITEM)
        if #tbRequestItemIds == 0 then
            pWidgetRef.btnPickItem:SetVisibility(ESlateVisibility.Collapsed)
        else
            pWidgetRef.btnPickItem:SetVisibility(ESlateVisibility.Visible)
        end
        BattlePickupSystem:RequestViewEnd()
    elseif CUSTOM_PICK_POS[szWndName] then
        self.tbOpenWndName[szWndName] = nil
        if not next(self.tbOpenWndName) then
            RefreshBtnPos(self, pWidgetRef.btnPickBox, self.tbBoxLayoutData)
            RefreshBtnPos(self, pWidgetRef.btnPickItem, self.tbItemLayoutData)
        end
    end
end
----
local function CollasedAllPickupButton(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnPickBox:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.btnPickItem:SetVisibility(ESlateVisibility.Collapsed)
end

local function OnFFAAimStateChanged(self, bOpenAim)
    self.bOpenAim = bOpenAim
    local pWidgetRef = self.pWidgetRef
    if bOpenAim then
        CollasedAllPickupButton(self)
    else
        local tbRequestBoxIds = BattlePickupSystem:GetAllBoxRequestIds()
        local tbRequestItemIds = BattlePickupSystem:GetRequestIdsByPickType(BattlePickTypeDef.ITEM)
        if #tbRequestBoxIds > 0 then
            if self.nRequestPickupType ~= BattlePickTypeDef.BOX or self.nRequestPickupType ~= BattlePickTypeDef.TREASURE_CHEST then
                pWidgetRef.btnPickBox:SetVisibility(ESlateVisibility.Visible)
                RefreshBtnPos(self, pWidgetRef.btnPickBox, self.tbBoxLayoutData)
            end
        end
        if #tbRequestItemIds > 0 then
            if self.nRequestPickupType ~= BattlePickTypeDef.ITEM then
                pWidgetRef.btnPickItem:SetVisibility(ESlateVisibility.Visible)
                RefreshBtnPos(self, pWidgetRef.btnPickItem, self.tbItemLayoutData)
            end
        end
        RefreshSceneItem(self)
    end
end

local function LoadPickupSetting(self, nFrom)
    local SettingLayout = SettingSystemNew:GetInstance(SettingClassType.Setting_Layout)
    local nBoxRemoteId = SettingLayout:ConvertToCurrentStyleRemoteId(nFrom, PICK_BOX_LOCAL_ID)
    local nItemRemoteId = SettingLayout:ConvertToCurrentStyleRemoteId(nFrom, PICK_ITEM_LOCAL_ID)
    self.tbBoxLayoutData = SettingLayout:GetLayout(nFrom, nBoxRemoteId)
    self.tbItemLayoutData = SettingLayout:GetLayout(nFrom, nItemRemoteId)
    local pBoxWidget = self.pWidgetRef.btnPickBox
    local pItemWidget = self.pWidgetRef.btnPickItem
    RefreshBtnPos(self, pBoxWidget, self.tbBoxLayoutData)
    pBoxWidget:SetRenderTransformPivot(pBoxWidget.Slot:GetAlignment())
    pBoxWidget:SetRenderOpacity(self.tbBoxLayoutData.nAlpha)
    pBoxWidget:SetRenderScale(Vector2D{X = self.tbBoxLayoutData.nScale, Y = self.tbBoxLayoutData.nScale})
    RefreshBtnPos(self, pItemWidget, self.tbItemLayoutData)
    pItemWidget:SetRenderTransformPivot(pItemWidget.Slot:GetAlignment())
    pItemWidget:SetRenderOpacity(self.tbItemLayoutData.nAlpha)
    pItemWidget:SetRenderScale(Vector2D{X = self.tbItemLayoutData.nScale, Y = self.tbItemLayoutData.nScale})
end

local function OnGameObjectPreDead(self, tbCharacter)
    local tbPlayer = GamePlayerSelfHelper:Get()
    if tbPlayer == tbCharacter then
        self.bIsDead = true
        CollasedAllPickupButton(self)
    end
end
--------------------------------------------------------------------------
--[[
    public function
]]
function ULPickupButton:OnShow()
    self.tbOpenWndName = {}
    CollasedAllPickupButton(self)
    LoadPickupSetting(self, self.Owner.nLayoutFrom)
    self.bIsDead = false
end

function ULPickupButton:OnBindEvent(EventHelper)
    --logdebug("ULPickupButton:OnBindEvent")
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnPickBox.OnClicked, self, OnPickBoxClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnPickItem.OnClicked, self, OnPickItemClicked)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_SYNC_SCENE_ITEM, self, RefreshSceneItem)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_PICKUP_ENTER, self, OnEnterPickupTrigger)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_PICKUP_LEAVE, self, OnLeavePickupTrigger)
    EventHelper:RegisterEvent(ClientEventDef.EV_PRE_CLOSE_UI, self, OnCloseUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_AIM_STATE_CHANGED, self, OnFFAAimStateChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_PRE_DEAD, self, OnGameObjectPreDead)
end

function ULPickupButton:Activate()

end

function ULPickupButton:Deactivate(nControlMode)
    if nControlMode ~= ControlModeDef.TRANSPORTNEW then
        BattlePickupSystem:ResetRequestIds()
        ClosePickupBox(self)
        ClosePickupItem(self)
        self.pWidgetRef.btnPickBox:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.btnPickItem:SetVisibility(ESlateVisibility.Collapsed)
    end
    self.bOpenAim = false
end

function ULPickupButton:Reset()
    BattlePickupSystem:SetItemAutoOpen(true)
    BattlePickupSystem:SetBoxAutoOpen(true)
end

--打开/关闭 背包和拾取界面的操作
function ULPickupButton:OnOpenUI(szWndName)
    local pWidgetRef = self.pWidgetRef
    if szWndName == UIDef.UI_PICKUP_ITEM then
        BattlePickupSystem:SetItemAutoOpen(true)
        pWidgetRef.btnPickItem:SetVisibility(ESlateVisibility_Collapsed)
    elseif szWndName == UIDef.UI_PICKUP_BOX then
        BattlePickupSystem:SetBoxAutoOpen(true)
        pWidgetRef.btnPickBox:SetVisibility(ESlateVisibility_Collapsed)
    elseif CUSTOM_PICK_POS[szWndName] then
        self.tbOpenWndName[szWndName] = true
        RefreshBtnPos(self, pWidgetRef.btnPickBox, self.tbBoxLayoutData)
        RefreshBtnPos(self, pWidgetRef.btnPickItem, self.tbItemLayoutData)
    end
end

function ULPickupButton:RefreshLayout()
    LoadPickupSetting(self, self.Owner.nLayoutFrom)
end

return ULPickupButton