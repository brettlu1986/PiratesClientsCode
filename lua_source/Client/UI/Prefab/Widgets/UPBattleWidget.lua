-----------------------------------------------------
--File Name    : ShipHeadInfoComponent.lua
--Author       : Song Fuhao
--Create Time  : 2017-03-02
--Description  : 船只头顶信息UI
-----------------------------------------------------

local luaclass = require("luaclass")
local UPWidgetBase = require("UPWidgetBase")
local UPBattleWidget = luaclass("UPBattleWidget", UPWidgetBase)

-- require
local UISetUtils = require("UISetUtils")
local CampSystem = require("CampSystem")
local GameNpcType = require("GameNpcType")
local ShipDataTable = require("ShipDataTable")
local UIResourceDef = require("UIResourceDef")
local ClientEventDef = require("ClientEventDef")
local CommonEventDef = require("CommonEventDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local WidgetAnimationHandle = require("WidgetAnimationHandle")
-- local BattleBuffDataTable = require("BattleBuffDataTable")
-- local HandlerManagerHelper = require("HandlerManagerHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
-- local ShipAIUtility = require("ShipAIUtility")
local L10N = require("L10N")

local UI_STATE_CENTER   = 1 -- 瞄准状态下，脱离屏幕
local UI_STATE_FULL     = 2 -- 完整模式
local UI_STATE_SIMPLE   = 3 -- 简单模式
local UI_STATE_MINIMAL  = 4 -- 迷你模式

local WIDGET_SWITCH_COMMON  = 0
local WIDGET_SWITCH_AIM     = 1

local TICK_TIME                 = 0.2
local MAX_BUFF_ICON_COUNT       = 6
local MINIMAL_STATE_RATIO       = 1
local MIN_AIM_STATE_POSITION_X  = 0
local MIN_AIM_STATE_POSITION_Y  = 20

local pNoGuildSelectSize = KismetMathLibrary.MakeVector2D(24, 50)
local pAimAlignment = KismetMathLibrary.MakeVector2D(0.5, 2)
local pViewportSize = WidgetLayoutLibrary.GetViewportSize(GWorld)
local pAimStatePosition = KismetMathLibrary.Divide_Vector2DFloat(pViewportSize, 2)

-- local variables
UPBattleWidget.bTargetingSelf = false
UPBattleWidget.bMinimalState = true
UPBattleWidget.bTeammate = false
UPBattleWidget.TickTimer = nil
UPBattleWidget.bInAimMode = false
UPBattleWidget.bBoss = false
UPBattleWidget.bHadGuildName = false

local function IsPlayerAutoFight(self)
    local tbPlayer = GamePlayerSelfHelper:Get()
    if tbPlayer.BattleAIComponent then
        return tbPlayer.BattleAIComponent.bEnable
    end
    return false
end

local function SetUIState( self, nStateIndex )
    local pWidgetRef = self.pWidgetRef
    local pOwnerWidgetRef = self.Owner.pWidgetRef
    if self.bTeammate or GlobalVariableSystem.bBattleFullHeadInfo then
        nStateIndex = UI_STATE_FULL
    end
    if nStateIndex == UI_STATE_CENTER then -- 瞄准状态下，脱离屏幕
        if self.nStateIndex ~= UI_STATE_CENTER then
            pOwnerWidgetRef:AddToViewport(0)
            pOwnerWidgetRef:SetAlignmentInViewport(pAimAlignment)
            pOwnerWidgetRef:SetPositionInViewport(pAimStatePosition, true)
            pWidgetRef.wsHeadInfo:SetActiveWidgetIndex(WIDGET_SWITCH_AIM)
            self.OwnerGameObject.pUEActor.HubHeadInfo:SetHiddenInGame(true, false)
        end
    else
        if self.nStateIndex == UI_STATE_CENTER then
            pOwnerWidgetRef:RemoveFromViewport()
            pWidgetRef.wsHeadInfo:SetActiveWidgetIndex(WIDGET_SWITCH_COMMON)
            self.OwnerGameObject.pUEActor.HubHeadInfo:SetHiddenInGame(false, false)
        end
        if nStateIndex == UI_STATE_FULL then -- 完整模式
            if self.bHadGuildName then
                pWidgetRef.txtGuildName:SetVisibility(ESlateVisibility.HitTestInvisible)
            end
            pWidgetRef:PlayAnimation(pWidgetRef.animStateFull, 0, 1, EUMGSequencePlayMode.Forward, 1)
        else
            if self.bHadGuildName then
                pWidgetRef.txtGuildName:SetVisibility(ESlateVisibility.Collapsed)
            end
            if nStateIndex == UI_STATE_MINIMAL or self.bBoss then
                pWidgetRef:PlayAnimation(pWidgetRef.animStateMinimal, 0, 1, EUMGSequencePlayMode.Forward, 1)
            elseif nStateIndex == UI_STATE_SIMPLE then
                pWidgetRef:PlayAnimation(pWidgetRef.animStateSimple, 0, 1, EUMGSequencePlayMode.Forward, 1)
            end
        end
    end
    self.nStateIndex = nStateIndex
end

local function SetGuildName(self)
    if self.pWidgetRef.txtGuildName == nil then
        logerror("wait battle head widget")
        return
    end
    local Collapsed, Visible = ESlateVisibility.Collapsed, ESlateVisibility.Visible
    local szGuildName = self.OwnerGameObject.GuildComponent and self.OwnerGameObject.GuildComponent:GetGuildName()
    if szGuildName == nil or szGuildName == "" then
        self.pWidgetRef.txtGuildName:SetVisibility(Collapsed)
        self.pWidgetRef.imgSelectedLeft.Slot:SetSize(pNoGuildSelectSize)
        self.pWidgetRef.imgSelectedRight.Slot:SetSize(pNoGuildSelectSize)
    else
        self.bHadGuildName = true
        self.pWidgetRef.txtGuildName:SetVisibility(Visible)
        self.pWidgetRef.txtGuildName:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("GUILD_NAME"), szGuildName))
    end
end

local function UpdateUIStateWhenTargetingSelf( self )
    local bPositionInScreen = true
    if not self.bBoss then
        local pWorldLocation = self.pWidgetComponent:K2_GetComponentLocation()
        local pPlayerController = GameplayStatics.GetPlayerController(GWorld, 0)
        local _, pScreenPosition = GameplayStatics.ProjectWorldToScreen(pPlayerController, pWorldLocation, false)
        local nX = pScreenPosition.X
        local nY = pScreenPosition.Y
        if (nX < MIN_AIM_STATE_POSITION_X) or (nY < MIN_AIM_STATE_POSITION_Y)  then
            bPositionInScreen = false
        elseif (nX > pViewportSize.X) or (nY > pViewportSize.Y) then
            bPositionInScreen = false
        end
    end

    SetUIState(self, ((not bPositionInScreen) and self.bInAimMode) and UI_STATE_CENTER or UI_STATE_FULL)
    self.bPositionInScreen = bPositionInScreen
end

local function CheckAndUpdateUIState( self )
    local pSelectedVisibility = ESlateVisibility.HitTestInvisible
    if self.bTargetingSelf and (not IsPlayerAutoFight(self)) then
        UpdateUIStateWhenTargetingSelf(self)
    else
        SetUIState(self, self.bMinimalState and UI_STATE_MINIMAL or UI_STATE_SIMPLE)
        pSelectedVisibility = ESlateVisibility.Hidden
    end
    
    self.pWidgetRef.imgSelectedLeft:SetVisibility(pSelectedVisibility)
    self.pWidgetRef.imgSelectedRight:SetVisibility(pSelectedVisibility)
end

local function UpdateFlagColor( self, pSlateColor )
    self.pWidgetRef.kpgbHP:SetTopImageTint(pSlateColor)
    UISetUtils.SetImageBrushTint(self.pWidgetRef.imgType, pSlateColor)
end

local function OnAIAlertedWhenPatrolling( self )
    UpdateFlagColor(self, UIResourceDef.COLOR.PINK.SLATE_COLOR)
end

local function OnAIAlertedWhenPatrollingEnds( self )
    UpdateFlagColor(self, UIResourceDef.COLOR.YELLOW.SLATE_COLOR)
end

local function OnAutoFightStateChanged(self)
    CheckAndUpdateUIState(self)
end

local function UpdateTickTimerState( self )
    if self.bTargetingSelf and self.bInAimMode and (not self.bBoss) then
        if self.TickTimer == nil then
            self.TickTimer = self.TimerHelper:NewTimerMethod(self, CheckAndUpdateUIState, TICK_TIME, true)
        end
    else
        self.TimerHelper:ClearTimer(self.TickTimer)
        self.TickTimer = nil
    end
end

-- local function OnHandlerModeSwitch( self, pMode )
--     self.bInAimMode = (pMode == Enum_HandlerMode.ShipAimMode)
--     UpdateTickTimerState(self)
--     CheckAndUpdateUIState(self)
-- end

local function UpdateFlagAndHPBar( self )
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if not PlayerSelf.bReady then
        return
    end
    local Owner = self.OwnerGameObject
    local EventHelper = self.EventHelper
    local DelegateComponent = Owner.DelegateComponent
    EventHelper:UnregisterLuaDelegate(DelegateComponent.OnAIAlertedWhenPatrolling, OnAIAlertedWhenPatrolling, self)
    EventHelper:UnregisterLuaDelegate(DelegateComponent.OnAIAlertedWhenPatrollingEnds, OnAIAlertedWhenPatrollingEnds, self)
    self.bTeammate = CampSystem:IsFriendRelation(Owner, PlayerSelf)
    if self.bTeammate then  -- 队友
        UpdateFlagColor(self, UIResourceDef.COLOR.BLUE1.SLATE_COLOR)
    elseif Owner.ObjectType == GameObjectTypeDef.PlayerOther then -- 玩家敌人
        UpdateFlagColor(self, UIResourceDef.COLOR.PINK.SLATE_COLOR)
    elseif Owner.ObjectType == GameObjectTypeDef.Npc then -- NPC敌人
        EventHelper:RegisterLuaDelegate(DelegateComponent.OnAIAlertedWhenPatrolling, OnAIAlertedWhenPatrolling, self)
        EventHelper:RegisterLuaDelegate(DelegateComponent.OnAIAlertedWhenPatrollingEnds, OnAIAlertedWhenPatrollingEnds, self)
        
        -- local bAIAlerted = ShipAIUtility.GetIsAIAlerted(Owner)
        -- UpdateFlagColor(self, bAIAlerted and UIResourceDef.COLOR.PINK.SLATE_COLOR or UIResourceDef.COLOR.YELLOW.SLATE_COLOR)
    end
    CheckAndUpdateUIState(self)
end

local function OnBattleCampTypeChanged( self, tbObject )
    if tbObject ~= self.OwnerGameObject then
        return
    end
    UpdateFlagAndHPBar(self)
end

local function OnBattleTeamIdChanged( self, args )
    UpdateFlagAndHPBar(self)
end

local function OnFullHeadInfoStateChanged( self, bEnable )
    if bEnable then
        SetUIState(self, UI_STATE_FULL)
    else
        CheckAndUpdateUIState(self)
    end
end

local function OnBattleCommandAnimationFinished( self )
    self.pWidgetRef.imgBattleCommand:SetVisibility(ESlateVisibility.Collapsed)
end

local function OnShowBattleCommandOnTargetHead( self, nType, tbTarget )
    if tbTarget ~= self.OwnerGameObject then
        return
    end
    self.pWidgetRef.imgBattleCommand:SetVisibility(ESlateVisibility.HitTestInvisible)
    local pWidgetRef = self.pWidgetRef
    UISetUtils.SetImageBrushRes(pWidgetRef.imgBattleCommand, UIResourceDef.BATTLE_COMMAND_HEAD_RES[nType]:load())
    local pAnimRef = pWidgetRef["animBattleCommand"]
    pWidgetRef:PlayAnimation(pAnimRef , 0, 6, EUMGSequencePlayMode.Forward , 1)
end

local function OnPlayerTargetChanged( self, pTargetShip )
    local bTargetingSelf = self.OwnerGameObject:GetUEActorUniqueId() == EngineExtActorShell.GetActorUniqueId(pTargetShip)
    if self.bTargetingSelf ~= bTargetingSelf then
        self.bTargetingSelf = bTargetingSelf
        CheckAndUpdateUIState(self)
        UpdateTickTimerState(self)
    end
end

-- local function OnHpChanged( self, nHp, nMaxHp, bWithAnim )
--     if bWithAnim == nil then
--         bWithAnim = true
--     end

--     if nMaxHp > 0 then
--         local nPercent = nHp / nMaxHp
--         local nRealPercent = math.ceil(nPercent * 100)
--         self.pWidgetRef.kpgbHP:SetPercent(nPercent, bWithAnim)
--         self.pWidgetRef.txtHP:SetText(string.format("%0.f(%d%%)", nHp, nRealPercent))
--         self.pWidgetRef.txtAimHP:SetText(string.format("%d%%", nRealPercent))
--     end
-- end

local function RefreshHpUI( self, bWithAnim )
    -- local OwnerGameObject = self.OwnerGameObject
    -- local nHp = OwnerGameObject.BattleStatusComponent:GetHp()
    -- local nMaxHp = OwnerGameObject.BattleStatusComponent:GetMaxHp()
    -- OnHpChanged(self, nHp, nMaxHp, bWithAnim)
end

local function OnMininmalStateChanged( self, bNewState )
    self.bMinimalState = bNewState
    CheckAndUpdateUIState(self)
end

local function OnBeCalledNameStateChanged( self, bVisible )
    self.pWidgetRef.ovlEyes:SetVisibility(bVisible and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
end

local function OnPawnDead( self, tbDeadObject )
    local bOwnerDead = tbDeadObject == self.OwnerGameObject
    if bOwnerDead or (tbDeadObject == GamePlayerSelfHelper:Get()) then
        OnPlayerTargetChanged(self, nil)
    end
    if bOwnerDead then
        self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function OnPawnReborn( self, tbObject )
    if tbObject == self.OwnerGameObject then
        self.pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.TimerHelper:RunNextTick(function()
            RefreshHpUI(self, false)
        end)
    elseif tbObject == GamePlayerSelfHelper:Get() then
        OnPlayerTargetChanged(self, GamePlayerSelfHelper:GetUEActor().ShipAimSystemComponent:GetTargetShip())
    end
end

-- 初始化依赖PlayerSelf的部分
local function InitByPlayerSelfReady( self )
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf:IsShip() then 
        self.pWidgetRef:Init(PlayerSelf.pUEActor.ShipAimSystemComponent.MaxRange * MINIMAL_STATE_RATIO)
    end 
    UpdateFlagAndHPBar(self)
    OnMininmalStateChanged(self, self.pWidgetRef.MinimalState)
end

-- 初始化基础信息
local function InitBaseInfo( self )
    local Owner = self.OwnerGameObject
    local pWidgetRef = self.pWidgetRef
    -- 船只图标
    local pImgType = nil
    local tbShipData = ShipDataTable:GetTemplate(Owner:GetTemplateId())
    --暂时修改成这个 之后要从另外的表格读取 现在还没有填写那个表
    
    if self.bBoss then
        pImgType = UIResourceDef.BOSS_FLAG_BORDER:load()
    else
        pImgType = UIResourceDef.SHIP_FLAG_BORDER[tbShipData.nCategory]:load()
    end
    UISetUtils.SetImageBrushRes(pWidgetRef.imgType, pImgType, false)

    -- 玩家姓名
    pWidgetRef.txtName:SetText(Owner.szName)
    pWidgetRef.txtAimName:SetText(Owner.szName)

    SetUIState(self, UI_STATE_MINIMAL)
    SetGuildName(self)
    
    -- 初始化血量信息
    RefreshHpUI(self, false)

    -- OnHandlerModeSwitch(self, HandlerManagerHelper:GetCurrentMode())

    for i=1,MAX_BUFF_ICON_COUNT do
        self.tbFreeBuffIconList[i] = self.pWidgetRef["imgBuff0"..i]
    end
end

UPBattleWidget.tbUsedBuffInfoList = {}
UPBattleWidget.tbFreeBuffIconList = {}

-- local function OnBuffAdd(self, nBuffId, nTime, nOverlapCount, nLevel)
--     local pBuffIcon = self.tbFreeBuffIconList[1]
--     if pBuffIcon then
--         table.remove(self.tbFreeBuffIconList, 1)
--     else
--         local tbBuffInfo = self.tbUsedBuffInfoList[1]
--         if tbBuffInfo then
--             pBuffIcon = tbBuffInfo.pWidget
--             table.remove(self.tbUsedBuffInfoList, 1)
--         end
--     end
--     if pBuffIcon == nil then
--         return
--     end
--     self.pWidgetRef.hboxBuffList:RemoveChild(pBuffIcon)
--     self.pWidgetRef.hboxBuffList:AddChild(pBuffIcon)
--     local tbResTemplate = BattleBuffDataTable:GetResTemplate(nBuffId)
--     if tbResTemplate and tbResTemplate.szIconRes then
--         UISetUtils.SetImageBrushRes(pBuffIcon, tbResTemplate.szIconRes:load())
--         local tbBuffInfo = {}
--         tbBuffInfo.nBuffId = nBuffId
--         tbBuffInfo.pWidget = pBuffIcon
--         table.insert(self.tbUsedBuffInfoList, tbBuffInfo)
--         pBuffIcon:SetVisibility(ESlateVisibility.HitTestInvisible)
--     end
-- end

-- local function OnBuffRemove(self, nBuffId)
--     for i,v in ipairs(self.tbUsedBuffInfoList) do
--         if v.nBuffId == nBuffId then
--             v.pWidget:SetVisibility(ESlateVisibility.Collapsed)
--             table.insert(self.tbFreeBuffIconList, v.pWidget)
--             table.remove(self.tbUsedBuffInfoList, i)
--             break
--         end
--     end
-- end

function UPBattleWidget:OnWidgetCreated()
    local Owner = self.OwnerGameObject
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if Owner == PlayerSelf then -- 隐藏自己的头顶信息
        self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
        return
    end

    local bNpc = Owner.ObjectType == GameObjectTypeDef.Npc
    if bNpc then
        if Owner.ObjectType ==  GameNpcType.BattleCollection
        and Owner.ObjectType ==  GameNpcType.BattleHumanNpc then
            self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
            return
        end

        local bIsShowUIEnergy = Owner.tbNpcTemplateData.bIsShowUIEnergy
        if not bIsShowUIEnergy then
            self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
            return
        end
    end
    
    self.pWidgetRef:SetVisibility(ESlateVisibility.HitTestInvisible)
    self.bBoss = bNpc and (Owner.tbNpcTemplateData.bIsBoos)

    self.pWidgetRef.Ship = Owner.pUEActor

    InitBaseInfo(self)

    local EventHelper = self.EventHelper
    local DelegateComponent = Owner.DelegateComponent
    -- local BattleStatusComponent = Owner.BattleStatusComponent
    EventHelper:RegisterCppDelegate(self.pWidgetRef.OnMininmalStateChanged, self, OnMininmalStateChanged)
    EventHelper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(self.pWidgetRef, self.pWidgetRef.animBattleCommand, OnBattleCommandAnimationFinished, self))
    EventHelper:RegisterLuaDelegate(DelegateComponent.OnBeCalledNameBegin, function() OnBeCalledNameStateChanged(self, true) end)
    EventHelper:RegisterLuaDelegate(DelegateComponent.OnBeCalledNameEnd, function() OnBeCalledNameStateChanged(self, false) end)
    -- EventHelper:RegisterLuaDelegate(BattleStatusComponent.OnHpChanged, OnHpChanged, self)
    -- EventHelper:RegisterLuaDelegate(HandlerManagerHelper.OnModeSwitchDelegate, OnHandlerModeSwitch, self)

    -- local BuffComponentClient = Owner.BuffComponentClient
    -- EventHelper:RegisterLuaDelegate(BuffComponentClient.OnBuffAddDelegate, OnBuffAdd, self)
    -- EventHelper:RegisterLuaDelegate(BuffComponentClient.OnBuffRemoveDelegate, OnBuffRemove, self)

    EventHelper:RegisterEvent(ClientEventDef.EV_AUTO_BATTLE, self, OnAutoFightStateChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_SELF_TARGET_CHANGED, self, OnPlayerTargetChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_FULL_HEAD_INFO_STATE_CHANGED, self, OnFullHeadInfoStateChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_SHOW_BATTLE_COMMAND_ON_TARGET_HEAD, self, OnShowBattleCommandOnTargetHead)
    EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_TEAM_ID_CHANGED, self, OnBattleTeamIdChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_CAMP_TYPE_CHANGED, self, OnBattleCampTypeChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnPawnDead)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_REBORN, self, OnPawnReborn)

    if PlayerSelf.bReady then
        InitByPlayerSelfReady(self)
    else
        self.EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_READY, self, InitByPlayerSelfReady)
    end
end

function UPBattleWidget:OnActorDestroyed()
    local pOwnerWidgetRef = self.Owner.pWidgetRef
    if pOwnerWidgetRef:IsInViewport() then
        pOwnerWidgetRef:RemoveFromViewport()
    end
    UPBattleWidget.super.OnActorDestroyed(self)
end

return UPBattleWidget
