-----------------------------------------------------
--File Name    : UILobbyShipBase.lua
--Author       : chenyixin
--Description  : 舰船船体
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbyShipBase = luaclass("UILobbyShipBase", WndBase)

local UISetUtils = require("UISetUtils")
local ItemChangedEffectDataTable = require("ItemChangedEffectDataTable")

UILobbyShipBase.OwnerSub = nil
UILobbyShipBase.pbWindowFrame = nil
UILobbyShipBase.tbShipDetail = nil
UILobbyShipBase.tbCurrentDisplayData = {}

UILobbyShipBase.szDetailAnim = nil
UILobbyShipBase.tbChangedEffectBdrs = {}
UILobbyShipBase.tbChangedEffectTxts = {}

UILobbyShipBase.nViewBlendTime = 0.5

local MAX_EFFECT_NUM = 6
local BDR_NAME = "bdrChangedEffect"
local TXT_NAME = "txtChangedEffect"

-- local ZERO_VECTOR2D = Vector2D{X = 0, Y = 0}

local function SetResumeData(self)
    self.OwnerSub:UpdateDisplayItemInfo(self.tbCurrentDisplayData)
end

function UILobbyShipBase:SetCurrentDisplayData(szKey, nValue)
    -- logdebug("SetCurrentDisplayData setting", szKey, "from", self.tbCurrentDisplayData[szKey],"to",nValue)
    self.tbCurrentDisplayData[szKey] = nValue
    SetResumeData(self)
end

---------------------------------------
-- Detail
---------------------------------------

local function OnDetailModeChanged(self, nDetailMode)
    self:SetCurrentDisplayData("nDetailMode", nDetailMode)
end

local function OnBtnDetailClicked(self)
    if self.nDetailMode and self.nDetailMode > 0 then
        self:SetDetailVisible(false, true)
    else
        self.tbShipDetail:SetShowDetailedInfo(false)
        self:SetDetailVisible(true, true)
    end
end

function UILobbyShipBase:SetShipBattleId(nBattleItemId, bResetDetailMode)
    self.tbShipDetail:SetShipTemplateId(nBattleItemId)
    if bResetDetailMode then
        self.tbShipDetail:SetShowDetailedInfo(false)
    end
end

function UILobbyShipBase:SetShowDetailedInfo(bShow)
    self.tbShipDetail:SetShowDetailedInfo(bShow)
end

function UILobbyShipBase:CanShow()
    return self.tbShipDetail:CanShow()
end

function UILobbyShipBase:SetDetailVisible(bVisible, bWitnAnim, fnCallback)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.bdrDetailChecked.Background.DrawAs = bVisible and ESlateBrushDrawType.Box or ESlateBrushDrawType.NoDrawType
    local SetVisibility = function()
        if pWidgetRef.bdrRotate then
            local pVisibility = bVisible and ESlateVisibility.Collapsed or ESlateVisibility.Visible
            pWidgetRef.bdrRotate:SetVisibility(pVisibility)
        end
        
        if bVisible then
            self.nDetailMode = self.tbShipDetail:GetShowDetailedInfo() and 2 or 1
        else
            pWidgetRef.pbLobbyShipDetail:SetVisibility(ESlateVisibility.Hidden)
            self.tbShipDetail:SetShowDetailedInfo(false)
            self.nDetailMode = 0
        end

        if fnCallback then
            fnCallback()
        end

        if self.fnOnDetailModeChanged then
            self.fnOnDetailModeChanged(self.nDetailMode)
        end
    end

    if bVisible then
        pWidgetRef.pbLobbyShipDetail:SetVisibility(ESlateVisibility.Visible)
    end
    
    if bWitnAnim and self.szDetailAnim then
        self:StopAnimation(self.szDetailAnim)
        local pPlayMode = bVisible and EUMGSequencePlayMode.Forward or EUMGSequencePlayMode.Reverse
        self:PlayAnimation(self.szDetailAnim, 0, 1, pPlayMode, 1, SetVisibility)
    else
        SetVisibility()
    end
end

function UILobbyShipBase:SetShowDetailAnim(szDetailAnim)
    self.szDetailAnim = szDetailAnim
end

---------------------------------------
-- SkinChangedEffects
---------------------------------------
function UILobbyShipBase:SetSkinChangedEffectData(tbTemplate)
    local tbChangedEffects = tbTemplate and tbTemplate.tbChangedEffects or {}
    local nEffectCount = 0
    for i = 1, MAX_EFFECT_NUM do
        local nEffectId = tbChangedEffects[i]
        local pBdr = self.tbChangedEffectBdrs[i]
        local pTxt = self.tbChangedEffectTxts[i]
        if nEffectId then
            nEffectCount = nEffectCount + 1
            local tbEffect = ItemChangedEffectDataTable:GetTemplate(nEffectId)
            local tbForground = tbEffect.tbForground
            local pForClr = KMUMGLibrary.GetSlateColor(tbForground[1], tbForground[2], tbForground[3], tbForground[4])
            local tbBackground = tbEffect.tbBackground
            local pBackClr = KMUMGLibrary.GetSlateColor(tbBackground[1], tbBackground[2], tbBackground[3], tbBackground[4])

            pTxt:SetColorAndOpacity(pForClr)
            pTxt:SetText(tbEffect.l10nName)
            UISetUtils.SetBorderBrushTint(pBdr, pBackClr)
            pBdr:SetVisibility(ESlateVisibility.Visible)
        else
            pBdr:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
    if nEffectCount > 0 then
        self.pWidgetRef.bdrChangedEffects:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.pWidgetRef.bdrChangedEffects:SetVisibility(ESlateVisibility.Collapsed)
    end
end

---------------------------------------
-- overrides
---------------------------------------
function UILobbyShipBase:OnLoad()
    local tbOpenArgs = self.tbOpenArgs
    self.OwnerSub = tbOpenArgs.OwnerSub
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetBackIsCloseSelf(false)

    local tbShipDetail = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbLobbyShipDetail)
    self.tbShipDetail = tbShipDetail

    local pWidgetRef = self.pWidgetRef
    for i = 1, MAX_EFFECT_NUM do
        self.tbChangedEffectBdrs[i] = pWidgetRef[BDR_NAME..i]
        self.tbChangedEffectTxts[i] = pWidgetRef[TXT_NAME..i]
    end

    if self.pWidgetRef.BlendTime then
        self.nViewBlendTime = self.pWidgetRef.BlendTime
    end
end

function UILobbyShipBase:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef

    EventHelper:RegisterCppDelegate(pWidgetRef.btnDetail.OnClicked, self, OnBtnDetailClicked)
    if self.tbShipDetail.ulShipDetailContent then
        self.tbShipDetail.ulShipDetailContent:BindOnBtnDetailClicked(function(nDetailMode)
            OnDetailModeChanged(self, nDetailMode)
        end)
    end
end

function UILobbyShipBase:OnExit()
    self:StopAnimation(self.szDetailAnim)
end



return UILobbyShipBase