local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULWatchBotEnergy = luaclass("ULWatchBotEnergy", UILogicBase)

local MathUtil = require("MathUtil")
local HeadHpIni = require("HeadHpIni")
local ShipDataTable = require("ShipDataTable")
local ShipMoraleDataTable = require("ShipMoraleDataTable")
local HumanMoraleDataTable = require("HumanMoraleDataTable")

local DEFAULT_HP_LEVEL = -1
local MAX_EP_IMAGE_PHASE = 4
local EP_SPLIT_WIDGET_NAME = "sldrEPSplit0"

ULWatchBotEnergy.nCurrentHpLevel = nil
ULWatchBotEnergy.tbEpSplitWidget = nil

local function GetCurrentHpLevel(self, nHpPercent)
    local nCurrentHpLevel = DEFAULT_HP_LEVEL
    local tbWatchObj = self.Owner.tbCurrrentWatchObj
    local tbHpLevelPercents = HeadHpIni.tbUiHpColors.tbHpLevelPercents
    if not tbWatchObj:IsDying() then
        for i,v in ipairs(tbHpLevelPercents) do
            if nHpPercent >= v then
                nCurrentHpLevel = i
                break
            end
        end
    end
    return nCurrentHpLevel
end

local function GetEpPhaseList(self, tbPlayer)
    local tbEpPhaseList = {}
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


local function RefreshEpPhase(self, tbPlayer)
    local tbEpPhaseList = GetEpPhaseList(self, tbPlayer)
    local nMaxEp = tbPlayer:GetCurrentPropertyComponent():GetMaxEp()
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

--血量 能量变化
local function OnWatchMateHpChanged(self, _, _, nHpPercent)
    local tbObj = self.Owner.tbCurrrentWatchObj
    local pWidgetRef = self.pWidgetRef
    if not pWidgetRef then
        return
    end

    if tbObj and tbObj:IsDead() then
        pWidgetRef.pgbHp:SetPercent(0)
        return
    end
   
    pWidgetRef.pgbHp:SetPercent(nHpPercent)

    local nCurrentHpLevel = GetCurrentHpLevel(self, nHpPercent)
    local tbHpLevelBgOpacities = HeadHpIni.tbUiHpColors.tbHpLevelBgOpacities
    local tbHpLevelColors = HeadHpIni.tbUiHpColors.tbHpLevelColors

    if nCurrentHpLevel ~= self.nCurrentHpLevel then
        self.nCurrentHpLevel = nCurrentHpLevel
        if nCurrentHpLevel == DEFAULT_HP_LEVEL then
            pWidgetRef.pgbHp:SetFillColorAndOpacity(KMUMGLibrary.GetLinearColorFromHex(HeadHpIni.tbUiHpColors.szDyingHpColor))
            pWidgetRef.imgHpBg:SetRenderOpacity(HeadHpIni.tbUiHpColors.nDyingHpBgOpacity)
        else
            pWidgetRef.pgbHp:SetFillColorAndOpacity(KMUMGLibrary.GetLinearColorFromHex(tbHpLevelColors[nCurrentHpLevel]))
            pWidgetRef.imgHpBg:SetRenderOpacity(tbHpLevelBgOpacities[nCurrentHpLevel])
        end
    end
end

local function OnWatchMateEpChanged(self, _, _, nEpPercent)
    local tbObj = self.Owner.tbCurrrentWatchObj
    if tbObj and tbObj:IsDead() then
        return
    end

    local pWidgetRef = self.pWidgetRef
    if not pWidgetRef then
        return
    end
    pWidgetRef.pgbEp:SetPercent(nEpPercent)
    if nEpPercent <= 0 then
        pWidgetRef.ovlEP:SetVisibility(ESlateVisibility.Hidden)
    else
        pWidgetRef.ovlEP:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
end

function ULWatchBotEnergy:RefreshCurrentMateEnergy()
    --unregister last
    local EventHelper = self.EventHelper
    local Owner = self.Owner
    if Owner.tbLastWatchObj then
        local LastPropertyComponent = Owner.tbLastWatchObj:GetCurrentPropertyComponent()
        EventHelper:UnregisterLuaDelegate(LastPropertyComponent.OnHpChanged, OnWatchMateHpChanged, self)
        EventHelper:UnregisterLuaDelegate(LastPropertyComponent.OnEpChanged, OnWatchMateEpChanged, self)
    end

    if Owner.tbCurrrentWatchObj then
        local PropertyComponent = Owner.tbCurrrentWatchObj:GetCurrentPropertyComponent()
        RefreshEpPhase(self, Owner.tbCurrrentWatchObj)
        --init the hp and ep
        OnWatchMateHpChanged(self, nil, nil, PropertyComponent:GetHpPercent())
        OnWatchMateEpChanged(self, nil, nil, PropertyComponent:GetEpPercent())

        EventHelper:RegisterLuaDelegate(PropertyComponent.OnHpChanged, OnWatchMateHpChanged, self)
        EventHelper:RegisterLuaDelegate(PropertyComponent.OnEpChanged, OnWatchMateEpChanged, self)
    end
end

function ULWatchBotEnergy:OnLoad()
    self.tbEpSplitWidget = {}
    for i=1,MAX_EP_IMAGE_PHASE do
        self.tbEpSplitWidget[i] = self.pWidgetRef[EP_SPLIT_WIDGET_NAME .. i]
    end
    self:RefreshCurrentMateEnergy()
    -- bind prefab
end

function ULWatchBotEnergy:OnEnter()
    --Owner is UIWatchBattle
    --local Owner = self.Owner
end

function ULWatchBotEnergy:OnBindEvent(EventHelper)
end

function ULWatchBotEnergy:OnUnload()
    --unload res
end

return ULWatchBotEnergy