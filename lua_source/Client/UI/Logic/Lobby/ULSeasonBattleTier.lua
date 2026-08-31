local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULSeasonBattleTier = luaclass("ULSeasonBattleTier", UILogicBase)

local UIManager = require("UIManager")
local SelfListHelperNew = require("SelfListHelperNew")
local UIDef = require("UIDef")
local SeasonSystem = require("SeasonSystem")
local BattleTierDataTable = require("BattleTierDataTable")
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
local SeasonIni = require("SeasonIni")
local UISetUtils = require("UISetUtils")
local BattleTierRewardDataTable = require("BattleTierRewardDataTable")
local SeasonDataTable = require("SeasonDataTable")
local ClientEventDef = require("ClientEventDef")
local ItemSystem = require("ItemSystem")
local ItemDataTable = require("ItemDataTable")
local UIUtils = require("UIUtils")
local Timer = require("Timer")
local L10N = require("L10N")
local UITextDef = require("UITextDef")
local Proto = require("ClientProtoNames")
local LobbySystem = require("LobbySystem")
local LobbySubTypeDef = require("LobbySubTypeDef")
local AwardDataTable = require("AwardDataTable")
local BattleTierRewardEffectDataTable = require("BattleTierRewardEffectDataTable")
local TimeUtil = require("TimeUtil")
local UIResourceDef = require("UIResourceDef")

local GetTextByKey = UISetUtils.GetTextByKey
local MAX_DATE_LEN = 2
local TIMEFORMAT = {
    GetTextByKey("COMMON_TIME_DAY"),
    GetTextByKey("COMMON_TIME_HOUR"),
    GetTextByKey("COMMON_TIME_MINUTE"),
    GetTextByKey("COMMON_TIME_SECOND"),
}
local MILESTONE_REFRESH_INTERVAL = 0.2
local MILESTONE_INIT_DELAY = 0.1
local ONE_DAY = 24 * 60 * 60
local EFFECT_IMAGES = {
    "imgGreen",
    "imgBlue",
    "imgPurple",
    "imgOrange"
}

ULSeasonBattleTier.ListHelper = nil

ULSeasonBattleTier.pbNextMileStoneReward = nil
ULSeasonBattleTier.pbAwardDesc = nil
ULSeasonBattleTier.tbMilestoneOffset = nil
ULSeasonBattleTier.tbMilestoneTimer = nil
ULSeasonBattleTier.nRightTier = nil
ULSeasonBattleTier.tbTimer = nil
ULSeasonBattleTier.bLoadedAwards = nil
ULSeasonBattleTier.tbSelectedData = nil
ULSeasonBattleTier.tbActivateParam = nil

ULSeasonBattleTier.bCanDrag = nil
ULSeasonBattleTier.bIsDrag = nil
ULSeasonBattleTier.tbLastPos = nil
ULSeasonBattleTier.tbCurPos = nil

-- 每隔几个战阶是一个大的战阶，最右侧需要显示大战阶
local function GetMilestoneTiers()
    local nInterval = SeasonIni.tbBattlePass.nBattleTierInterval
    local tbBattlePass = SeasonSystem:GetComponent():GetBattlePass()
    local tbTier = {}
    for i = 1, tbBattlePass.battle_max_tier do
        if math.fmod(i, nInterval) == 0 then
            table.insert(tbTier, i)
        end
    end
    return tbTier
end

-- 很hack 但是没有更好的接口提供当前什么item进入视野，暂时这么处理
local function InitMilestoneScrollOffset(self)
    if self.tbMilestoneOffset ~= nil then
        return
    end
    self.tbMilestoneOffset = { }
    local tbMilestonesData = GetMilestoneTiers()
    for i, v in ipairs(tbMilestonesData) do
        local tbMilestoneData = {
            nBattleTierLevel = v,
        }
        table.insert( self.tbMilestoneOffset,  tbMilestoneData)
    end
end

local function CheckNextMilestone(self)
    local nViewingItemIndex = self.ListHelper:GetViewingItemIndexFromBottom()
    for i, v in ipairs(self.tbMilestoneOffset) do
        local nNextLevel = v.nBattleTierLevel
        if nViewingItemIndex < nNextLevel or i == #self.tbMilestoneOffset then
            if self.nRightTier == nil or self.nRightTier ~= nNextLevel then
                local tbRewardData = BattleTierRewardDataTable:GetTemplate(nNextLevel)
                if self.pbNextMileStoneReward.tbData == nil or self.pbNextMileStoneReward.tbData ~= tbRewardData then 
                    self.pbNextMileStoneReward:OnRefresh(tbRewardData, true)
                    self.pbNextMileStoneReward.tbData = tbRewardData
                end
            end
            break
        end
    end

    if self.tbMilestoneTimer == nil then
        self.tbMilestoneTimer = self.TimerHelper:NewTimerMethod(self, CheckNextMilestone, MILESTONE_REFRESH_INTERVAL, true)
    end
end

local function RefreshReward(self)
    if self.bLoadedAwards then
        return
    end
    -- 奖励列表
    local tbTierReward = BattleTierRewardDataTable:GetContainer()

    self.ListHelper:SetData(tbTierReward)
end

local function RefreshBattleTier(self)
    local pWidgetRef = self.pWidgetRef
    local SeasonComponent = SeasonSystem:GetComponent()
    local tbBattlePass = SeasonComponent:GetBattlePass()

    local tbTierData = BattleTierDataTable:GetTemplate(tbBattlePass.battle_tier)
    local Visible, Collapsed = ESlateVisibility_Visible, ESlateVisibility_Collapsed

    -- 战阶
    pWidgetRef.txtBattleTier:SetText(tbBattlePass.battle_tier)
    -- 战星
    pWidgetRef.txtBattleStar:SetText(string.format("%d/%d", tbBattlePass.battle_star, tbTierData.nBattleStar))
    pWidgetRef.progressBattleStar:SetPercent(tbBattlePass.battle_star / tbTierData.nBattleStar)
    -- 进阶战阶，购买战阶按钮
    if not SeasonComponent:IsPassActive() then
        pWidgetRef.imgLock:SetVisibility(Visible)
        pWidgetRef.imgBlackLock:SetVisibility(Visible)
        pWidgetRef.txtBuy:SetText(UISetUtils.GetL10NTextByKey("LOBBY_SEASON_BUY_PASS"))
    else
        pWidgetRef.imgLock:SetVisibility(Collapsed)
        pWidgetRef.imgBlackLock:SetVisibility(Collapsed)
        pWidgetRef.txtBuy:SetText(UISetUtils.GetL10NTextByKey("LOBBY_SEASON_BUY_TIER"))
        -- if BattleTierDataTable:GetTemplate(tbBattlePass.battle_tier + 1) ~= nil then
        --     self.Owner:PlayAnimation("anim_BuyTier", 0, 0, EUMGSequencePlayMode.Forward, 1)
        -- else
        --     self.Owner:StopAnimation("anim_BuyTier")
        -- end
    end
end

local function DestroyTimer(self)
    if self.tbTimer ~= nil then
        self.tbTimer:Clear()
        self.tbTimer = nil
    end
end

local function ShowOpening(self)
    self.pWidgetRef.txtSeasonTime:SetText(UISetUtils.GetL10NTextByKey("SEASON_NEW_OPENING"))
end

local function ShowHeroEffect(self, bShow)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.img_FxHero_Big:SetVisibility(bShow and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Collapsed)
    pWidgetRef.par_FxHeroSlowParticles_Big:SetVisibility(bShow and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Collapsed)
end

local function OnSelectedItem(self, nTemplateId, nSelectIndex, nTier, nEffectId, bAdvance, bForce)
    if self.nSelectId ~= nil and not bForce then 
        return
    end
    local Visible, Collapsed = ESlateVisibility_Visible, ESlateVisibility_Collapsed
    local pWidgetRef = self.pWidgetRef
    if self.nSelectId == nil then
        pWidgetRef.vbHero:SetVisibility(Collapsed)
        pWidgetRef.pbAwardDesc:SetVisibility(Collapsed)
        pWidgetRef.olItem:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    end
    self.tbSelectedData = {nTemplateId = nTemplateId, 
        nSelectIndex = nSelectIndex, 
        nTier = nTier, 
        nEffectId = nEffectId, 
        bAdvance = bAdvance, 
        bForce = bForce}
    self.nSelectId = nTemplateId
    self.pbAwardDesc:SetSelectedData(self.tbSelectedData)
    self.nEffectId = nEffectId
    ShowHeroEffect(self, false)

    local tbItemTemplate = ItemSystem:GetItemTemplate(nTemplateId or 0)

    if tbItemTemplate == nil then
        pWidgetRef.olItem:SetVisibility(Collapsed)
        return
    end
    self.pbAwardDesc:OnRefresh(tbItemTemplate)
    local fnHideEffect = function()
        for i, v in ipairs(EFFECT_IMAGES) do
            pWidgetRef[v]:SetVisibility(Collapsed)
        end
    end
    if LobbySystem:GetSub(LobbySubTypeDef.SEASON):SetViewTarget(tbItemTemplate) then
        self.bCanDrag = true
        pWidgetRef.olItem:SetVisibility(Collapsed)
        fnHideEffect()
    else
        self.bCanDrag = false
        local tbItemResTemplate = ItemDataTable:GetResTemplate(nTemplateId)
        local szIconPath = tbItemResTemplate.szIconPath
        UISetUtils.SetImageBrushRes(pWidgetRef.imgSelectedItem, szIconPath:load())

        pWidgetRef.olItem:SetVisibility(Visible)
        if nEffectId > 0 and nEffectId <= #EFFECT_IMAGES then
            local SelfHitTestInvisible = ESlateVisibility.SelfHitTestInvisible
            pWidgetRef[EFFECT_IMAGES[nEffectId]]:SetVisibility(SelfHitTestInvisible)
        else
            fnHideEffect()
        end
        local szGradeIcon = UIResourceDef.ITEM_COLOR_GRADE_BG[tbItemTemplate.nGrade]
        if szGradeIcon ~= nil then
            UISetUtils.SetImageBrushRes(pWidgetRef.imgPackItemBg, szGradeIcon:load())
        end
    end
end

local function DefaultSelectItem(self, tbData)
    local SeasonComponent = SeasonSystem:GetComponent()
    local bActive = SeasonComponent:IsPassActive()
    local pWidgetRef = self.pWidgetRef
    if tbData then
        pWidgetRef.vbHero:SetVisibility(ESlateVisibility_Collapsed)
        OnSelectedItem(self, tbData.nTemplateId, tbData.nSelectIndex, tbData.nTier, tbData.nEffectId, tbData.bAdvance, tbData.bForce)
        self.EventHelper:FireEvent(ClientEventDef.EV_ON_SELECT_AWARD, tbData.nTemplateId, tbData.nSelectIndex, tbData.nTier, tbData.nEffectId, tbData.bAdvance, tbData.bForce)
    else
        if bActive then
            pWidgetRef.vbHero:SetVisibility(ESlateVisibility_Collapsed)
    
            local tbBattlePass = SeasonComponent:GetBattlePass()
            local nTier = BattleTierRewardDataTable:GetNextSelectedTier(tbBattlePass.battle_tier)

            local tbRewardData = BattleTierRewardDataTable:GetTemplate(nTier)
            local tbAdvanceItems = AwardDataTable:GetAwardItem(tbRewardData.nHeroAwardId)
            local tbAdvanceItemEffects = BattleTierRewardEffectDataTable:GetHeroAwardEffectTemplate(nTier)
            if tbAdvanceItems ~= nil and #tbAdvanceItems > 0 then          
                local fnGetEffectId = function(nIndex)
                    local nEffectId = 0
                    if tbAdvanceItemEffects == nil then
                        return nEffectId
                    end
                    for i, v in ipairs(tbAdvanceItemEffects) do
                        if nIndex == i then
                            nEffectId = v.nEffect
                            break
                        end
                    end
                    return nEffectId
                end       
                local nEffectId = fnGetEffectId(1)
                OnSelectedItem(self, tbAdvanceItems[1].nItemId, nil, nil, nEffectId, true, true)
                self.EventHelper:FireEvent(ClientEventDef.EV_ON_SELECT_AWARD, tbAdvanceItems[1].nItemId, 1, nTier, nEffectId, true, true)
            end
        else
            pWidgetRef.vbHero:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
            pWidgetRef.pbAwardDesc:SetVisibility(ESlateVisibility_Collapsed)
            pWidgetRef.olItem:SetVisibility(ESlateVisibility_Collapsed)
            ShowHeroEffect(self, true)
        end
    end
end

local function TimeToDHMSStr(nTime)
    local nDay, nHour, nMin = TimeUtil.TimeToDHMS(nTime)
    local tbDate = {nDay, nHour, nMin}

    local nCount = 0
    local szRet = ""
    for i, value in ipairs(tbDate) do
        if value > 0 then
            szRet = szRet..(value..TIMEFORMAT[i])
            nCount = nCount + 1
            if nCount >= MAX_DATE_LEN then
                break
            end 
        end
    end 

    -- 只有时间小于1小时时，才显示秒数
    local bStartTimer = nDay == 0 and nHour == 0

    return szRet, bStartTimer
end

local function RefreshUI(self)
    local pWidgetRef = self.pWidgetRef
    local SeasonComponent = SeasonSystem:GetComponent()
    local tbBattlePass = SeasonComponent:GetBattlePass()
    if tbBattlePass == nil then
        pWidgetRef.cpPanel:SetVisibility(ESlateVisibility.Collapsed)
        UIUtils.ShowLoadingDialog()
        return
    end
    local nSeasonId = SeasonComponent:GetSeasonId()
    local nSeasonStartTime = SeasonComponent:GetStartTime()

    RefreshBattleTier(self)
    RefreshReward(self)

    -- 倒计时
    local nStatus = SeasonComponent:GetNewSeasonStatus()
    local fnShowSeasonTime = function(nTime)
        local nSeasonRemainTime = nTime - GlobalVariableSystem_C:GetServerTimeUtc()     
        if nSeasonRemainTime > 0 then
            local szRemainTime, bStartTimer = TimeToDHMSStr(nSeasonRemainTime)   
            if bStartTimer then
                pWidgetRef.txtSeasonTime:StartTimer(nSeasonRemainTime, 1, TIMEFORMAT, EMinTimeUnit.Second)
            else
                pWidgetRef.txtSeasonTime:SetText(szRemainTime)
            end
        else
            ShowOpening(self)
            pWidgetRef.txtSeasonTimeTitle:SetText(UISetUtils.GetL10NTextByKey("SEASON_TIME_TO_OPENING"))
        end
    end 
    if nStatus == Proto.PlayerSeasonStatus.RUNNING then
        local tbSeasonData = SeasonDataTable:GetTemplate(nSeasonId)
        local nTime = tbSeasonData.nDurationDay * ONE_DAY + nSeasonStartTime

        fnShowSeasonTime(nTime)
        pWidgetRef.txtSeasonTimeTitle:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("SEASON_TIME_TO_CLOSING"), tbSeasonData.l10nName))
    else
        fnShowSeasonTime(nSeasonStartTime)
        pWidgetRef.txtSeasonTimeTitle:SetText(UISetUtils.GetL10NTextByKey("SEASON_TIME_TO_OPENING"))
    end
end

local function OnCompleteSeason(self)
    ShowOpening(self)
end

local function RefreshSeasonPass(self)
    self.bLoadedAwards = false
    RefreshBattleTier(self)
    RefreshReward(self)
    if self.nSelectId == nil then
        DefaultSelectItem(self)
    end
end

local function OnClickedAdvanceBattlePass(self)
    local SeasonComponent = SeasonSystem:GetComponent()
    local tbBattlePass = SeasonComponent:GetBattlePass()
    if not SeasonComponent:IsPassActive() then
        -- 进阶战阶
        UIManager:OpenWnd(UIDef.UI_SEASON_BATTLEPASS_ADVANCE)
    else
        if BattleTierDataTable:GetTemplate(tbBattlePass.battle_tier + 1) ~= nil then
            -- 购买战阶
            UIManager:OpenWnd(UIDef.UI_SEASON_BATTLE_TIER_BUY)
        else
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("SEASON_BUY_TIER_FULL"))
        end
    end
end

local function OnClickedChallenge(self)
    local SeasonComponent = SeasonSystem:GetComponent()
    local nStatus = SeasonComponent:GetNewSeasonStatus()
    if nStatus ~= Proto.PlayerSeasonStatus.RUNNING then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("SEASON_CHALLENGE_NO_OPEN"))
    else
        UIManager:OpenWnd(UIDef.UI_SEASON_CHALLENGE)
    end    
end

local function OnClickedGetAward(self)
    local tbPass = SeasonSystem:GetComponent():GetBattlePass()
    local bGeted = true
    for i = 1, tbPass.battle_tier do
        if tbPass.battle_tier_award_status[i] <= 0 then
            bGeted = false
            break
        end
    end
    if not bGeted then
        SeasonSystem:RequestReceiveAllBattleTierAward()
    else
        UIUtils.ShowToast(UITextDef.BATTLE_TIER_LEVEL_AWARD_RECEIVED)
    end
end

local function OnMouseButtonDown(self, pGeometry, pMouseEvent)
    if self.bCanDrag then
        self.bIsDrag = true
        self.tbLastPos = KismetInputLibrary.PointerEvent_GetScreenSpacePosition(pMouseEvent)
    end
    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseMove(self, pGeometry, pMouseEvent)
    if self.bIsDrag then
        self.tbCurPos = KismetInputLibrary.PointerEvent_GetScreenSpacePosition(pMouseEvent)
        LobbySystem:GetSub(LobbySubTypeDef.SEASON):RotateActor((self.tbCurPos.X - self.tbLastPos.X) * 0.5)
        self.tbLastPos = self.tbCurPos
    end

    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseButtonUp(self, pGeometry, pMouseEvent)
    self.bIsDrag = nil
    self.tbLastPos = nil
    self.tbCurPos = nil

    return WidgetBlueprintLibrary.Handled()
end

local function InitList(self)
    local tbBattlePass = SeasonSystem:GetComponent():GetBattlePass()
    if tbBattlePass ~= nil then
        local ESelfHitTestInvisible = ESlateVisibility.SelfHitTestInvisible
        local ECollapsed = ESlateVisibility.Collapsed
        local olNext = self.pWidgetRef.olNext
        if self.tbActivateParam then
            self.ListHelper:ScrollToIndexCenter(self.tbActivateParam.nTier)
        else
            self.ListHelper:ScrollToIndexCenter(tbBattlePass.battle_tier)
        end
        olNext:SetVisibility(ECollapsed)
        local fnInit = function()
            InitMilestoneScrollOffset(self)
            CheckNextMilestone(self)
        end
        fnInit()
        self.tbMilestoneTimer = self.TimerHelper:NewTimerMethod(self,
            function()
                self.TimerHelper:ClearTimer(self.tbMilestoneTimer)
                self.tbMilestoneTimer = nil
                olNext:SetVisibility(ESelfHitTestInvisible)
            end,
            MILESTONE_INIT_DELAY, false)
    end 
end

local function OnRecvSeasonData(self)
    self.pWidgetRef.cpPanel:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    RefreshUI(self)
    InitList(self)
    UIUtils.HideLoadingDialog()
end

local function OnRecvSeasonBattleTierAward(self, nTier)
    if nTier == nil then
        RefreshReward(self)
    end
end

function ULSeasonBattleTier:OnLoad()
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    self.pbNextMileStoneReward = PrefabHelper:BindPrefab(pWidgetRef.pbNextMileStoneReward,
    UIDef.UP_SEASON_BATTLETIER_LISTITEM)
    -- self.pbNextMileStoneReward:HideBackImage()

    self.ListHelper = SelfListHelperNew()
    self.ListHelper:Init(self, pWidgetRef.listRewardNew)

    self.pbAwardDesc = PrefabHelper:BindPrefab(pWidgetRef.pbAwardDesc, UIDef.UP_SEASON_AWARD_DESC)
    self.pbAwardDesc.Owner = UIDef.UI_SEASON_BATTLEPASS
end

function ULSeasonBattleTier:OnShow()
    -- 奖励默认滚动位置
    InitList(self)     

    -- self.pWidgetRef.olItem:SetVisibility(ESlateVisibility_Collapsed)
end

function ULSeasonBattleTier:OnDestroy()
    DestroyTimer(self)
    self.ListHelper:Uninit()
    self.ListHelper = nil
    self.pbNextMileStoneReward = nil
    self.nSelectId = nil
    self.tbSelectedData = nil
    self.tbActivateParam = nil
end

function ULSeasonBattleTier:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAdvanceBattlePass.OnClicked,  self, OnClickedAdvanceBattlePass)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnChallenge.OnClicked,  self, OnClickedChallenge)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnGetAward.OnClicked,  self, OnClickedGetAward)
    EventHelper:RegisterCppDelegate(pWidgetRef.txtSeasonTime.OnCompleteTimer, self, OnCompleteSeason)

    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_SEASON_PASS, self, RefreshSeasonPass)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SELECT_AWARD, self, OnSelectedItem)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_GET_SEASON_DATA, self, OnRecvSeasonData)
    EventHelper:RegisterEvent(ClientEventDef.EV_SEASON_BATTLE_TIER_AWARD, self, OnRecvSeasonBattleTierAward)

    EventHelper:RegisterCppDelegate(pWidgetRef.bdrActorListener.OnMouseButtonDownEvent, self, OnMouseButtonDown)
    EventHelper:RegisterCppDelegate(pWidgetRef.bdrActorListener.OnMouseMoveEvent, self, OnMouseMove)
    EventHelper:RegisterCppDelegate(pWidgetRef.bdrActorListener.OnMouseButtonUpEvent, self, OnMouseButtonUp)
end

function ULSeasonBattleTier:Activate(tbParam)
    RefreshUI(self)
    self.bLoadedAwards = false
    self.tbActivateParam = tbParam
    DefaultSelectItem(self, tbParam)
    if self.tbTimer == nil then
        self.tbTimer = Timer.NewTimerMethod(self, RefreshUI, 60, true)
    end  
end

function ULSeasonBattleTier:Deactivate()
    DestroyTimer(self)
    self.nSelectId = nil
    self.tbActivateParam = nil
    self.tbSelectedData = nil
end

return ULSeasonBattleTier