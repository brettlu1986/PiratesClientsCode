-----------------------------------------------------
--File Name    : UPFFAMainChat.lua
--Author       : Edward J
--Create Time  : 2018-03-12
--Description  : UPFFAMainChat
-----------------------------------------------------
local luaclass      = require("luaclass")
local UPFFABase     = require("UPFFABase")
local UPFFAMainChat = luaclass("UPFFAMainChat", UPFFABase)

local L10N                      = require("L10N")
local SelfVerticalListHelper    = require("SelfVerticalListHelper")
local BattleChatSystem          = dynamic_require("BattleChatSystem")
local QuickChatDataTable        = require("QuickChatDataTable")
local CommonEventDef            = require("CommonEventDef")
local UIDef                     = require("UIDef")
local UIUtils                   = require("UIUtils")
local UITextDef                 = require("UITextDef")
local GameObjectSystem          = dynamic_require("GameObjectSystem")
local GameObjectTypeDef         = require("GameObjectTypeDef")
local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")
local GameTriggerType           = require("GameTriggerType")
local BattleItemDataTable       = require("BattleItemDataTable")
local ChatSystemHelper          = require("ChatSystemHelper")
local SettingSystemNew          = require("SettingSystemNew")
local SettingClassType          = require("SettingClassType")
local ClientEventDef            = require("ClientEventDef")
local GenderTypeDefine          = require("GenderTypeDefine")
local PointTipsHelper           = require("PointTipsHelper")
local ControlModeDef            = require("ControlModeDef")
local GameplayUtilityHelper     = require("GameplayUtilityHelper")
-- local EventManager              = require("EventManager")
-- local UISetUtils                = require("UISetUtils")
-----------------------------------------------------
local tbTabType                 = UIDef.CHAT_TAB_TYPE
local TEAM_SEND_INTERVAL        = 3
local TRACE_CHECK_INTERVAL      = 1
local MAX_BTN_COUNT             = 4
local ANIMATION_NAME            = "animSayTips"
local Visible                   = ESlateVisibility.Visible
local Collapsed                 = ESlateVisibility.Collapsed
local SelfHitTestInvisible      = ESlateVisibility.SelfHitTestInvisible
local DeprojectScreenToWorld    = GameplayStatics.DeprojectScreenToWorld
local CHANGEABLE_MSG_CATEGORY   = 100
local CHANGEABLE_MSG_INDEX      = 1
local CHANGEABLE_MSG_BASE       = nil
local TB_CHANGEABLE_MSG_DEFAULT = nil
local DEFAULT_COLOR             = "#FFFFFF"
local POINT_LOCATE_ID           = 1
-- local POINT_DROP_ITEM_ID        = 2
local EndPos                    = Vector()

UPFFAMainChat.bVisible            = false
UPFFAMainChat.tbBtns              = nil
UPFFAMainChat.tbViewArgs          = nil
UPFFAMainChat.tbInputWidgetList   = nil
UPFFAMainChat.tbSelectImg         = nil
UPFFAMainChat.ECurrentViewType    = tbTabType.ETabQuickMsg
UPFFAMainChat.CommonListHelper    = nil
UPFFAMainChat.FriendListHelper    = nil
UPFFAMainChat.WatchListHelper     = nil
UPFFAMainChat.tbQuickChatList     = nil
UPFFAMainChat.nSelectedHistory    = 1
UPFFAMainChat.pEditBox            = nil
UPFFAMainChat.nFriendId           = nil
UPFFAMainChat.tbTimerHandler      = nil
UPFFAMainChat.pImgSaySelect       = nil
UPFFAMainChat.bCanSendToTeam      = true
UPFFAMainChat.pLastShowView       = nil
UPFFAMainChat.bRegisterEvent      = false
UPFFAMainChat.tbTraceTimerHandler = nil
UPFFAMainChat.nLastTriggerId      = nil
UPFFAMainChat.tbPointConfig       = nil
UPFFAMainChat.pPointDropItemPos   = nil
UPFFAMainChat.tbPlayerSelf        = nil
-----------------------------------------------------

local function InitQuickChatMsg(self)
    CHANGEABLE_MSG_BASE = ""
    TB_CHANGEABLE_MSG_DEFAULT = {}
    self.tbQuickChatList = {}
    local nAllCount = QuickChatDataTable:GetAllCount()
    local tbchatList = self.tbQuickChatList
    local SettingChat = SettingSystemNew:GetInstance(SettingClassType.Setting_Chat)
    SettingSystemNew:SetUseDefaultSaveId(true)
    SettingChat:LoadDefaultValue()
    local tbChatMsg = SettingChat:GetValues()
    local nGender = GamePlayerSelfHelper:GetGenderInBattle()
    
    SettingSystemNew:SetUseDefaultSaveId(false)
    for i = 1, nAllCount do
        local tbTemplate = QuickChatDataTable:GetTemplate(i)
        if tbTemplate then
            if tbTemplate.nCategory < 0 or tbTemplate.nCategory == 100 then
                local tbMsgInfo ={}
                local szMsg = L10N:ToString(tbTemplate.l10nMsg)
                local nSoundId = nGender == GenderTypeDefine.MALE and tbTemplate.nMaleSoundId or tbTemplate.nFemaleSoundId
                if CHANGEABLE_MSG_CATEGORY == tbTemplate.nCategory then
                    szMsg = string.gsub(szMsg,"'","\"")
                    CHANGEABLE_MSG_BASE = szMsg
                    szMsg = string.format(szMsg, DEFAULT_COLOR, L10N:ToString(UITextDef.UI_STATIC_CHANGEABLE_DEF))
                    TB_CHANGEABLE_MSG_DEFAULT.szMsg = szMsg
                    TB_CHANGEABLE_MSG_DEFAULT.nId = i
                    CHANGEABLE_MSG_INDEX = i
                    TB_CHANGEABLE_MSG_DEFAULT.nSoundId = nSoundId
                end
                tbMsgInfo.nId = i
                tbMsgInfo.szMsg = szMsg
                tbMsgInfo.nSoundId = nSoundId
                tbchatList[i] = tbMsgInfo
            end
        end
    end
    for i, nId in ipairs(tbChatMsg) do
        local tbTemplate = QuickChatDataTable:GetTemplate(nId)
        if tbTemplate then
            local tbMsgInfo ={}
            local nSoundId = nGender == GenderTypeDefine.MALE and tbTemplate.nMaleSoundId or tbTemplate.nFemaleSoundId
            local szMsg = L10N:ToString(tbTemplate.l10nMsg)
            tbMsgInfo.nId = nId
            tbMsgInfo.szMsg = szMsg
            tbMsgInfo.nSoundId = nSoundId
            table.insert(tbchatList, tbMsgInfo)
        end
    end
end

local function OnUISettingClose(self, szWndName)
    if szWndName == UIDef.UI_SETTING then
        InitQuickChatMsg(self)
    end
end

-- local function ReversTab(tbValue)
--     local tbTemp = {}
--     local ntbCount = #tbValue
--     for i = 1, ntbCount do
--         tbTemp[i] = tbValue[ntbCount-i+1]
--     end
--     return tbTemp
-- end

local function GetTeamChatHistory()
    local tbHistory = BattleChatSystem:GetTeamHistory()
    return tbHistory
end

local function GetOneFriendHistory(nFriendId)
    local tbFriend = BattleChatSystem:GetOneFriendHistory(nFriendId)
    return tbFriend.tbMsg
end

local function GetData(self, eTabType)
    if eTabType == tbTabType.ETabQuickMsg then
        return self.tbQuickChatList
    elseif eTabType == tbTabType.ETabHistory then
        return GetTeamChatHistory()
    elseif eTabType == tbTabType.ETabFriends then
        return BattleChatSystem:GetFriendHistory()
    elseif eTabType == tbTabType.ETabFriendsMsg then
        return GetOneFriendHistory(self.nFriendId)
    elseif eTabType == tbTabType.ETabWatch then
        return nil
    else
        return self.tbQuickChatList
    end
end

local function SetSelectImg(self, eTabType)
    if eTabType > tbTabType.ETabWatch then
        return
    end
    local tbImg = self.tbSelectImg
    for i = 1, MAX_BTN_COUNT do
        tbImg[i]:SetVisibility(eTabType == i and Visible or Collapsed)
    end
end

local function OnSelectHistory(self, nIndex)
    self.nSelectedHistory = nIndex
end

local function SetNewFriendMsgTipVisible(self, bVisible)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.ovlFriednMsgTip:SetVisibility(bVisible and Visible or Collapsed)
end

local function PlaySayImgAnimation(self)
    if self.pImgSaySelect == nil then
        return
    end
    self.pImgSaySelect:SetVisibility(SelfHitTestInvisible)
    self.Owner:PlayAnimation(ANIMATION_NAME, 0, 0, EUMGSequencePlayMode.Forward, 1)
    SetNewFriendMsgTipVisible(self, true)
end

local function StopSayImgAnimation(self)
    if self.pImgSaySelect == nil then
        return
    end
    self.pImgSaySelect:SetVisibility(Collapsed)
    self.Owner:StopAnimation(ANIMATION_NAME)
end

local function ClearSendIntervalTimer(self)
    local tbTimerHandler = self.tbTimerHandler
    if tbTimerHandler then
        self.TimerHelper:ClearTimer(tbTimerHandler)
        self.tbTimerHandler = nil
    end
end

local function TeamMsgSendInterval(self)
    self.bCanSendToTeam = true
    ClearSendIntervalTimer(self)
end

local function StartSendIntervalTimer(self)
    ClearSendIntervalTimer(self)
    self.bCanSendToTeam = false
    self.tbTimerHandler = self.TimerHelper:NewTimerMethod(self, TeamMsgSendInterval, TEAM_SEND_INTERVAL, true)
end

local function OnSelectFriend(self, nFriendId)
    self.nFriendId = nFriendId
    self:OnSelectTabButton(tbTabType.ETabFriendsMsg)
end

local function OnRecieveFriendMsg(self, nFriendId, szMsg)
    if not self.bVisible then
        PlaySayImgAnimation(self)
        return
    end
    if self.ECurrentViewType == tbTabType.ETabFriends then
        self:Refresh(tbTabType.ETabFriends)
    elseif self.ECurrentViewType == tbTabType.ETabFriendsMsg and self.nFriendId == nFriendId then
        self:RefreshCurrentFriendView()
        BattleChatSystem:ReadFriendHistory(nFriendId)
        if szMsg == "INVITE" then
            SetNewFriendMsgTipVisible(self, true)
        end
    end
end

local function OnRecieveTeamMsg(self, szMsg)
    -- if self.ECurrentViewType == tbTabType.ETabHistory then
        -- self:RefreshItem(tbTabType.ETabHistory, szMsg)
    -- end
end

local function SendToTeam(self, szMsg, nSoundId, nId)
    if not self.bCanSendToTeam then
        UIUtils.ShowToast(UITextDef.CHAT_TEAM_INTERVAL_LIMITE)
        return false
    end
    if nId == POINT_LOCATE_ID then
        local ulPointTips = self.Owner.uiBattlePointTip
        if not ulPointTips then
            return false
        end
        if not ulPointTips:PointLocation() then
            return false
        end
        -- EventManager:OnFireEvent(ClientEventDef.EV_POINT_LOCATE)
    end
    local bResult = BattleChatSystem:SendMsgToTeam(szMsg, nSoundId)
    if bResult then
        StartSendIntervalTimer(self)
        BattleChatSystem:AddSelfHistory(szMsg)
        self:Deactivate()
    end
    -- if nId == POINT_DROP_ITEM_ID then
        -- local pPos = self.pPointDropItemPos
        -- if not pPos then
        --     EventManager:OnFireEvent(ClientEventDef.EV_POINT_LOCATE)
        --     UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("POINT_TO_A_ITEM"))
        -- else
        --     EventManager:OnFireEvent(ClientEventDef.EV_POINT_DROP_ITEM_LOCATE, PointTipsHelper.PointTips, pPos)
        -- end
        
    -- end
    return bResult
end

local function SendToFriend(self, szMsg, nFriendId)
    local bResult = BattleChatSystem:SendMsgToFriend(szMsg, nFriendId)
    if bResult then
        self:Deactivate()
    end
    return bResult
end

local function OnSendBtnClicked(self)
    local pEditBox = self.pEditBox
    local szMsg = L10N:ToString(pEditBox:GetText())
    szMsg = string.gsub(szMsg, " ", "")
    szMsg = ChatSystemHelper.CheckSpecialCharacter(szMsg)
    szMsg = ChatSystemHelper.CheckMsgSensitiveWords(szMsg)
    local bSendResult
    if self.ECurrentViewType == tbTabType.ETabFriendsMsg then
        bSendResult = SendToFriend(self, szMsg, self.nFriendId)
    else
        bSendResult = SendToTeam(self, szMsg)
    end
    if not bSendResult then
        return
    end
    pEditBox:SetText("")
end

local function OnFriendBackClicked(self)
    self:Refresh(tbTabType.ETabFriends)
end

local function OnDisturbStateChanged(self, bState)
    BattleChatSystem:SetFirendDisturb(bState)
end

local function ChangeQuickMsg(self, szDropItemName)
    local szMsg = TB_CHANGEABLE_MSG_DEFAULT.szMsg
    if szDropItemName then
        szMsg = string.format(CHANGEABLE_MSG_BASE, L10N:ToString(UITextDef.UI_STATIC_CHANGEABLE_COLOR), szDropItemName)
    end
    local tbTemp = {}
    tbTemp.nId = TB_CHANGEABLE_MSG_DEFAULT.nId
    tbTemp.szMsg = szMsg
    tbTemp.nSoundId = TB_CHANGEABLE_MSG_DEFAULT.nSoundId
    self:RefreshItemByIndex(tbTabType.ETabQuickMsg, tbTemp, CHANGEABLE_MSG_INDEX)
end

local function DistanceFilter(self, tbAllTriggers)
    local temp = {}
    local PlayerSelf = self.tbPlayerSelf
    if not PlayerSelf then
        return
    end
    local selfLocation = PlayerSelf:GetLocation()
    local tbConfig = self.tbPointConfig
    local nInteractionDistance = tbConfig.distance
    for trigger,v in pairs(tbAllTriggers) do
        local actorLocation = trigger:GetLocation()
        local nDistance = PointTipsHelper.GetDistance(selfLocation, actorLocation)
        if nDistance <= nInteractionDistance then
            table.insert(temp, trigger)
        end
    end
    return temp
end

local function TraceActorNew(self)
    local PlayerSelf = self.tbPlayerSelf
    if not PlayerSelf then
        return
    end
    local pUEController = PlayerSelf.pUEController
    local tbAllTriggers = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.Trigger)
    tbAllTriggers = DistanceFilter(self, tbAllTriggers)
    local bSetDefault = true
    local tbConfig = self.tbPointConfig
    -- logdebug("Triggers Count = " .. #tbAllTriggers)
    for i,tbGameObject in ipairs(tbAllTriggers) do
        if  tbGameObject.nType == GameTriggerType.SceneItem then
            local bShip = PlayerSelf:IsShip()
            local pActor = tbGameObject.pUEActor
            local ViewPortVector = PointTipsHelper.GetCrosshairPos(self.Owner, PlayerSelf, bShip)
            if not ViewPortVector then
                return
            end
            local nDistance = tbConfig.lineLen
            local bHit = false
            local pActorLocation = nil 
            pActorLocation = pActor:K2_GetActorLocation()
            local __, pStartPos, pWorldDirection = DeprojectScreenToWorld(pUEController, ViewPortVector)
            local nEndPosX, nEndPosY, nEndPosZ = pStartPos.X + pWorldDirection.X*nDistance, pStartPos.Y + pWorldDirection.Y*nDistance, pStartPos.Z + pWorldDirection.Z*nDistance
            EndPos.X = nEndPosX
            EndPos.Y = nEndPosY
            EndPos.Z = nEndPosZ
            --bHit = ExtendBlueprintFunctions.LineIntersection(pActorLocation, tbConfig.boxExtent, pStartPos, EndPos)
            bHit = GameplayUtilityHelper.TraceActorNew(pUEController, pActor, ViewPortVector, nDistance, tbConfig.boxExtent, GWorld)
            if PointTipsHelper.DEBUG_MODE then
                local ___, ____ = GameplayUtilityHelper.TraceActor(GWorld, pStartPos, EndPos, {PlayerSelf.pUEActor}, PointTipsHelper.DEBUG_MODE, true, true, false, true, false, GWorld)
            end
            if bHit then
                local tbInfo = tbGameObject.tbCustomProtoData.scene_item_info
                local nTemplateId = tbInfo.template_id
                local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
                if tbTemplate ~= nil then
                    bSetDefault = false
                    local nLastId = self.nLastTriggerId
                    local nUniqueId = tbGameObject.nUniqueId
                    if nLastId == nil or nLastId ~= nUniqueId then
                        self.nLastTriggerId = nUniqueId
                        self.pPointDropItemPos = pActorLocation
                        ChangeQuickMsg(self, L10N:ToString(tbTemplate.l10nName))
                    end
                end
                break
            end
        end
    end
    if bSetDefault then
        self.nLastTriggerId = nil
        self.pPointDropItemPos = nil
        ChangeQuickMsg(self, nil)
    end
end

local function ClearTraceTimer(self)
    local tbTimer = self.tbTraceTimerHandler
    if tbTimer ~= nil then
        self.TimerHelper:ClearTimer(tbTimer)
        self.tbTraceTimerHandler = nil
    end
    return true
end

local function ControlModeChange(self, nControlMode)
    local bShip = false
    if nControlMode == ControlModeDef.SHIP then
        bShip = true
    elseif nControlMode == ControlModeDef.HUMAN then
        bShip = false
    end
    self.tbPointConfig = PointTipsHelper.GetConfig(bShip, PointTipsHelper.DropItemConfig)
end

local function StartTraceTimer(self)
    ClearTraceTimer(self)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local bShip = PlayerSelf:IsShip()
    self.tbPointConfig = PointTipsHelper.GetConfig(bShip, PointTipsHelper.DropItemConfig)
    self.tbTraceTimerHandler = self.TimerHelper:NewTimerMethod(self, TraceActorNew, TRACE_CHECK_INTERVAL, true)
    return true
end

local function IsTableContain(tbValue, Content)
    if tbValue == nil then
        return false
    end
    for _, v in ipairs(tbValue) do
        if v == Content then
            return true
        end
    end
    return false
end

local function SetAppearance(self, eTabType, tbListData)
    local tbViewData = self.tbViewArgs[eTabType]
    if tbViewData == nil then
        return
    end
    local ListHelper = tbViewData.ListHelper
    local tbShowWidget = tbViewData.tbShowWidget
    local pListRef = ListHelper.pListRef
    if self.pLastShowView then
        self.pLastShowView:SetVisibility(Collapsed)
    end
    pListRef:SetVisibility(Visible)
    self.pLastShowView = pListRef

    for _, v in pairs(self.tbInputWidgetList) do
        v:SetVisibility(IsTableContain(tbShowWidget, v) and Visible or Collapsed)
    end
    if not tbListData then
        return
    end
    ListHelper:SetData(tbListData)
    if eTabType == tbTabType.ETabHistory then
        -- ListHelper:ScrollToIndex(self.nSelectedHistory, false)
        ListHelper:ScrollToBottom(false)
    elseif eTabType == tbTabType.ETabQuickMsg then
        ListHelper:ScrollToTop(false)
    else
        ListHelper:ScrollToBottom(false)
    end
end

local function AddTabViewArgs(self, eTabType, ListHelper, tbShowWidget)
    local tbTemp = {}
    tbTemp.ListHelper = ListHelper
    tbTemp.tbShowWidget = tbShowWidget
    self.tbViewArgs[eTabType] = tbTemp
end

local function HideLists(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.pMsgList:SetVisibility(Collapsed)
    pWidgetRef.pFriendMsgList:SetVisibility(Collapsed)
    pWidgetRef.pWatchList:SetVisibility(Collapsed)
end

function UPFFAMainChat:GetCurrentViewType()
    return self.ECurrentViewType
end

function UPFFAMainChat:Refresh(eTabType)
    self.ECurrentViewType = eTabType
    if eTabType == tbTabType.ETabFriends then
        SetNewFriendMsgTipVisible(self, false)
    end
    local tbListData = GetData(self, eTabType) or {}
    SetAppearance(self, eTabType, tbListData)
end

function UPFFAMainChat:RefreshItem(eTabType, szMsg)
    local tbViewData = self.tbViewArgs[eTabType]
    if tbViewData == nil then
        return
    end
    local ListHelper = tbViewData.ListHelper
    ListHelper:AddItem(szMsg, 1)
end

function UPFFAMainChat:RefreshCurrentFriendView()
    local tbViewData = self.tbViewArgs[tbTabType.ETabFriendsMsg]
    if tbViewData == nil then
        return
    end
    local ListHelper = tbViewData.ListHelper
    ListHelper:RequestListRefresh()
    ListHelper:ScrollToBottom(false)
end

function UPFFAMainChat:RefreshItemByIndex(eTabType, szMsg, nIndex)
    local tbViewData = self.tbViewArgs[eTabType]
    if tbViewData == nil then
        return
    end
    local ListHelper = tbViewData.ListHelper
    ListHelper:SetItemAt(szMsg, nIndex)
end

function UPFFAMainChat:GetVisible()
    return self.bVisible
end

function UPFFAMainChat:GetCurrentFirendId()
    return self.nFriendId
end

function UPFFAMainChat:GetCurrentFirendName()
    local szName = BattleChatSystem:GetFriendName(self.nFriendId)
    return szName
end

function UPFFAMainChat:OnSelectTabButton(eTabType, bMemoryClick)
    if self.ECurrentViewType == eTabType and not bMemoryClick then
        return
    end
    if self.ECurrentViewType == tbTabType.ETabFriendsMsg and eTabType == tbTabType.ETabFriends then
        return
    end
    local __ = (eTabType == tbTabType.ETabQuickMsg) and StartTraceTimer(self) or ClearTraceTimer(self)
    SetSelectImg(self, eTabType)
    self:Refresh(eTabType)
end

function UPFFAMainChat:Activate()
    self.super.Activate(self)
    if not self.bRegisterEvent then
        self:OnBindCommonEvent()
    end
    self.pWidgetRef:SetVisibility(Visible)
    self.bVisible = true
    self:OnSelectTabButton(self.ECurrentViewType, true)
    StopSayImgAnimation(self)
    if self.ECurrentViewType == tbTabType.ETabQuickMsg then
        ChangeQuickMsg(self, nil) --设一下快捷回复到初始值
    end
    local bDisturb = BattleChatSystem:GetFirendDisturb()
    self.pWidgetRef.kmcDisturb:SetCheckedState(bDisturb and ECheckBoxState.Checked or ECheckBoxState.Unchecked)
end

function UPFFAMainChat:Deactivate()
    self.super.Deactivate(self)
    self:UnbindCommonEvent()
    HideLists(self)
    self.pWidgetRef:SetVisibility(Collapsed)
    self.bVisible = false
    self.pLastShowView = nil
    self.nLastTriggerId = nil
    if BattleChatSystem:FriendHasNewMsg() and not BattleChatSystem:GetFirendDisturb() then
        PlaySayImgAnimation(self)
    end
    ClearTraceTimer(self)
end

function UPFFAMainChat:ToggleActivate()
    if self.bVisible then
        self:Deactivate()
        return
    end
    self:Activate()
end

function UPFFAMainChat:OnLoad()
    self.super.OnLoad(self)
    local pWidgetRef = self.pWidgetRef
    self:Deactivate()
    self.tbBtns = {}
    self.tbLists = {}
    self.tbSelectImg = {}
    self.tbViewArgs = {}
    self.tbInputWidgetList = {}
    self.tbPointConfig = {}
    self.tbPlayerSelf = GamePlayerSelfHelper:Get()
    for i = 1, MAX_BTN_COUNT do
        self.tbBtns[i] = pWidgetRef["btn0" .. i]
        self.tbSelectImg[i] = pWidgetRef["imgSelect0" .. i]
    end
    self.pImgSaySelect = self.Owner.pWidgetRef.imgSaySelect
    self.pEditBox = pWidgetRef.pEditText

    self.tbInputWidgetList = {
        pWidgetRef.pInputBox,
        pWidgetRef.dontDisturb,
        pWidgetRef.btnBack,
        pWidgetRef.txtTeam,
        pWidgetRef.cvsWatchView,
    }

    self.CommonListHelper = SelfVerticalListHelper()
    self.CommonListHelper:Init(self, pWidgetRef.pMsgList)
    self.FriendListHelper = SelfVerticalListHelper()
    self.FriendListHelper:Init(self, pWidgetRef.pFriendMsgList)
    self.WatchListHelper = SelfVerticalListHelper()
    self.WatchListHelper:Init(self, pWidgetRef.pWatchList)
    HideLists(self)

    AddTabViewArgs(self, tbTabType.ETabQuickMsg, self.CommonListHelper, {pWidgetRef.pInputBox, pWidgetRef.txtTeam})
    AddTabViewArgs(self, tbTabType.ETabHistory, self.CommonListHelper, {pWidgetRef.pInputBox, pWidgetRef.txtTeam})
    AddTabViewArgs(self, tbTabType.ETabFriends, self.FriendListHelper, {pWidgetRef.dontDisturb})
    AddTabViewArgs(self, tbTabType.ETabFriendsMsg, self.CommonListHelper, {pWidgetRef.pInputBox, pWidgetRef.btnBack})
    AddTabViewArgs(self, tbTabType.ETabWatch, self.WatchListHelper, {pWidgetRef.cvsWatchView})

    self.tbQuickChatList = {}
    InitQuickChatMsg(self)
    SetNewFriendMsgTipVisible(self, false)
end

function UPFFAMainChat:OnUnload()
    self.super.OnUnload(self)
    self.CommonListHelper:Uninit()
    self.FriendListHelper:Uninit()
    self.WatchListHelper:Uninit()
    local tbTimerHandler = self.tbTimerHandler
    if tbTimerHandler ~= nil then
        self.TimerHelper:ClearTimer(tbTimerHandler)
        self.tbTimerHandler = nil
    end
    self.nLastTriggerId = nil
end

function UPFFAMainChat:OnBindCommonEvent()
    local EventHelper = self.EventHelper
    
    EventHelper:RegisterEvent(CommonEventDef.EV_BATTLECHAT_TEAM_NEW_MSG, self, OnRecieveTeamMsg)
    self.bRegisterEvent = true
end

function UPFFAMainChat:UnbindCommonEvent()
    local EventHelper = self.EventHelper
    EventHelper:UnregisterEvent(CommonEventDef.EV_BATTLECHAT_TEAM_NEW_MSG, self, OnRecieveTeamMsg)
    self.bRegisterEvent = false
end

function UPFFAMainChat:OnBindEvent(EventHelper)
    for i = 1, MAX_BTN_COUNT do
        EventHelper:RegisterCppDelegate(self.tbBtns[i].OnClicked, self, function() self:OnSelectTabButton(i) end)
    end
    self:OnBindCommonEvent()
    EventHelper:RegisterEvent(ClientEventDef.EV_CLICK_QUICK_CHAT, self, SendToTeam)
    EventHelper:RegisterEvent(ClientEventDef.EV_SELECT_HISTORY, self, OnSelectHistory)
    EventHelper:RegisterEvent(ClientEventDef.EV_SELECT_FRIEND_CHAT, self, OnSelectFriend)
    EventHelper:RegisterEvent(ClientEventDef.EV_PRE_CLOSE_UI, self, OnUISettingClose)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLECHAT_FRIEND_NEW_MSG, self, OnRecieveFriendMsg)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_CONTROL_MODE_ACTIVATE, self, ControlModeChange)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSend.OnClicked, self, OnSendBtnClicked)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnBack.OnClicked, self, OnFriendBackClicked)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.kmcDisturb.OnCheckStateChanged, self, OnDisturbStateChanged)
end

return UPFFAMainChat