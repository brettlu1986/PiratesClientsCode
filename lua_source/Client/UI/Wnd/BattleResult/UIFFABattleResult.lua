-----------------------------------------------------
--File Name    : UIFFABattleResult.lua
--Description  : FFA战斗结算界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIFFABattleResult = luaclass("UIFFABattleResult", WndBase)

local UISetUtils = require("UISetUtils")
local ScreenCaptureHelper = require("ScreenCaptureHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local AvatarDataTable = require("AvatarDataTable")
local HeadIconResDataTable = require("HeadIconResDataTable")
local L10N = require("L10N")
local BattleResultSystem = dynamic_require("BattleResultSystem")
local GenderTypeDefine = require("GenderTypeDefine")
local UIResourceDef = require("UIResourceDef")
local DelayTimer = require("DelayTimer")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local FriendSystem = require("FriendSystem")
local Proto = require("ClientProtoNames")
local CurrencyIni = require("CurrencyIni")
local CurrencySystem = require("CurrencySystem")
local TutorialDungeonIni = require("TutorialDungeonIni")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local WatchBattleSystem = dynamic_require("WatchBattleSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local UITextDef = require("UITextDef")
local UIUtils = require("UIUtils")
local ClientEventDef = require("ClientEventDef")
local CommonEventDef = require("CommonEventDef")
local UIStateDef = require("UIStateDef")
local TeamWatchClientHelper = require("TeamWatchClientHelper")
local BattleResultIni = require("BattleResultIni")
local BattleResultServerIni = require("BattleResultServerIni")
local BattleItemDataTable = require("BattleItemDataTable")

local VISIBLE = ESlateVisibility.Visible
local HIT_TEST_IN_VISIBLE = ESlateVisibility.HitTestInvisible
local COLLAPSED = ESlateVisibility.Collapsed
local TEAM_MEMBER_COUNT = 4
local SHOT_DELAY = 0.2
local EXP_ITEM_ID = 2300001
local GOLD_ITEM_ID = 1400000
local SINGLE_MODE = 1
local COUNT_DOWN_TIME = 10
local DEFALUT_NAME = UISetUtils.GetL10NTextByKey("BATTLE_RESULT_PLAYER_DEFAULT_NAME")
local IMAGE_SIZE = 43

UIFFABattleResult.OtherTeamMember = nil
UIFFABattleResult.tbDelayHandle = nil

local function SetTeamMemberInfo(self, nIndex, nAvatarId, nGenderType, name, nPlayerId)
    local pWidgetRef = self.pWidgetRef
    --头像
    local HumanTemplate = AvatarDataTable:GetTemplate(nAvatarId)
    if not HumanTemplate then
        logerror("UIFFABattleResult:SetTeamMemberInfo,HumanTemplate is nil,templateid=", nAvatarId)
        return
    end
    local szHeadIconPath = HeadIconResDataTable:GetResPath(HumanTemplate.nHeadIconId)
    if szHeadIconPath then
        local pIconObj = szHeadIconPath:load()
        if pIconObj then
            local pHeadIconWidget = pWidgetRef["imgPlay0"..nIndex]
            pWidgetRef["imgPlayBg0"..nIndex]:SetVisibility(HIT_TEST_IN_VISIBLE)
            pHeadIconWidget:SetVisibility(HIT_TEST_IN_VISIBLE)
            UISetUtils.SetImageBrushRes(pHeadIconWidget, pIconObj)
        end
    end
    --性别
    local szGenderIcon = UIResourceDef.GENDER_FEMALE
    if nGenderType == GenderTypeDefine.MALE then
        szGenderIcon = UIResourceDef.GENDER_MALE
    end
    local pSexWidget = pWidgetRef["imgSexPlay0"..nIndex]
    pSexWidget:SetVisibility(HIT_TEST_IN_VISIBLE)
    UISetUtils.SetImageBrushRes(pSexWidget, szGenderIcon:load(), true)
    --名字
    local pNameWidget = pWidgetRef["txtPlayName0"..nIndex]
    pNameWidget:SetVisibility(HIT_TEST_IN_VISIBLE)
    pNameWidget:SetText(name)
    --添加好友按钮

    local FriendComponent = FriendSystem:GetComponent()
    if FriendComponent ~= nil then
        if FriendComponent:GetFriend(nPlayerId) ~= nil then
            pWidgetRef["btnAdd0"..nIndex]:SetVisibility(COLLAPSED)
        else
            pWidgetRef["btnAdd0"..nIndex]:SetVisibility(VISIBLE)
        end
    else
        log("UIFFABattleResult not find friendcomponent")
        pWidgetRef["btnAdd0"..nIndex]:SetVisibility(VISIBLE)
    end
end

local function IsTutorialDungeon()
    local nDungeonId = BattleGameModeSystem.nDungeonId
    if nDungeonId == TutorialDungeonIni.nDungeonId then
        return true
    end
    return false
end

local function SetInfo(self)
    local tbInfo = self.tbOpenArgs.tbTeamInfo
    if not tbInfo then
        return
    end
    local tbTeamMemberData = self.tbOpenArgs.tbTeamMemberData
    if not tbTeamMemberData then
        return
    end
    local pWidgetRef = self.pWidgetRef
    local bInLobby = self.tbOpenArgs.bInLobby
    local bIsTutorialDungeon = IsTutorialDungeon()
    if not bInLobby then
        if bIsTutorialDungeon then
            pWidgetRef.cvsItem:SetVisibility(ESlateVisibility_Collapsed)
        else
            pWidgetRef.cvsItem:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        end
    end
    --log("UIFFABattleResult:SetInfo,nRank,nKillCount,nSurvivalTime,nTotalPlayerCount=",nRank,nKillCount,nSurvivalTime,nTotalPlayerCount)
    local tbSelfData = nil
    local nSelfPlayerId = self.tbOpenArgs.nSelfPlayerId or GamePlayerSelfHelper:Get().nPlayerId

    pWidgetRef.btnContinue:SetVisibility(self.tbOpenArgs.bInLobby and COLLAPSED or VISIBLE)
    pWidgetRef.btnShare:SetVisibility(self.tbOpenArgs.bInLobby and COLLAPSED or VISIBLE)
    pWidgetRef.imgLogo:SetVisibility(self.tbOpenArgs.bInLobby and HIT_TEST_IN_VISIBLE or COLLAPSED)
    pWidgetRef.Image_0:SetVisibility(self.tbOpenArgs.bInLobby and COLLAPSED or VISIBLE)
    pWidgetRef.imgBack:SetVisibility(self.tbOpenArgs.bInLobby and HIT_TEST_IN_VISIBLE or COLLAPSED)
    for i = 1, TEAM_MEMBER_COUNT - 1 do
        pWidgetRef["btnAdd0"..i]:SetVisibility(self.tbOpenArgs.bInLobby and COLLAPSED or VISIBLE)
    end
    --队友
    local nTeamMemberCount = #tbTeamMemberData
    if nTeamMemberCount > 1 then
        pWidgetRef.cvsTeam:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
    local nMemberIndex = 1
    for k, v in ipairs(tbTeamMemberData) do
        if v.nPlayerId == nSelfPlayerId then
            tbSelfData = v
        elseif nTeamMemberCount > 1 then
            SetTeamMemberInfo(self, nMemberIndex, v.nAvatarId, v.nGenderType, v.name, v.nPlayerId)
            self.OtherTeamMember[nMemberIndex] = v.nPlayerId
            nMemberIndex = nMemberIndex + 1
        end
    end
    for i = nMemberIndex, TEAM_MEMBER_COUNT - 1 do
        pWidgetRef["btnAdd0"..i]:SetVisibility(COLLAPSED)
    end

    --个人信息
    local HumanTemplate = AvatarDataTable:GetTemplate(tbSelfData.nAvatarId)
    if not HumanTemplate then
        logerror("UIFFABattleResult:SetInfo,HumanTemplate is nil,templateid=", tbSelfData.nAvatarId)
        return
    end
    local tbHeadTemplate = HeadIconResDataTable:GetTemplate(HumanTemplate.nHeadIconId)
    if tbHeadTemplate then
        local pIconObj = nil
        if tbHeadTemplate.szFFAResultPath then
            pIconObj = tbHeadTemplate.szFFAResultPath:load()
        end
        if not pIconObj then
            pIconObj = tbHeadTemplate.szPath:load()
        end
        if pIconObj then
            UISetUtils.SetImageBrushRes(pWidgetRef.imgPlayerAvatarIcon, pIconObj)
        end
    end
    local szName = tbSelfData.name
    if not szName or szName == "" then
        szName = DEFALUT_NAME
    end
    pWidgetRef.txtPlayerName:SetText(szName)

    --个人排名or队伍排名
    local l10Detail = UISetUtils.GetL10NTextByKey("FFA_RESULT_DETAIL")
    local nRank = tbSelfData.nPlayerRank
    if not nRank then
        nRank = 1
    end
    local l10Rank = nil
    if bIsTutorialDungeon then
        l10Detail = L10N:Format(UISetUtils.GetL10NTextByKey("TUTORIAL_RESULT_DETAIL"), nRank)
        l10Rank = L10N:Format(UISetUtils.GetL10NTextByKey("FFA_RESULT_RANK"), nRank, tbInfo.nPlayerCount)
    else
        if tbInfo.nMode ~= SINGLE_MODE and tbInfo.bTeamDead and not self.tbOpenArgs.bInLobby then
            l10Detail = UISetUtils.GetL10NTextByKey("FFA_RESULT_DETAIL_TEAM")
            nRank = tbInfo.nTeamRank
            l10Rank = L10N:Format(UISetUtils.GetL10NTextByKey("FFA_RESULT_TEAM_RANK"), tbInfo.nTeamRank, tbInfo.nTeamCount)
        else
            l10Rank = L10N:Format(UISetUtils.GetL10NTextByKey("FFA_RESULT_RANK"), nRank, tbInfo.nPlayerCount)
        end
        l10Detail = L10N:Format(l10Detail, nRank, tbSelfData.nKillCount)
    end
    pWidgetRef.rtxtRank:SetText(l10Rank)
    pWidgetRef.rtxtDetail:SetText(l10Detail)

    --奖励
    local nExpCount = 0
    local nCurrencyCount = 0
    local nLevelupItemCount = 0
    local tbAwards = tbSelfData.Awards
    --logdebug("tbAwards,tbSelfData.nGradeScore,tbSelfData.nExtraScore,tbSelfData.nSurvivalScore,tbSelfData.nKillScore=",tbAwards,tbSelfData.nGradeScore,tbSelfData.nExtraScore,tbSelfData.nSurvivalScore,tbSelfData.nKillScore)
    if tbAwards then
        for k, v in ipairs(tbAwards) do
            if v.nItemId == EXP_ITEM_ID then
                nExpCount = v.nItemCount
            elseif v.nItemId == GOLD_ITEM_ID then
                nCurrencyCount = v.nItemCount
            elseif v.nItemId == BattleResultServerIni.nRusultEquipLevelupItem then
                nLevelupItemCount = v.nItemCount
            end
        end
    end

    --原力之尘
    local tbItemResTemplate = BattleItemDataTable:GetResTemplate(BattleResultServerIni.nRusultEquipLevelupItem)
    local szIconPath = tbItemResTemplate.szIconPath
    UISetUtils.SetImageBrushRes(pWidgetRef.imgCurrency2, szIconPath:load(), false, true, IMAGE_SIZE, IMAGE_SIZE)
    local l10RewardMax = L10N:Format(UISetUtils.GetL10NTextByKey("DYNAMIC_BATTLE_RESULT_MAX_REWARD"), BattleResultServerIni.nRewardMax)
    if nLevelupItemCount >= BattleResultServerIni.nRewardMax then  
        pWidgetRef.txtCurrency2:SetText(string.format("%d%s", nLevelupItemCount, L10N:ToString(l10RewardMax)))
    else  
        pWidgetRef.txtCurrency2:SetText(nLevelupItemCount)
    end

    if nCurrencyCount > 0 or not CurrencySystem:ReachCurrencyMax(CurrencyIni.tbCurrencyCeiling.nCurrencyId) then
        pWidgetRef.hboxCurrency:SetVisibility(HIT_TEST_IN_VISIBLE)
        pWidgetRef.bdrGoldUp:SetVisibility(COLLAPSED)
        pWidgetRef.txtCurrency:SetText(nCurrencyCount)
    else
        pWidgetRef.hboxCurrency:SetVisibility(COLLAPSED)
        pWidgetRef.bdrGoldUp:SetVisibility(HIT_TEST_IN_VISIBLE)
    end

    pWidgetRef.txtExp:SetText(nExpCount)
    local szSignTotalScore = ""
    if tbSelfData.nGradeScore > 0 then
        szSignTotalScore = "+"
    end
    local l10nTotalScore = szSignTotalScore .. tbSelfData.nGradeScore
    if tbSelfData.nExtraScore and tbSelfData.nExtraScore > 0 then
        l10nTotalScore = L10N:Format(UISetUtils.GetL10NTextByKey("FFA_RESULT_TOTAL_SCORE"), l10nTotalScore, tbSelfData.nExtraScore)
    end
    pWidgetRef.txtTotalScore:SetText(l10nTotalScore)
    local szSignSurvivalScore = ""
    if tbSelfData.nSurvivalScore > 0 then
        szSignSurvivalScore = "+"
    end
    local szSurvivalScore = szSignSurvivalScore .. tbSelfData.nSurvivalScore
    pWidgetRef.txtSurvivalScore:SetText(szSurvivalScore)
    local szSignKillScore = ""
    if tbSelfData.nKillScore > 0 then
        szSignKillScore = "+"
    end
    local szKillScore = szSignKillScore .. tbSelfData.nKillScore
    pWidgetRef.txtKillScore:SetText(szKillScore)

    --标语
    if tbInfo.bKillBoss then
        --击杀boss结算
        pWidgetRef.txtResult:SetText(UISetUtils.GetL10NTextByKey("FFA_RESULT_KILL_BOSS"))
        pWidgetRef.btnDeadPlayback:SetVisibility(ESlateVisibility_Collapsed)
    else
        --吃鸡or失败
        if tbInfo.nTeamRank == 1 then
            pWidgetRef.txtResult:SetText(UISetUtils.GetL10NTextByKey("FFA_RESULT_SUCCESS"))
            pWidgetRef.btnDeadPlayback:SetVisibility(ESlateVisibility_Collapsed)
        else
            pWidgetRef.txtResult:SetText(UISetUtils.GetL10NTextByKey("FFA_RESULT_FAIL"))
            pWidgetRef.btnDeadPlayback:SetVisibility(self.tbOpenArgs.bInLobby and ESlateVisibility_Collapsed or ESlateVisibility_Visible)
        end
    end
    pWidgetRef.txtContinue:SetText(UISetUtils.GetL10NTextByKey("COMMON_CONTINUE"))
end

local function OnContinueClicked(self)
    BattleResultSystem:EnterFFAStatistic()
end

local function OnScreenShotCaptureFinished(self, Width, Height, ShotTexture)
    UIManager:SnapshotUI(false, {UIDef.UI_FFA_BATTLE_RESULT})
    local tbOpenArg =
    {
        Width = Width,
        Height = Height,
        ShotTexture = ShotTexture,
    }
    UIManager:OpenWnd(UIDef.UI_FFA_BATTLE_SHARE, tbOpenArg)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnContinue:SetVisibility(VISIBLE)
    pWidgetRef.btnShare:SetVisibility(VISIBLE)
    pWidgetRef.imgLogo:SetVisibility(COLLAPSED)
end

local function OnShareRankClicked(self)
    if self.tbDelayHandle then
        return
    end
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnContinue:SetVisibility(COLLAPSED)
    pWidgetRef.btnShare:SetVisibility(COLLAPSED)
    pWidgetRef.imgLogo:SetVisibility(HIT_TEST_IN_VISIBLE)
    UIManager:SnapshotUI(true, {UIDef.UI_FFA_BATTLE_RESULT})

    local CameraShot = function()
        ScreenCaptureHelper.Capture(function(...)
            if not self.tbOpenArgs.bInLobby then
                OnScreenShotCaptureFinished(self, ...)
            end
        end)
        self.tbDelayHandle = nil
    end

    self.tbDelayHandle = DelayTimer:DelayRun(CameraShot, SHOT_DELAY)
end

local function OnAddFriendClicked(self, nIndex)
    local nPlayerId = self.OtherTeamMember[nIndex]
    if nPlayerId ~= nil then
        if nPlayerId > 0 then
            FriendSystem:RequestApplyFriend(nPlayerId,
            L10N:ToString(UISetUtils.GetL10NTextByKey("FFA_APPLYFRIEND_MESSAGE_BYTEAM")),
            Proto.FriendSource.GAME_RESULT)
        else
            UIUtils.ShowToast(UITextDef.FRIEND_APPLY_SUCCESS)
        end
    end
end

local function OnDeadPlaybackClicked(self)
    UIManager:OpenWnd(UIDef.UI_FFA_BATTLE_DEAD_PLAYBACK)
end

local function OnBattleGameOver(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnWatchOther:SetVisibility(COLLAPSED)
    pWidgetRef.txtCountDown:SetCountDownEnable(false)
    local l10nContinue = UISetUtils.GetL10NTextByKey("BATTLE_RESULT_CONTINUE_PARAM")
    pWidgetRef.txtContinue:SetTimerStart(l10nContinue, false, GlobalVariableSystem:GetLocalTime() + BattleResultIni.tbBattleResult.nResultCountdown)
end

--观察对手
local function CheckWatchOther(self)
    local pWidgetRef = self.pWidgetRef
    local bShowWatchOtherBtn = true 

    -- 这里队伍死亡 包括  多人模式 所有人死亡， 多人模式但是进入的是单人或 队伍不满员， 单人模式单人死亡
    -- 只有队伍都死亡了， 结算才会显示观战对手
    local bNotShowConditon_1 = not TeamWatchClientHelper.IsOriginalTeamDead()  
    local bNotShowCondition_2 = TeamWatchClientHelper.IsOtherTeamWatch() and WatchBattleSystem:IsSelfExitWatch()
    -- local bNotShowCondition_3 = WatchBattleSystem:IsReloginTeamDead()

    log("[CheckWatchOther ] cons ::", WatchBattleSystem:IsBattleEnd(), bNotShowConditon_1, bNotShowCondition_2)
    local bNotShowState = WatchBattleSystem:IsBattleEnd() or GlobalVariableSystem:IsStandalone() 
        or bNotShowConditon_1 or bNotShowCondition_2 --or bNotShowCondition_3
        
    --已经吃鸡不显示 观战对手
    if bNotShowState then   
        bShowWatchOtherBtn = false
    end   
    if bShowWatchOtherBtn then
        local l10nCountDown = UITextDef.FFA_WATCH_OTHER_COUNTDOWN 
        pWidgetRef.txtCountDown:SetTimerStart(L10N:ToString(l10nCountDown),false, GlobalVariableSystem:GetLocalTime() + COUNT_DOWN_TIME)
        pWidgetRef.btnWatchOther:SetVisibility(VISIBLE)
    else   
        pWidgetRef.btnWatchOther:SetVisibility(COLLAPSED)
        local l10nContinue = UISetUtils.GetL10NTextByKey("BATTLE_RESULT_CONTINUE_PARAM")
        pWidgetRef.txtContinue:SetTimerStart(l10nContinue, false, GlobalVariableSystem:GetLocalTime() + BattleResultIni.tbBattleResult.nResultCountdown)
    end
end

local function OnWatchOtherClicked(self)
    UIUtils.ShowWaitingPacket()
    self.EventHelper:FireEvent(CommonEventDef.EV_REQUEST_CHANGE_WATCH_OTHER)
end

local function OnShowWatchOtherView(self, tbOther)
    UIUtils.HideWaitingPacket()
    UIManager:PushState(UIStateDef.StateName.UI_WATCH_BATTLE_STATE, { tbMateObj = tbOther }, true, true)
end

local function OnWatchOtherCountFinish(self)
    local bIsBattleEnd = WatchBattleSystem:IsBattleEnd()
    if not bIsBattleEnd then
        OnWatchOtherClicked(self)
    else   
        OnContinueClicked(self)
    end
end

local function OnContinueCountFinished(self)
    OnContinueClicked(self)
end

function UIFFABattleResult:OnLoad()
    self.pWidgetRef.bTopWindow = false
    self.PrefabHelper:BindPrefab(self.pWidgetRef.pbCutoutScreenAdapter)
end

function UIFFABattleResult:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnContinue.OnClicked, self, OnContinueClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnShare.OnClicked, self, OnShareRankClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnDeadPlayback.OnClicked, self, OnDeadPlaybackClicked)

    EventHelper:RegisterCppDelegate(pWidgetRef.btnWatchOther.OnClicked, self, OnWatchOtherClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.txtCountDown.OnCountDownFinished, self, OnWatchOtherCountFinish)
    EventHelper:RegisterCppDelegate(pWidgetRef.txtContinue.OnCountDownFinished, self, OnContinueCountFinished)

    EventHelper:RegisterEvent(ClientEventDef.EV_REFRESH_WATCH_MATE, self, OnShowWatchOtherView)
    EventHelper:RegisterEvent(CommonEventDef.EV_DUNGEON_GAME_OVER, self, OnBattleGameOver)

    for i = 1, TEAM_MEMBER_COUNT - 1 do
        EventHelper:RegisterCppDelegate(pWidgetRef["btnAdd0"..i].OnClicked, self, function() OnAddFriendClicked(self, i) end)
    end
end

function UIFFABattleResult:OnShow()
    self.OtherTeamMember = {}
    if not self.tbOpenArgs.bInLobby then
        self:PlayAnimation("animStart", 0, 1, EUMGSequencePlayMode.Forward, 1)
    end
    SetInfo(self)
    CheckWatchOther(self)
end

function UIFFABattleResult:OnExit()
    if self.tbDelayHandle then
        DelayTimer:ClearTimer(self.tbDelayHandle)
        self.tbDelayHandle = nil
    end
end

return UIFFABattleResult