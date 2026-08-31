-----------------------------------------------------
--File Name    : UPMainTips.lua
--Description  : UPMainTips
-----------------------------------------------------
local luaclass = require ("luaclass")
local UPFFABase = require("UPFFABase")
local UPMainTips = luaclass("UPFFAHeadDialog", UPFFABase)
local ClientEventDef = require("ClientEventDef")
local FFADialogDataTable = require("FFADialogDataTable")
local NpcHeadIconRes = require("NpcHeadIconRes")
local UISetUtils = require("UISetUtils")
local StringUtil = require("StringUtil")
local Timer = require("Timer")
local SoundManager = require("SoundManager")
local L10N = require("L10N")

UPMainTips.nCurIndex = 0
UPMainTips.nDialogId = 0
UPMainTips.tbDialogParam = nil
UPMainTips.nIconId   = 0
UPMainTips.l10nName  = nil
UPMainTips.tbRefreshTimer = nil
UPMainTips.bHide = false

local DEFAULT_DIALOG_INDEX = 1
local RefreshDialog = nil

local function HideDialog(self)
    self.nIconId = 0
    self.l10nName = nil
    self.bHide = true
    local pWidgetRef = self.pWidgetRef
    local OnAnimationComplete = function()
        if self.bHide then
            pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
    self:PlayAnimation("animTips", 0, 1, EUMGSequencePlayMode.Reverse, 1, OnAnimationComplete)
    if self.fnCallback then
        self.fnCallback(self.Owner)
    end
end

local function DestroyTimer(self)
    if self.tbRefreshTimer then
        self.tbRefreshTimer:Clear()
        self.tbRefreshTimer = nil
        self.bHide = false
    end    
end

local function VerifyNextDialog(self)
    DestroyTimer(self)
    self.nCurIndex = self.nCurIndex + 1
    RefreshDialog(self)
end

RefreshDialog = function(self)
    local tbDialogTemp = FFADialogDataTable:GetTemplate(self.nDialogId, self.nCurIndex)
    if tbDialogTemp == nil then
        HideDialog(self)
        return
    end

    local pWidgetRef = self.pWidgetRef

    if self.nIconId ~= tbDialogTemp.nIconId then
        local tbIconRes = NpcHeadIconRes:GetTemplate(tbDialogTemp.nIconId)
        if tbIconRes and not StringUtil.IsEmptyString(tbIconRes.szHeadIcon) then
            UISetUtils.SetImageBrushRes(pWidgetRef.imgBiginHead, tbIconRes.szHeadIcon:load())
        end
        self.nIconId = tbDialogTemp.nIconId
    end
    pWidgetRef.imgBiginHead:SetVisibility(self.nIconId > 0 and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed)
    local l10nName = tbDialogTemp.l10nName
    if self.l10nName ~= l10nName then
        if l10nName ~= nil then
            pWidgetRef.txtName:SetText(l10nName)
        else
            logwarning("UPFFAHeadDialog not name, id = ", self.nDialogId)
        end
        self.l10nName = l10nName
    end

    local l10nContent = tbDialogTemp.l10nContent
    if self.tbDialogParam then
        l10nContent = L10N:FormatFromTable(l10nContent,self.tbDialogParam)
    end

    if l10nContent ~= nil then
        pWidgetRef.txtContent:SetText(l10nContent)
    else
        logwarning("UPFFAHeadDialog not content, id = ", self.nDialogId)        
    end

    if tbDialogTemp.nSoundId > 0 and self.bPlaySound then
        SoundManager:PlaySoundEffect(tbDialogTemp.nSoundId)
    end
    if self.tbRefreshTimer == nil then 
        self.tbRefreshTimer = Timer.NewTimerMethod(self, VerifyNextDialog, tbDialogTemp.nRemainTime)
    end    
end

local function ShowDialog(self, nDialogId, tbDialogParam, fnCallback, bPlaySound)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation("animTips", 0, 1, EUMGSequencePlayMode.Forward, 1)
    self.bHide = false
    self.nDialogId = nDialogId
    self.tbDialogParam = tbDialogParam
    self.nCurIndex = DEFAULT_DIALOG_INDEX
    self.fnCallback = fnCallback
    self.bPlaySound = bPlaySound ~= nil and bPlaySound or true
    RefreshDialog(self)    
end

function UPMainTips:OnCreate()
end

function UPMainTips:OnDestroy()
    DestroyTimer(self)
end

function UPMainTips:OnRefresh(nDialogId, fnCallback, bPlaySound)
    DestroyTimer(self)
    ShowDialog(self, nDialogId, nil, fnCallback, bPlaySound)
end

function UPMainTips:OnBindEvent(EventHelper)
    if not self.Owner.bDialogIngoreEvent then
        EventHelper:RegisterEvent(ClientEventDef.EV_FFA_SHOWDIALOG, self, ShowDialog)
    end
end

return UPMainTips
