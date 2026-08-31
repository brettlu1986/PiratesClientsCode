local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIWatchBattle = luaclass("UIWatchBattle", WndBase)

local ClientEventDef = require("ClientEventDef")
local PlayerSelfHelper = require("GamePlayerSelfHelper")
local Proto = require("DungeonCommonProtoNames")
local CommonEventDef = require("CommonEventDef")
local UIResourceDef = require("UIResourceDef")
local WatchBattleSystem = require("WatchBattleSystem_C")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local UISetUtils = require("UISetUtils")
local UIDef = require("UIDef")
local L10N = require("L10N")
local UITextDef = require("UITextDef")
local UIManager = require("UIManager")
local UIUtils = require("UIUtils")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local StringUtil = require("StringUtil")
local TeamWatchClientHelper = require("TeamWatchClientHelper")
local BattleTeammateSystem = require("BattleTeammateSystem")
local GVoiceSDKSystem = require("GVoiceSDKSystem")
-- local InputHandle = require("InputHandle")
local DelayTimer = require("DelayTimer")

local EState = Proto.TeamInfo_EState

UIWatchBattle.tbLastWatchObj = nil
UIWatchBattle.tbCurrrentWatchObj = nil
UIWatchBattle.tbTeamOtherInfo = nil
UIWatchBattle.tbTeamBtnList = nil
UIWatchBattle.bShowMateList = false
UIWatchBattle.nTeamSurviveCount = 0

UIWatchBattle.ulWatchMateEnergy = nil
UIWatchBattle.ulWatchMateWeapon = nil
UIWatchBattle.ulWatchMateAim = nil
UIWatchBattle.ulWatchMateProgress = nil
UIWatchBattle.ulBattleTeam = nil
UIWatchBattle.ulBattleInfo = nil
UIWatchBattle.ulFFAToast = nil
UIWatchBattle.ulTeammateBuff = nil

UIWatchBattle.pbRadarMap = nil
UIWatchBattle.pbCompass = nil
UIWatchBattle.pbProgressBar = nil
UIWatchBattle.pbTeamMainHead = nil

UIWatchBattle.pbMainChatQuickView = nil
UIWatchBattle.pbMainChat = nil

UIWatchBattle.nVoiceMicPressedStart = 0
UIWatchBattle.nVoiceMicPressedEnd = 0
UIWatchBattle.pbVoiceMicCtr = nil
UIWatchBattle.pbVoiceSpeakerCtr = nil
UIWatchBattle.bVoiceMicOnPressed = false
UIWatchBattle.pVoicePressTimer = nil
UIWatchBattle.pDealyEffectTimer = nil

local Role_Human_Res = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_WatchMan.Spr_WatchMan'"
local Role_Ship_Res = "PaperSprite'/Game/UI/FFA/Textures/UI_FFAMain/Frames/Spr_WatchShip.Spr_WatchShip'"
local DOUBLE_MODE = 2
local SINGLE_MODE = 1
local EStopType = Proto.c2d_StopWatchTeammateBattle_EStopType
local PRESS_TIME_OUT = 10

------观战队友界面相关--

local function IsCurrentWatchOriginTeam() 
    return TeamWatchClientHelper.GetOtherWatchTeamId() == -1
end

--为当前正在观战的队友 刷新界面
local function RefreshCurrentMateInfo(self)
    if not self.tbCurrrentWatchObj then
        return
    end
    local pWidgetRef = self.pWidgetRef
    if not pWidgetRef then 
        return
    end
    local tbCurMateObj = self.tbCurrrentWatchObj
    pWidgetRef.txtViewPlayer:SetText(tbCurMateObj:GetName())

    local bWatchOrigin = IsCurrentWatchOriginTeam()
    if not bWatchOrigin then 
        pWidgetRef.btnChange:SetIsEnabled(false)
        pWidgetRef.chkViewPlayer:SetVisibility(ESlateVisibility.HitTestInvisible)
    end

    local pRes = nil
    if tbCurMateObj:IsShip() then
        pRes = Role_Ship_Res:load()
    else
        pRes = Role_Human_Res:load()
    end
    UISetUtils.SetImageBrushRes(pWidgetRef.ImgRole, pRes)

    self.ulBattleInfo:RefreshInfoCount()
    --刷新当前武器
    self.ulWatchMateWeapon:RefreshCurrentMateWeapon()
    --刷新当前血量 能量
    self.ulWatchMateEnergy:RefreshCurrentMateEnergy()
    --刷新重置小地图
    self.pbRadarMap:OnResetMapTarget()
    if self.pbTeamMainHead then
        --刷新重置队友名字片
        self.pbTeamMainHead:OnResetTarget()
    end
    --刷新人的瞄准图标
    self.ulWatchMateAim:RefreshCurrentMateAim()
    --刷新progress bar
    self.ulWatchMateProgress:RefreshCurrentProgressBarState()
    --刷新观战可能需要显示的 buff 屏幕特效
    self.ulTeammateBuff:RefreshCurrentMateBuff()

end

-------------------
--获取下一个或者的队友的消息
local function GetNextAliveMate(self)
    local tbTeamOtherInfo = self.tbTeamOtherInfo
    local nWatchInstanceId = self.tbCurrrentWatchObj.nServerInstanceId
    local tbNextMateInfo = nil
    local nCurrentIdx = 1
    local nTeamOtherCount = #tbTeamOtherInfo
    for i = 1, nTeamOtherCount do
        if nWatchInstanceId == tbTeamOtherInfo[i].nInstanceId then
            nCurrentIdx = i
            break
        end
    end

    local nLastIdx = nCurrentIdx
    while nCurrentIdx <= nTeamOtherCount do
        nCurrentIdx = nCurrentIdx + 1
        if nCurrentIdx > nTeamOtherCount then
            nCurrentIdx = 1
        end

        if nLastIdx == nCurrentIdx then  --not found
            break
        end

        local tbNextInfo = tbTeamOtherInfo[nCurrentIdx]
        if tbNextInfo.nState ~= EState.DEAD and tbNextInfo.nState ~= EState.ADDITIONALSUCCESS then
            tbNextMateInfo = tbNextInfo
            break
        end
    end

    return tbNextMateInfo
end

local function RefreshAliveMate(self)
    local tbNextValidInfo = GetNextAliveMate(self)
    self.ulWatchMateProgress:ClearProgressBar()
    if tbNextValidInfo then
        local tbCurrentMateObj = self.tbCurrrentWatchObj
        if tbCurrentMateObj.nServerInstanceId == tbNextValidInfo.nInstanceId then
            log("[ClientWatch] :RefreshAliveMate already change to this watch mate", tbCurrentMateObj.nServerInstanceId)
        else
            log("[ClientWatch] :RefreshAliveMate change to original team")
            self.EventHelper:FireEvent(CommonEventDef.EV_REQUEST_CHANGE_WATCH_MATE, tbNextValidInfo.nInstanceId)
        end
    else
        if IsCurrentWatchOriginTeam() then   
            log("[ClientWatch]:RefreshAliveMate original team dead, open battle result")
            WatchBattleSystem:RequestStopWatchTeammate(EStopType.FINISH)
            --观战的队友突然挂了，需要重设镜头角度
            self.EventHelper:FireEvent(ClientEventDef.EV_GAME_OVER_CAMERA_DETACH, true)
            self.EventHelper:FireEvent(ClientEventDef.EV_BATTLE_OPEN_RESULT, true)
        else   
            log("[ClientWatch]:RefreshAliveMate other team, try to change otherteam")
            self.EventHelper:FireEvent(CommonEventDef.EV_REQUEST_CHANGE_WATCH_OTHER)
        end
    end
end

local function ShowRequestLoading(bShow)
    if bShow then  
        UIUtils.ShowWaitingPacket()
    else   
        UIUtils.HideWaitingPacket()
    end
end

--假如当前观战的队友死亡，要么切下一个，要么直接走死亡结算流程
local function OnPawnDead(self, nDeadInsId)
    local tbCurrentMateObj = self.tbCurrrentWatchObj
    if tbCurrentMateObj and tbCurrentMateObj.nServerInstanceId == nDeadInsId then
        RefreshAliveMate(self)
    end
end

--发送切换观战队员成功之后接收到事件
local function OnRefreshViewForNewMate(self, tbNewMateObj)
    ShowRequestLoading(false)
    self.tbLastWatchObj = self.tbCurrrentWatchObj
    self.tbCurrrentWatchObj = tbNewMateObj
    RefreshCurrentMateInfo(self)
    --logdebug("EV_REFRESH_WATCH_MATE trigger in watch battle view")
end

--刷新列表队友状态
local function RefreshMateListItem(self)
    local nTeamOtherCount = #self.tbTeamOtherInfo
    local nBtnCount = #self.tbTeamBtnList
    local txtMateName, tbMateInfo
    for i = 1, nBtnCount do
        local pBtn = self.tbTeamBtnList[i]
        if i > nTeamOtherCount then
            pBtn:SetVisibility(ESlateVisibility.Collapsed)
        else
            pBtn:SetVisibility(ESlateVisibility.Visible)
            tbMateInfo = self.tbTeamOtherInfo[i]
            txtMateName = self.pWidgetRef["txtName0"..i]
            txtMateName:SetText(tbMateInfo.name)
            if tbMateInfo.nState == EState.DEAD or
                tbMateInfo.nState == EState.ADDITIONALSUCCESS then
                pBtn:SetIsEnabled(false)
                txtMateName:SetColorAndOpacity(UIResourceDef.COLOR.GREY.SLATE_COLOR)
            else
                txtMateName:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.SLATE_COLOR)
            end
        end
    end
end

--队伍人员状态变化触发事件
local function OnFFATeamInfoChanged(self)
    local tbPlayer = PlayerSelfHelper:Get()
    local bWatchOrigin = IsCurrentWatchOriginTeam()
    if not bWatchOrigin then   
        return
    end
    local tbOriginalTeamInfo = TeamWatchClientHelper.GetOriginalTeamInfo()
    if tbOriginalTeamInfo then
        local nPlayerId = tbPlayer:GetServerInstanceId()
        local nSurviveCount = 0
        local bNeedRefresh = false
        local nWatchId = self.tbCurrrentWatchObj ~= nil and self.tbCurrrentWatchObj.nServerInstanceId or -1
        self.tbTeamOtherInfo = {}
        for k, v in ipairs(tbOriginalTeamInfo) do
            if v.nInstanceId ~= nPlayerId then
                table.insert(self.tbTeamOtherInfo, v)
            end
            if v.nState ~= EState.DEAD and v.nState ~= EState.ADDITIONALSUCCESS then
                nSurviveCount = nSurviveCount + 1
            end
            if v.nInstanceId == nWatchId and
                (v.nState == EState.ADDITIONALSUCCESS or
                v.nState == EState.DEAD ) then
                bNeedRefresh = true
            end
        end
        if bNeedRefresh then
            RefreshAliveMate(self)
        end
        self.nTeamSurviveCount = nSurviveCount
    end
    --队员列表显示中 需要刷新状态
    if self.bShowMateList then
        RefreshMateListItem(self)
    end
end

--初始化队伍数据
local function InitTeamSurvive(self)
    OnFFATeamInfoChanged(self)
end

--显示 其他队友列表
local function OnChangeMateListVisible(self)
    self.bShowMateList = not self.bShowMateList
    local pWidgetRef = self.pWidgetRef
    if self.bShowMateList then
        pWidgetRef.bdrPlayer:SetVisibility(ESlateVisibility.Visible)
        RefreshMateListItem(self)
        self:PlayAnimation("animTeam", 0, 1, EUMGSequencePlayMode.Forward, 1)
    else
        pWidgetRef.bdrPlayer:SetVisibility(ESlateVisibility.Collapsed)
        self:PlayAnimation("animTeam", 0, 1, EUMGSequencePlayMode.Reverse, 1)
    end
end

local function OnOpenMateList(self, bChecked)
    if self.bShowMateList == bChecked then
        return
    end
    OnChangeMateListVisible(self)
end

--点击非列表地方 需要关闭队友列表
local function OnMouseButtonUp(self, pGeometry, pMouseEvent)
    if self.bShowMateList then
        OnChangeMateListVisible(self)
    end
    return WidgetBlueprintLibrary.Handled()
end

--选择队友观战
local function OnMateListSelect(self, nSelectIdx)
    local tbSelectMateInfo = self.tbTeamOtherInfo[nSelectIdx]

    --选中队友之后 需要关闭列表
    if self.bShowMateList then
        OnChangeMateListVisible(self)
    end

    if self.tbCurrrentWatchObj and self.tbCurrrentWatchObj.nServerInstanceId == tbSelectMateInfo.nInstanceId then
        return
    end
    ShowRequestLoading(true)
    self.EventHelper:FireEvent(CommonEventDef.EV_REQUEST_CHANGE_WATCH_MATE, tbSelectMateInfo.nInstanceId)
end

--初始化ui状态
local function InitUIWidgetState(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.bdrPlayer:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.pMateInfo:SetVisibility(ESlateVisibility.Collapsed)
    if  IsCurrentWatchOriginTeam() then  
        self.tbTeamBtnList = {}        
        local pTeamListRef = pWidgetRef.vbList
        local nCount = pTeamListRef:GetChildrenCount()
        for i = 1, nCount do
            local pBtn = pTeamListRef:GetChildAt(i - 1)
            self.EventHelper:RegisterCppDelegate(pBtn.OnClicked, self, function() OnMateListSelect(self, i) end)
            self.tbTeamBtnList[i] = pBtn
        end
    end
end

--填充玩家数据
local function RefreshMemberStatistic(self, tbPacket)
    ShowRequestLoading(false)
    local pWidgetRef = self.pWidgetRef

    local tbCurMateObj = self.tbCurrrentWatchObj
    
    local nTeamCount = TeamWatchClientHelper.GetTeamCount()
    if nTeamCount == SINGLE_MODE then  
        pWidgetRef.txtMode:SetText(UITextDef.FFA_SINGLE_WATCH_BATTLE) 
    elseif nTeamCount == DOUBLE_MODE then
        pWidgetRef.txtMode:SetText(UITextDef.LOBBYCHAT_TEAMINGMODE_TOW)
    else  
        local l10nCount = UISetUtils.GetL10NTextByKey(string.format("COMMON_NUMBER_%d", nTeamCount))
        local l10nMode = UITextDef.WATCH_BATTLE_MODE
        l10nMode = L10N:Format(l10nMode, l10nCount)
        pWidgetRef.txtMode:SetText(L10N:ToString(l10nMode))
    end

    pWidgetRef.txtTitleName:SetText(tbCurMateObj:GetName())
    pWidgetRef.txtRounds:SetText(tbPacket.nGames)
    pWidgetRef.txtDefeatCount:SetText(tbPacket.nKills)
    pWidgetRef.txtWinCount:SetText(tbPacket.nWins)
    pWidgetRef.txtTop10Count:SetText(tbPacket.nTopTens)
    pWidgetRef.txtCurKills:SetText(tbPacket.nKillCount)

    pWidgetRef.pMateInfo:SetVisibility(ESlateVisibility.Visible)
end

--显示玩家详情数据
local function OnShowCurrentMateStatistic(self, bChecked)
    local pWidgetRef = self.pWidgetRef
    if bChecked then
        if self.bShowMateList then
            OnChangeMateListVisible(self)
        end
        local nWatchId = self.tbCurrrentWatchObj.nServerInstanceId
        WatchBattleSystem:RequestWatchTeammateStatistics(nWatchId)
        ShowRequestLoading(true)
    else
        pWidgetRef.pMateInfo:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function OnCloseMateStatistic(self)
    local pWidgetRef = self.pWidgetRef
    if pWidgetRef.ckOpenInfo:GetCheckedState() == ECheckBoxState.Checked then
        pWidgetRef.ckOpenInfo:SetCheckedState(ECheckBoxState.Unchecked)
    end
    OnShowCurrentMateStatistic(self, false)
end

local function OnExitGame(self)
    WatchBattleSystem:SetSelfExitWatch(true)
    WatchBattleSystem:RequestStopWatchTeammate(EStopType.ABORT)
    --主动退出的只需要detach就可以了，不需要重设镜头的角度跟距离
    self.EventHelper:FireEvent(ClientEventDef.EV_GAME_OVER_CAMERA_DETACH, false)
    self.EventHelper:FireEvent(ClientEventDef.EV_BATTLE_OPEN_RESULT, self.nTeamSurviveCount == 0)
end

-- option & talk logic
local function OnSetClicked(self)
    UIManager:OpenWnd(UIDef.UI_SETTING)
end

local function OnSayClicked(self)
    self.pbMainChat:ToggleActivate()
end

local function RefreshPing(self)
    local nPing = ExtendBlueprintFunctions.GetPing(GWorld)
    self.pWidgetRef.txtPing:SetText(nPing.."ms")
end

local function OnVoiceMicClicked(self)
    local pbVoiceMicCtr = self.pbVoiceMicCtr
    local nMicOption = pbVoiceMicCtr:GetCurrentMicOption()
    local nPressInterval = self.nVoiceMicPressedEnd - self.nVoiceMicPressedStart
    if nMicOption < pbVoiceMicCtr.PRESSALL or pbVoiceMicCtr.bVisible or nPressInterval < 1 then
        self.pbVoiceMicCtr:Toggle()
    end
end

local function ClearVoiceMicPressTimer(self)
    if self.pVoicePressTimer then
        DelayTimer:ClearTimer(self.pVoicePressTimer)
        self.pVoicePressTimer = nil
    end
end

local function ClearDelayEffectTimer(self)
    if self.pDealyEffectTimer then
        DelayTimer:ClearTimer(self.pDealyEffectTimer)
        self.pDealyEffectTimer = nil
    end
end

local function OnVoiceMicReleased(self)
    local pbVoiceMicCtr = self.pbVoiceMicCtr
    local nMicOption = pbVoiceMicCtr:GetCurrentMicOption()
    if nMicOption == pbVoiceMicCtr.PRESSALL or nMicOption == pbVoiceMicCtr.PRESSTEAM then
        local pWidgetRef = self.pWidgetRef
        self.nVoiceMicPressedEnd = os.time()
        GVoiceSDKSystem:EnableMic(false)
        self.bVoiceMicOnPressed = false
        pWidgetRef.imgPress:SetVisibility(ESlateVisibility_Collapsed)
        ClearVoiceMicPressTimer(self)
        ClearDelayEffectTimer(self)
    end
end

local function OnVoiceMicPressed(self)
    local pbVoiceMicCtr = self.pbVoiceMicCtr
    local nMicOption = pbVoiceMicCtr:GetCurrentMicOption()
    if nMicOption == pbVoiceMicCtr.PRESSALL or nMicOption == pbVoiceMicCtr.PRESSTEAM then
        local pWidgetRef = self.pWidgetRef
        self.nVoiceMicPressedStart = os.time()
        GVoiceSDKSystem:EnableMic(true)
        self.bVoiceMicOnPressed = true
        ClearDelayEffectTimer(self)
        self.pDealyEffectTimer = DelayTimer:DelayRun(function() pWidgetRef.imgPress:SetVisibility(ESlateVisibility_HitTestInvisible) end, 0.5)
        ClearVoiceMicPressTimer(self)
        self.pVoicePressTimer = DelayTimer:DelayRun(function() OnVoiceMicReleased(self) end, PRESS_TIME_OUT)
    end
end

local function OnVoiceSpeakerClicked(self)
    if self.bVoiceMicOnPressed then
        return
    end
    self.pbVoiceSpeakerCtr:Toggle()
end

----
function UIWatchBattle:OnLoad()
    self.tbCurrrentWatchObj = self.tbOpenArgs.tbMateObj
    local UILogicHelper = self.UILogicHelper
    self.ulWatchMateEnergy = UILogicHelper:CreateUILogic("ULWatchBattleEnergy")
    self.ulWatchMateWeapon = UILogicHelper:CreateUILogic("ULWatchBattleWeapon")

    local nTeamCount = TeamWatchClientHelper.GetTeamCount()
    if nTeamCount > 1 then
        self.ulBattleTeam = UILogicHelper:CreateUILogic("ULBattleTeam")
    end

    self.ulBattleInfo = UILogicHelper:CreateUILogic("ULWatchBattleInfo")
    self.ulWatchMateAim = UILogicHelper:CreateUILogic("ULWatchBattleMateAim")
    self.ulWatchMateProgress = UILogicHelper:CreateUILogic("ULWatchBattleProgressBar")
    self.ulTeammateBuff = UILogicHelper:CreateUILogic("ULWatchBattleBuff")
    self.ulFFAToast = UILogicHelper:CreateUILogic("ULFFAToastBoard")
    local ulFFAMainStaticLayout = UILogicHelper:CreateUILogic("ULFFAMainStaticLayout")
    ulFFAMainStaticLayout:Init()

    -- bind prefab
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    local pbCutoutScreenAdapter = PrefabHelper:BindPrefab(pWidgetRef.pbCutoutScreenAdapter)
    self.nCutoutSpacerWidth = pbCutoutScreenAdapter:GetCutoutSpacerWidth()
    self.pbCompass = PrefabHelper:BindPrefab(pWidgetRef.pbCompass)
    self.pbRadarMap = PrefabHelper:BindPrefab(pWidgetRef.pbRadarMap, UIDef.UP_RADAR_MAP) --, UIDef.UP_RADAR_MAP_WATCH_MATE
    self.pbProgressBar = PrefabHelper:BindPrefab(pWidgetRef.pbProgressBar, UIDef.UP_PROGRESS_BAR_WATCH_MATE )
    if BattleTeammateSystem:GetTeamMode() > 1 then
        self.pbTeamMainHead = PrefabHelper:BindPrefab(pWidgetRef.pbTeamMainHead)
    end
    self.pbMainChatQuickView = PrefabHelper:BindPrefab(pWidgetRef.pbMainChatQuickView)
    self.pbMainChat = PrefabHelper:BindPrefab(pWidgetRef.pbMainChat)
    self.pbVoiceMicCtr = PrefabHelper:BindPrefab(pWidgetRef.pbFFAMainTalk01)
    self.pbVoiceMicCtr:InitDefaultSelect()
    self.pbVoiceSpeakerCtr = PrefabHelper:BindPrefab(pWidgetRef.pbFFAMainTalk02)
    self.pbVoiceSpeakerCtr:InitDefaultSelect()
    self.pbShipWeaponCannon = PrefabHelper:BindPrefab(self.pWidgetRef.pbShipWeaponCannon)

    pWidgetRef.imgPress:SetVisibility(ESlateVisibility_Collapsed)
end

--init ui content, OnEnter or OnShow
function UIWatchBattle:OnEnter()
    --self.pbRadarMap:InitWatchBattleRadar()
    self.tbTeamOtherInfo = {}
end

function UIWatchBattle:OnShow()
    InitUIWidgetState(self)
    InitTeamSurvive(self)
    RefreshCurrentMateInfo(self)

    if GlobalVariableSystem:IsStandalone() then
        self.pWidgetRef.txtPing:SetVisibility(ESlateVisibility.Collapsed)
    else
        -- 非常临时的做法，lua里不应该有这么频繁的Tick
        self.TimerHelper:NewTimerMethod(self, RefreshPing, 1, true)
        -- 设置DungeonSessionId
        local szDungeonSessionId = BattleGameModeSystem:GetShortDungeonSessionId()
        if not StringUtil.IsEmptyString(szDungeonSessionId) then
            self.pWidgetRef.txtDungeonSessionId:SetText(szDungeonSessionId)
        else
            self.pWidgetRef.txtDungeonSessionId:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
end

function UIWatchBattle:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnChange.OnClicked, self, OnChangeMateListVisible)
    EventHelper:RegisterCppDelegate(pWidgetRef.bdrForTouch.OnMouseButtonUpEvent, self, OnMouseButtonUp)
    EventHelper:RegisterCppDelegate(pWidgetRef.ckOpenInfo.OnCheckStateChanged, self, OnShowCurrentMateStatistic)
    EventHelper:RegisterCppDelegate(pWidgetRef.chkViewPlayer.OnCheckStateChanged, self, OnOpenMateList)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnInfoClose.OnClicked, self, OnCloseMateStatistic)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnExitGame.OnClicked, self, OnExitGame)

    EventHelper:RegisterCppDelegate(pWidgetRef.btnSay.OnClicked, self, OnSayClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSet.OnClicked, self, OnSetClicked)

    EventHelper:RegisterEvent(ClientEventDef.EV_REFRESH_WATCH_MATE, self, OnRefreshViewForNewMate)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_CHANGED, self, OnFFATeamInfoChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_SHOW_WATCH_MATE_TIPS, self, RefreshMemberStatistic)
    -- EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnPawnDead)
    EventHelper:RegisterEvent(ClientEventDef.EV_PAWN_DEAD_WATCHER_CHECK, self, OnPawnDead)

    -- self.tbC = InputHandle:BindKeyReleased(EInputKey.C, function()
    --     logdebug("Current Watch Id : ", TeamWatchClientHelper.GetCurrentWatchId() )
    -- end, self)
    -- self.EventHelper:RegisterHandle(self.tbC)

    EventHelper:RegisterCppDelegate(pWidgetRef.btnTalk01.OnClicked                  , self, OnVoiceSpeakerClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnTalk02.OnClicked                  , self, OnVoiceMicClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnTalk02.OnPressed                  , self, OnVoiceMicPressed)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnTalk02.OnReleased                 , self, OnVoiceMicReleased)

end

function UIWatchBattle:OnExit()

end

function UIWatchBattle:OnUnload()
    self.ulWatchMateProgress:ClearProgressBar()
    self.ulTeammateBuff:ClearWatchBuff()
    --unload res
end

return UIWatchBattle