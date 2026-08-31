-----------------------------------------------------
--File Name    : ULPlayerStatusPanel.lua
--Author       : Song Fuhao
--Create Time  : 2019-01-10
--Description  : 用于管理当前玩家状态显示（血量、能量等）
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULPlayerStatusPanel = luaclass("ULPlayerStatusPanel", UILogicBase)

local PropUtil = require("PropUtil")
local MathUtil = require("MathUtil")
local HeadHpIni = require("HeadHpIni")
local UISetUtils = require("UISetUtils")
local ShipDataTable = require("ShipDataTable")
local ClientEventDef = require("ClientEventDef")
local CommonEventDef = require("CommonEventDef")
local SelfEventHelper = require("SelfEventHelper")
local ConsumableItemDef = require("ConsumableItemDef")
local ShipMoraleDataTable = require("ShipMoraleDataTable")
local HumanMoraleDataTable = require("HumanMoraleDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemSystemHelper = require("BattleItemSystemHelper")

local DEFAULT_HP_LEVEL = -1
local MAX_EP_IMAGE_PHASE = 4
local MAX_EP_BUF_COUNT = 2
local EP_SPLIT_WIDGET_NAME = "sldrEPSplit0"

ULPlayerStatusPanel.nDamageInRecovering = 0
ULPlayerStatusPanel.tbConsumableList = nil
ULPlayerStatusPanel.tbEpSplitWidget = nil
ULPlayerStatusPanel.nCurrentHpLevel = DEFAULT_HP_LEVEL
ULPlayerStatusPanel.tbMoraleBufs = nil

local nLastHpPercent = 1

local function LOG(...)
    log("[ULPlayerStatusPanel]", ...)
end

local function InitHpBarParam(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.pgbHp.AnimDuration = HeadHpIni.nHpBarAnimTime
    pWidgetRef.pgbHp.TopAnimDuration = HeadHpIni.nHpBarTopAnimTime
    pWidgetRef.pgbHp.BeforeMiddleAnimDuration = HeadHpIni.nHpBarMidWaitTime
end

local function GetCurrentHpLevel(nHpPercent)
    if not GamePlayerSelfHelper:Get():IsDying() then
        local tbHpLevelPercents = HeadHpIni.tbUiHpColors.tbHpLevelPercents
        for i,v in ipairs(tbHpLevelPercents) do
            if (nHpPercent >= v) or (math.abs(nHpPercent - v) < 0.0001) then
                return i
            end
        end
    end
    return DEFAULT_HP_LEVEL
end

local function OnHpChanged(self, nHp, nMaxHp, nHpPercent, bShieldAnim)
    LOG("OnHpChanged before", nHp, nMaxHp, nHpPercent)
    local PropertyComponent = GamePlayerSelfHelper:Get():GetCurrentPropertyComponent()
    if PropertyComponent:GetIsDead() then
        nHp = 0
        nHpPercent = 0
    else
        nHp = math.ceil(nHp or PropertyComponent:GetHp())
        nHpPercent = nHpPercent or PropertyComponent:GetHpPercent()
    end
    nMaxHp = math.ceil(nMaxHp or PropertyComponent:GetMaxHp())
    LOG("OnHpChanged after", nHp, nMaxHp, nHpPercent)

    local pWidgetRef = self.pWidgetRef
    pWidgetRef.pgbHp:SetPercent(nHpPercent, (nHpPercent <= nLastHpPercent) and (not bShieldAnim)) -- 动态设bWithAnim是为了解决KMProgressBar在血量减到0到重伤的一瞬间,血条会涨的bug
    nLastHpPercent = nHpPercent
    pWidgetRef.txtHp:SetText(nHp.."/"..nMaxHp)

    local nHpLevel = GetCurrentHpLevel(nHpPercent)
    LOG("nHpLevel =", nHpLevel)
    local tbHpLevelBgOpacities = HeadHpIni.tbUiHpColors.tbHpLevelBgOpacities
    local tbHpLevelColors = HeadHpIni.tbUiHpColors.tbHpLevelColors
    if self.nCurrentHpLevel ~= nHpLevel then
        self.nCurrentHpLevel = nHpLevel
        LOG("set nCurrentHpLevel =", self.nCurrentHpLevel)
        if nHpLevel == DEFAULT_HP_LEVEL then
            -- pWidgetRef.pgbHp:SetFillColorAndOpacity(KMUMGLibrary.GetLinearColorFromHex(HeadHpIni.tbUiHpColors.szDyingHpColor))
            pWidgetRef.pgbHp:SetTopImageTint(KMUMGLibrary.GetSlateColorFromHex(HeadHpIni.tbUiHpColors.szDyingHpColor))
            pWidgetRef.imgHpBg:SetRenderOpacity(HeadHpIni.tbUiHpColors.nDyingHpBgOpacity)
        else
            -- pWidgetRef.pgbHp:SetFillColorAndOpacity(KMUMGLibrary.GetLinearColorFromHex(tbHpLevelColors[nCurrentHpLevel]))
            pWidgetRef.pgbHp:SetTopImageTint(KMUMGLibrary.GetSlateColorFromHex(tbHpLevelColors[nHpLevel]))
            pWidgetRef.imgHpBg:SetRenderOpacity(tbHpLevelBgOpacities[nHpLevel])
        end
    end
end

local function OnMoralePhaseChanged(self)
    local tbPlayer = GamePlayerSelfHelper:Get()
    local tbBufIcons
    if tbPlayer:IsShip() then
        tbBufIcons = tbPlayer.ShipMoraleComponent:GetPhaseIcon()
    else
        tbBufIcons = tbPlayer.HumanMoraleComponent:GetPhaseIcon()
    end
    if self.tbMoraleBufs ~= tbBufIcons then
        self.tbMoraleBufs = tbBufIcons
        local nCurBufCount = self.tbMoraleBufs ~= nil and #self.tbMoraleBufs or 0

        local SelfHitTestInvisible, Hidden = ESlateVisibility.SelfHitTestInvisible, ESlateVisibility.Hidden
        local pWidgetRef = self.pWidgetRef
        for i = 1, MAX_EP_BUF_COUNT do
            local img = pWidgetRef["imgEpBuf"..i]
            if i <= nCurBufCount then
                img:SetVisibility(SelfHitTestInvisible)
                UISetUtils.SetImageBrushRes(img, self.tbMoraleBufs[i]:load())
            else
                img:SetVisibility(Hidden)
            end
        end
    end
end

local function OnEpChanged(self, _, _, nEpPercent)
    nEpPercent = nEpPercent or GamePlayerSelfHelper:Get():GetCurrentPropertyComponent():GetEpPercent()
    self.pWidgetRef.pgbEp:SetPercent(nEpPercent)
    if nEpPercent <= 0 then
        self.pWidgetRef.ovlEp:SetVisibility(ESlateVisibility.Hidden)
    else
        self.pWidgetRef.ovlEp:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end

    OnMoralePhaseChanged(self)
end

local function OnIsDyingChanged(self)
    OnHpChanged(self)
end

local function OnPawnDead(self, tbPlayer)
    if tbPlayer == GamePlayerSelfHelper:Get() then
        OnHpChanged(self)
    end
end

local function GetEpPhaseList(self)
    local tbEpPhaseList = {}
    local tbPlayer = GamePlayerSelfHelper:Get()
    if tbPlayer:IsHuman() then
        local nPhaseCount = HumanMoraleDataTable:GetPhaseCount()
        for i=1,nPhaseCount do
            tbEpPhaseList[i] = HumanMoraleDataTable:GetMoralePhase(i).nMorale
        end
    else
        local nShipTemplateId = tbPlayer:GetShipTemplateId()
        local tbShipTemplate = ShipDataTable:GetTemplate(nShipTemplateId)
        local nMoralePhaseId = tbShipTemplate.nMoralePhaseId
        local nPhaseCount = ShipMoraleDataTable:GetMoralePhaseCount(nMoralePhaseId)
        for i=1,nPhaseCount do
            local tbShipMoraleTemplate = ShipMoraleDataTable:GetMoralePhase(nMoralePhaseId, i)
            tbEpPhaseList[i] = tbShipMoraleTemplate.nMorale
        end
    end
    return tbEpPhaseList
end

local function RefreshEpPhase(self)
    local tbEpPhaseList = GetEpPhaseList(self)
    local nMaxEp = GamePlayerSelfHelper:Get():GetCurrentPropertyComponent():GetMaxEp()
    local nNextValidPhaseIndex = 1
    for i,nMorale in ipairs(tbEpPhaseList) do
        if nMorale > 0 and nMorale < nMaxEp then
            local pEpSplitWidget = self.tbEpSplitWidget[nNextValidPhaseIndex]
            assert(pEpSplitWidget, "Ep phase count is too many.")
            nNextValidPhaseIndex = nNextValidPhaseIndex + 1
            pEpSplitWidget:SetValue(MathUtil.Clamp(nMorale, 0, nMaxEp) / nMaxEp)
            pEpSplitWidget:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        end
    end
    for i=nNextValidPhaseIndex,#self.tbEpSplitWidget do
        self.tbEpSplitWidget[i]:SetVisibility(ESlateVisibility.Collapsed)
    end
end

--------------------------------------------------
-- 吃药恢复显示相关逻辑 Begin

--[[
    获取当前目标恢复的血量百分比
    遍历所有已经吃下的药和正在吃的药，获取相关药物配置，按照下方公式计算即可，但需要满足部分前提：
    前提1：不会出现吃了直接回复药之后，继续吃回复部分血量的药
    nPersistentPercentSum   计算所有可累加的药的总回复值
    nMaxImmediatePercent    计算所有直接回复的药的最大值
    nMinStartPercent        取所有药吃的那一刻血量的最小值
    nMaxHpPercentLimit      取所有药回复限制的最大值
    nTotalDamagePercent     取吃药期间受到的伤害总和

    当前预计回复血量百分比 = math.min(math.max(nMinStartPercent, nMaxImmediatePercent) + math.max(nPersistentPercentSum - nTotalDamagePercent, 0), nMaxHpPercentLimit)
]]
local function GetTargetRecoveredHpPercent(self)
    local RecoveringValueType = ConsumableItemDef.RecoveringValueType
    local nPersistentPercentSum = 0
    local nMaxImmediatePercent = 0
    local nMinStartPercent = 1
    local nMaxHpPercentLimit = 0
    local nMaxHp = PropUtil.GetMaxHp(GamePlayerSelfHelper:Get())
    local nTotalDamagePercent = self.nDamageInRecovering / nMaxHp
    for i,v in ipairs(self.tbConsumableList) do
        local tbTemplate = v.tbTemplate
        local nValue = tbTemplate.nRecoveringValue
        local nValueType = tbTemplate.nRecoveringValueType
        if nValueType == RecoveringValueType.RECOVER_FIXED_VALUE then
            nPersistentPercentSum = nPersistentPercentSum + nValue / nMaxHp
        elseif nValueType == RecoveringValueType.RECOVER_PERCENT_VALUE then
            nPersistentPercentSum = nPersistentPercentSum + nValue / 100
        elseif nValueType == RecoveringValueType.RECOVER_TO_FIXED_VALUE then
            nMaxImmediatePercent = math.max(nMaxImmediatePercent, nValue / nMaxHp)
        elseif nValueType == RecoveringValueType.RECOVER_TO_PERCENT_VALUE then
            nMaxImmediatePercent = math.max(nMaxImmediatePercent, nValue / 100)
        end
        nMinStartPercent = math.min(nMinStartPercent, v.nStartPercent)
        nMaxHpPercentLimit = math.max(nMaxHpPercentLimit, tbTemplate.nHpLimit / 100)
    end
    if nMaxImmediatePercent > 0 then
        return nMaxImmediatePercent
    end
    local nResult = math.min(nMinStartPercent + nPersistentPercentSum - nTotalDamagePercent, nMaxHpPercentLimit)
    LOG(string.format("GetTargetRecoveredHpPercent nMinStartPercent=%f, nMaxImmediatePercent=%f, nPersistentPercentSum=%f, nTotalDamagePercent=%f, nMaxHpPercentLimit=%f, nResult=%f", nMinStartPercent, nMaxImmediatePercent, nPersistentPercentSum, nTotalDamagePercent, nMaxHpPercentLimit, nResult))
    return nResult
end

local function UpdateRecoveredHp(self)
    local nCount = #self.tbConsumableList
    LOG(string.format("UpdateRecoveredHp nConsumableCount=%s", nCount))
    if nCount > 0 then
        self.pWidgetRef.pgbRecoveredHp:SetPercent(GetTargetRecoveredHpPercent(self))
        self.pWidgetRef.pgbRecoveredHp:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.pWidgetRef.pgbRecoveredHp:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function ClearConsumableInfo(self)
    LOG("ClearConsumableInfo")
    self.tbConsumableList = {}
    self.nDamageInRecovering = 0
    UpdateRecoveredHp(self)
end

-- 吃药开始，新增Table，且刷新UI
local function OnConsumableUseStarted(self, nInstanceId)
    LOG(string.format("OnConsumableUseStarted1 nInstanceId=%s", nInstanceId))
    local ConsumableItem = BattleItemSystemHelper:GetItem(nInstanceId, true)
    local tbConsumableTemplate = ConsumableItem:GetTemplate()
    if tbConsumableTemplate.nRecoveringType == ConsumableItemDef.RecoveringType.HP then
        local nHp = PropUtil.GetHpPercent(GamePlayerSelfHelper:Get())
        table.insert(self.tbConsumableList, {
            nId = nInstanceId,
            tbTemplate = tbConsumableTemplate,
            nStartPercent = nHp
        })
        LOG(string.format("OnConsumableUseStarted2 Add consumable info, nInstanceId=%s, nTemplateId=%s, nStartPercent=%s", nInstanceId, tbConsumableTemplate.nId, nHp))
        UpdateRecoveredHp(self)
    end
end

-- 吃药打断，移除Table且刷新UI
local function OnConsumableUseInterrupted(self, nInstanceId)
    LOG(string.format("OnConsumableUseInterrupted1 nInstanceId=%s", nInstanceId))
    for i=#self.tbConsumableList, 1, -1 do
        local v = self.tbConsumableList[i]
        if (v.nId == nInstanceId) and (not v.bRemoved) then
            table.remove(self.tbConsumableList, i)
            LOG(string.format("OnConsumableUseInterrupted2 remove consumable info, nInstanceId=%s", nInstanceId))
            UpdateRecoveredHp(self)
            break
        end
    end
end

-- 吃药结束
local function OnConsumableUseEnded(self, nInstanceId)
    LOG(string.format("OnConsumableUseEnded1 nInstanceId=%s", nInstanceId))
    for _, v in ipairs(self.tbConsumableList) do
        if (v.nId == nInstanceId) and (not v.bRemoved) then
            LOG(string.format("OnConsumableUseEnded2 Mark Removed, nInstanceId=%s", nInstanceId))
            v.bRemoved = true
            break
        end
    end

    -- 如果有任何没被移除的药
    for _, v in ipairs(self.tbConsumableList) do
        if not v.bRemoved then
            return
        end
    end
    ClearConsumableInfo(self)
end

-- 吃药中受伤
local function OnTakeDamage(self, tbTaker, tbCauser, nDamage)
    if (tbTaker == GamePlayerSelfHelper:Get()) and  (#self.tbConsumableList > 0) then
        self.nDamageInRecovering = self.nDamageInRecovering + nDamage
        LOG(string.format("OnTakeDamage nDamage=%s, nDamageInRecovering=%s", nDamage, self.nDamageInRecovering))
        UpdateRecoveredHp(self)
    end
end

-- 吃药恢复显示相关逻辑 End
--------------------------------------------------
function ULPlayerStatusPanel:OnCreate()
    -- 用自己的EventHelper，因为事件需要跟随Active状态绑定/解绑
    self.EventHelper = SelfEventHelper()
    self.tbConsumableList = {}
end

function ULPlayerStatusPanel:OnDestroy()
    self:Deactivate()
end

function ULPlayerStatusPanel:OnLoad()
    self.tbEpSplitWidget = {}
    for i=1,MAX_EP_IMAGE_PHASE do
        self.tbEpSplitWidget[i] = self.pWidgetRef[EP_SPLIT_WIDGET_NAME .. i]
    end

    InitHpBarParam(self)
end

function ULPlayerStatusPanel:Activate()
    LOG("Activate")
    RefreshEpPhase(self)

    local tbPlayer = GamePlayerSelfHelper:Get()
    local PropertyComponent = tbPlayer:GetCurrentPropertyComponent()
    OnHpChanged(self, nil, nil, nil, true)
    OnEpChanged(self)

    local EventHelper = self.EventHelper
    EventHelper:RegisterLuaDelegate(PropertyComponent.OnHpChanged, OnHpChanged, self)
    EventHelper:RegisterLuaDelegate(PropertyComponent.OnEpChanged, OnEpChanged, self)
    EventHelper:RegisterLuaDelegate(PropertyComponent.OnIsDyingChanged, OnIsDyingChanged, self)

    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnPawnDead)
    EventHelper:RegisterEvent(ClientEventDef.EV_CONSUMABLE_START_USE, self, OnConsumableUseStarted)
    EventHelper:RegisterEvent(ClientEventDef.EV_CONSUMABLE_USE_INTERRUPTED, self, OnConsumableUseInterrupted)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_CONSUMABLE_USE_SUCCESS, self, OnConsumableUseSucceeded)
    EventHelper:RegisterEvent(ClientEventDef.EV_CONSUMABLE_USE_END, self, OnConsumableUseEnded)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_TAKE_DAMAGE, self, OnTakeDamage)
    EventHelper:RegisterEvent(CommonEventDef.EV_MORALE_PHASE_CHANGED, self, OnMoralePhaseChanged)
end

function ULPlayerStatusPanel:Deactivate()
    LOG("Deactivate")
    self.EventHelper:UnregisterAll()
    ClearConsumableInfo(self)
end

return ULPlayerStatusPanel