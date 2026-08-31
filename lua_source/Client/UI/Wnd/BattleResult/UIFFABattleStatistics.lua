-----------------------------------------------------
--File Name    : UIFFABattleStatistics.lua
--Description  : FFA战斗统计界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIFFABattleStatistics = luaclass("UIFFABattleStatistics", WndBase)

local ScreenCaptureHelper = require("ScreenCaptureHelper")
local UISetUtils = require("UISetUtils")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local TutorialDungeonIni = require("TutorialDungeonIni")
local L10N = require("L10N")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local DelayTimer = require("DelayTimer")
-- local AvatarDataTable = require("AvatarDataTable")
-- local UIResourceDef = require("UIResourceDef")
-- local HumanDataTable = require("HumanDataTable")
-- local GenderTypeDefine = require("GenderTypeDefine")
local UITextDef = require("UITextDef")
local ScoreResDataTable = require("ScoreResDataTable")
local ProcedureTool = require("ProcedureTool")
local BattleStaticsCustomItemDataTable = require("BattleStaticsCustomItemDataTable")
local SelfListHelperNew = require("SelfListHelperNew")
local BattleResultIni = require("BattleResultIni")
local UIUtils = require("UIUtils")
-- local HeadIconHelper = require("HeadIconHelper")

local MAX_TEAM_MEMBER_COUNT = 4
local VISIBLE = ESlateVisibility.Visible
local HIT_TEST_IN_VISIBLE = ESlateVisibility.HitTestInvisible
local SELF_HIT_TEST_IN_VISIBLE = ESlateVisibility.SelfHitTestInvisible
local COLLAPSED = ESlateVisibility.Collapsed
local MIRROR_NO_MIRROR = ESlateBrushMirrorType.NoMirror
local MIRROR_HORIZONTAL = ESlateBrushMirrorType.Horizontal
local SHOT_DELAY = 0.2
local MEMBER_INFO_PADDINGS =
{
    [1] = Margin{Left = 100, Top = 0, Right = 0, Bottom = 0},
    [2] = Margin{Left = -290, Top = 0, Right = 0, Bottom = 0},
}
local SINGLE_MODE = 1

UIFFABattleStatistics.tbMemberResultPrefab = {}
UIFFABattleStatistics.tbMemberDetailPrefab = {}
UIFFABattleStatistics.bOpenDetail = false
UIFFABattleStatistics.tbDelayHandle = nil
UIFFABattleStatistics.pbFiveDimensionalGraph = nil
UIFFABattleStatistics.ListHelper = nil

local function IsTutorialDungeon()
    local nDungeonId = BattleGameModeSystem.nDungeonId
    if nDungeonId == TutorialDungeonIni.nDungeonId then
        return true
    end
    return false
end

local function SetMemberInfo(self, tbSortTeamMemberData)
    local tbMemberResultPrefab = self.tbMemberResultPrefab
    local nMemberCount = #tbSortTeamMemberData
    local bHideKillCount = IsTutorialDungeon()
    for k, v in ipairs(tbSortTeamMemberData) do
        local pbResult = tbMemberResultPrefab[k]
        if pbResult then
            pbResult:SetData(v, bHideKillCount)
            --两个队友时需要特殊处理一下ui的位置
            if nMemberCount == 2 then
                local pHorizontalBoxSlot = pbResult.pWidgetRef.Slot
                if pHorizontalBoxSlot then
                    pHorizontalBoxSlot:SetPadding(MEMBER_INFO_PADDINGS[k])
                end
            end
        end
    end
end

local function CheckCustomItemVisibleInMode(nMode, tbVisibleMode)
    if not tbVisibleMode then
        return true
    end
    for k, v in pairs(tbVisibleMode) do
        if nMode == v then
            return true
        end
    end
    return false
end

local function SetMemberDetailInfo(self, tbSortTeamMemberData, bTeamDead, nMVPPlayerId, nMode)
    --固定显示的统计选项
    local tbInfo = self.tbOpenArgs.tbTeamInfo
    local tbMemberDetailPrefab = self.tbMemberDetailPrefab
    local bMVP = false
    for k, v in ipairs(tbSortTeamMemberData) do
        bMVP = tbInfo.nMode ~= SINGLE_MODE and nMVPPlayerId == v.nPlayerId and tbInfo.bTeamDead
        local pbDetail = tbMemberDetailPrefab[k]
        if pbDetail then
            pbDetail:SetData(v, bTeamDead, bMVP)
        end
    end
    --可配置的统计选项
    local nSelfPlayerId = GamePlayerSelfHelper:Get().nPlayerId
    local tbAllCustomItems = BattleStaticsCustomItemDataTable:GetAllCustomItems()
    local tbCustomItemData = {}
    for k, v in ipairs(tbAllCustomItems) do
        --logdebug("k,v=",k, v.nId)
        if CheckCustomItemVisibleInMode(nMode, v.tbMode) then
            local tbItemData = {}
            tbItemData.tbTemplate = v
            tbItemData.tbValueList = {}
            local szParamName = v.szParamName
            for k1, v1 in ipairs(tbSortTeamMemberData) do
                if bTeamDead or v1.nPlayerId == nSelfPlayerId then
                    table.insert(tbItemData.tbValueList, v1[szParamName])
                else
                    table.insert(tbItemData.tbValueList, 0)
                end
            end
            table.insert(tbCustomItemData, tbItemData)
        end
    end 
    self.ListHelper:SetData(tbCustomItemData)
end


-- local function GetGenderRes(nAvatarId)
--     local tbAvatarData = AvatarDataTable:GetTemplate(nAvatarId)
--     if tbAvatarData == nil then
--         return UIResourceDef.GENDER_MALE
--     end
--     local tbHumanData = HumanDataTable:GetTemplate(tbAvatarData.nHumanId)
--     if tbHumanData == nil then
--         return UIResourceDef.GENDER_MALE
--     end
--     if tbHumanData.nGender == GenderTypeDefine.MALE then
--         return UIResourceDef.GENDER_MALE
--     else
--         return UIResourceDef.GENDER_FEMALE
--     end
-- end



local function SetInfo(self)
    local tbInfo = self.tbOpenArgs.tbTeamInfo
    if not tbInfo then
        return
    end
    local tbSortTeamMemberData = self.tbOpenArgs.tbSortTeamMemberData
    if not tbSortTeamMemberData then
        return
    end
    local tbSelfData = nil
    local nSelfPlayerId = GamePlayerSelfHelper:Get().nPlayerId
    local nCurPlayerId = self.tbOpenArgs.nSelfPlayerId

    for k, v in ipairs(tbSortTeamMemberData) do
        if (nCurPlayerId and v.nPlayerId == nCurPlayerId) or v.nPlayerId == nSelfPlayerId then
            tbSelfData = v
        end
    end
    if tbSelfData == nil then
        logerror("battle statistics not find self data: ", nCurPlayerId, nSelfPlayerId)
        return
    end
    SetMemberInfo(self, tbSortTeamMemberData)
    SetMemberDetailInfo(self, tbSortTeamMemberData, tbInfo.bTeamDead, tbInfo.nMVPPlayerId, tbInfo.nMode)
    local pWidgetRef = self.pWidgetRef
    local bInLobby = self.tbOpenArgs.bInLobby
    local bTutorialDungeon = IsTutorialDungeon()

    --五维图
    local tbDimensionalUnit = {tbSelfData.nDimensionalSurvival, tbSelfData.nDimensionalDamage,
    tbSelfData.nDimensionalKill, tbSelfData.nDimensionalAssist, tbSelfData.nDimensionalItem}
    self.pbFiveDimensionalGraph:OnRefresh(tbDimensionalUnit, tbInfo.nMode)
    local szScoreImg = ScoreResDataTable:GetImage(tbSelfData.nBattleScore)
    local pScoreIcon = szScoreImg:load()
    if pScoreIcon then
        UISetUtils.SetImageBrushRes(pWidgetRef.Image_1, pScoreIcon)
    else
        pWidgetRef.Image_1:SetVisibility(ESlateVisibility_Collapsed)
        logerror("UIFFABattleStatistics:pScoreIcon is nil, nBattleScore =", tbSelfData.nBattleScore)
    end
    --log("UIFFABattleStatistics:SetInfo,nRank,nKillCount,nSurvivalTime,nTotalPlayerCount=",nRank,nKillCount,nSurvivalTime,nTotalPlayerCount)


    --个人排名or队伍排名
    local l10Rank = nil
    if tbInfo.nMode ~= SINGLE_MODE and tbInfo.bTeamDead then
        l10Rank = L10N:Format(UISetUtils.GetL10NTextByKey("FFA_RESULT_TEAM_RANK"), tbInfo.nTeamRank, tbInfo.nTeamCount)
    else
        local nRank = tbSelfData.nPlayerRank
        if not nRank then
            nRank = 1
        end
        l10Rank = L10N:Format(UISetUtils.GetL10NTextByKey("FFA_RESULT_RANK"), nRank, tbInfo.nPlayerCount)
    end
    pWidgetRef.rtxtRank:SetText(l10Rank)

    local l10Back = UISetUtils.GetL10NTextByKey("FFA_RESULT_BUTTON_BACK")
    if not bInLobby then
        if bTutorialDungeon then
            pWidgetRef.cdtxtBack:SetText(UITextDef.COMMON_CONTINUE)
        else
            pWidgetRef.cdtxtBack:SetTimerStart(l10Back, false, GlobalVariableSystem:GetLocalTime() + BattleResultIni.tbBattleResult.nStatisticsCountdown)
        end
    else
        pWidgetRef.cdtxtBack:SetText(UITextDef.COMMON_RETURN)
    end

    -- pWidgetRef.imgScore:SetVisibility(bInLobby and COLLAPSED or SELF_HIT_TEST_IN_VISIBLE)
    -- pWidgetRef.txtScore:SetVisibility(bInLobby and COLLAPSED or SELF_HIT_TEST_IN_VISIBLE)
    -- pWidgetRef.cvsPlayerInfo:SetVisibility(bInLobby and SELF_HIT_TEST_IN_VISIBLE or COLLAPSED)
    pWidgetRef.cvsPlayerInfo:SetVisibility(COLLAPSED)
    pWidgetRef.imgBack:SetVisibility(bInLobby and SELF_HIT_TEST_IN_VISIBLE or COLLAPSED)
    -- pWidgetRef.btnFightContent:SetVisibility(bInLobby and COLLAPSED or VISIBLE)
    pWidgetRef.vbFight:SetVisibility(bInLobby and COLLAPSED or SELF_HIT_TEST_IN_VISIBLE)
    pWidgetRef.btnShareResult:SetVisibility(((nCurPlayerId and nCurPlayerId == nSelfPlayerId) or (not nCurPlayerId))
         and VISIBLE or COLLAPSED)
    pWidgetRef.btnShare:SetVisibility(((nCurPlayerId and nCurPlayerId == nSelfPlayerId) or (not nCurPlayerId))
         and VISIBLE or COLLAPSED)

    if not bInLobby then
        if bTutorialDungeon then
            pWidgetRef.ovlTotalScore:SetVisibility(ESlateVisibility_Collapsed)
            pWidgetRef.ovlFight:SetVisibility(ESlateVisibility_Collapsed)
            pWidgetRef.btnShareResult:SetVisibility(ESlateVisibility_Collapsed)
        else
            pWidgetRef.ovlTotalScore:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        end
    else
        pWidgetRef.ovlTotalScore:SetVisibility(ESlateVisibility_Collapsed)
    end

    if bInLobby then
        local tbOpenArgs = self.tbOpenArgs
        -- local szGender = GetGenderRes(tbOpenArgs.nAvatarId)
        -- UISetUtils.SetImageBrushRes(pWidgetRef.imgSex, szGender:load(), true)
    
        -- local szHead = HeadIconHelper:GetPlayerHeadIconResByAvatar(tbOpenArgs.nAvatarId)
        -- UISetUtils.SetImageBrushRes(pWidgetRef.imgPlayerAvatarIcon, szHead:load(), false, true, 210, 210)

        -- pWidgetRef.txtPlayerName:SetText(tbOpenArgs.szName)
        if tbOpenArgs.nExtraScore > 0  then
            --击杀boss结算
            pWidgetRef.txtResult:SetText(UISetUtils.GetL10NTextByKey("FFA_RESULT_KILL_BOSS"))
        else
            --吃鸡or失败
            if tbOpenArgs.nTeamRank == 1 then
                pWidgetRef.txtResult:SetText(UISetUtils.GetL10NTextByKey("FFA_RESULT_SUCCESS"))
            else
                pWidgetRef.txtResult:SetText(UISetUtils.GetL10NTextByKey("FFA_RESULT_FAIL"))
            end
        end
    else
        local l10Score = UISetUtils.GetL10NTextByKey("FFA_RESULT_SCORE")
        if tbSelfData.nGradeScore > 0 then
            l10Score = L10N:Format(l10Score, "+"..tbSelfData.nGradeScore)
        else
            l10Score = L10N:Format(l10Score, tbSelfData.nGradeScore)
        end
        pWidgetRef.txtScore:SetText(l10Score)
    end
end

local function OnBackClicked(self)
    if self.tbOpenArgs.bInLobby then
        self:CloseSelf()
    elseif IsTutorialDungeon() then
        ProcedureTool:EnterCreateRole({bNeedLoadMap = true})
    elseif not GlobalVariableSystem:IsWithLobby() then
        ProcedureTool:ReturnToStartGame()
    else
        BattleGameModeSystem:RequestQuitDungeon(BattleGameModeSystem.QUIT_REASON.QUIT_BUTTON)
    end
end

local function ShowDetail(self, bOpenDetail)
    local DetailVisible = bOpenDetail == true and SELF_HIT_TEST_IN_VISIBLE or COLLAPSED
    local InfoVisible = bOpenDetail == true and COLLAPSED or HIT_TEST_IN_VISIBLE
    local DetailMirror = self.bOpenDetail == true and MIRROR_NO_MIRROR or MIRROR_HORIZONTAL
    self.pWidgetRef.cvsDetail:SetVisibility(DetailVisible)
    self.pWidgetRef.Image_2:SetVisibility(DetailVisible)
    self.pWidgetRef.Image_3:SetVisibility(DetailVisible)
    self.pWidgetRef.Image_4:SetVisibility(DetailVisible)
    self.pWidgetRef.Image_5:SetVisibility(DetailVisible)
    self.pWidgetRef.hbxInfo:SetVisibility(InfoVisible)
    self.pWidgetRef.imgDetail.Brush.Mirroring = DetailMirror
end

local function OnBattleDetailClicked(self)
    self.bOpenDetail = not self.bOpenDetail
    ShowDetail(self, self.bOpenDetail)
end

local function OnScreenShotCaptureFinished(self, Width, Height, ShotTexture)
    local tbOpenArg =
    {
        Width = Width,
        Height = Height,
        ShotTexture = ShotTexture,
    }
    UIManager:SnapshotUI(false, {UIDef.UI_FFA_BATTLE_RESULT, UIDef.UI_FFA_BATTLE_STATISTICS})
    UIManager:OpenWnd(UIDef.UI_FFA_BATTLE_SHARE, tbOpenArg)
    UIManager:CloseWnd(UIDef.UI_FFA_BATTLE_RESULT)

    ShowDetail(self, self.bOpenDetail)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(VISIBLE)
    pWidgetRef.btnShare:SetVisibility(VISIBLE)
    if not self.tbOpenArgs.bInLobby and IsTutorialDungeon() then
        pWidgetRef.btnShareResult:SetVisibility(COLLAPSED)
    else
        pWidgetRef.btnShareResult:SetVisibility(VISIBLE)
    end
    pWidgetRef.btnBack:SetVisibility(VISIBLE)
    pWidgetRef.btnFightContent:SetVisibility(VISIBLE)
    pWidgetRef.imgDetail:SetVisibility(HIT_TEST_IN_VISIBLE)
    pWidgetRef.imgLogo:SetVisibility(COLLAPSED)
end

local function SnapShotUI(self, bOpenDetail)
    local pWidgetRef = self.pWidgetRef
    ShowDetail(self, bOpenDetail)
    pWidgetRef.btnShare:SetVisibility(COLLAPSED)
    pWidgetRef.btnShareResult:SetVisibility(COLLAPSED)
    pWidgetRef.btnBack:SetVisibility(COLLAPSED)
    pWidgetRef.btnFightContent:SetVisibility(COLLAPSED)
    pWidgetRef.imgDetail:SetVisibility(COLLAPSED)
    pWidgetRef.imgLogo:SetVisibility(HIT_TEST_IN_VISIBLE)
    UIManager:SnapshotUI(true, {UIDef.UI_FFA_BATTLE_RESULT, UIDef.UI_FFA_BATTLE_STATISTICS})
    local CameraShot = function()
        ScreenCaptureHelper.Capture(OnScreenShotCaptureFinished, self)
        self.tbDelayHandle = nil
    end

    self.tbDelayHandle = DelayTimer:DelayRun(CameraShot, SHOT_DELAY)
end

local function OnShareClicked(self)
    if self.tbDelayHandle then
        return
    end
    local bInLobby = self.tbOpenArgs.bInLobby
    if bInLobby then
        local tbParams = {}
        tbParams.tbTeamInfo = self.tbOpenArgs.tbTeamInfo
        tbParams.tbTeamMemberData = self.tbOpenArgs.tbSortTeamMemberData
        tbParams.bInLobby = bInLobby
        tbParams.nSelfPlayerId = self.tbOpenArgs.nSelfPlayerId
        self.pWidgetRef:SetVisibility(COLLAPSED)
        UIManager:OpenWnd(UIDef.UI_FFA_BATTLE_RESULT, tbParams)
    end
    SnapShotUI(self, false)
end

local function OnShareDetailClicked(self)
    if self.tbDelayHandle then
        return
    end
    SnapShotUI(self, true)
end

function UIFFABattleStatistics:OnLoad()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.bTopWindow = false
    self.tbMemberResultPrefab = {}
    self.tbMemberDetailPrefab = {}
    local PrefabHelper = self.PrefabHelper
    PrefabHelper:BindPrefab(pWidgetRef.pbCutoutScreenAdapter)
    self.pbFiveDimensionalGraph = PrefabHelper:BindPrefab(pWidgetRef.pbFiveDimensionalGraph)
    for i = 1, MAX_TEAM_MEMBER_COUNT do
        local pbMemberResult = PrefabHelper:BindPrefab(pWidgetRef["pbMemberResult0"..i])
        table.insert(self.tbMemberResultPrefab, pbMemberResult)
    end
    for i = 1, MAX_TEAM_MEMBER_COUNT do
        local pbMemberDetail = PrefabHelper:BindPrefab(pWidgetRef["pbMemberDetail0"..i])
        table.insert(self.tbMemberDetailPrefab, pbMemberDetail)
    end
    self.ListHelper = SelfListHelperNew()
    self.ListHelper:Init(self, pWidgetRef.kmList)
end

function UIFFABattleStatistics:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnBack.OnClicked, self, OnBackClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnShare.OnClicked, self, OnShareClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnShareResult.OnClicked, self, OnShareDetailClicked)
    if not self.tbOpenArgs.bInLobby then
        EventHelper:RegisterCppDelegate(pWidgetRef.btnFightContent.OnClicked, self, OnBattleDetailClicked)
    end
    EventHelper:RegisterCppDelegate(pWidgetRef.cdtxtBack.OnCountDownFinished, self, OnBackClicked)
end

function UIFFABattleStatistics:OnShow()
    UIUtils.BottomMenuHide(true)
    SetInfo(self)
    self.bOpenDetail = self.tbOpenArgs.bOpenDetail
    ShowDetail(self, self.bOpenDetail)
    if self.tbOpenArgs.bInLobby then
        self.pWidgetRef.hbButton.Slot:SetPosition(Vector2D{X=-140, Y=-100})
    else
        self.pWidgetRef.hbButton.Slot:SetPosition(Vector2D{X=-140, Y=-75})
    end
end

function UIFFABattleStatistics:OnExit()
    if self.tbDelayHandle then
        DelayTimer:ClearTimer(self.tbDelayHandle)
        self.tbDelayHandle = nil
    end
end

function UIFFABattleStatistics:OnHide()
    UIUtils.BottomMenuHide(false)
end

function UIFFABattleStatistics:OnDestroy()
    self.ListHelper:Uninit()
end
return UIFFABattleStatistics