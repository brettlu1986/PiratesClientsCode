-----------------------------------------------------
--File Name    : ULLobbyAwardDisplay.lua
--Author       : Chen Yixin
--Create Time  : 2019-09-26
--Description  : 大厅道具获得展示UI
-----------------------------------------------------
local luaclass = require ("luaclass")
local UILogicBase = require("UILogicBase")
local ULLobbyAwardDisplay = luaclass("ULBuildShip", UILogicBase)

local TimeUtil = require("TimeUtil")
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")
local UITextDef = require("UITextDef")
local DisplayItemHelper = require("DisplayItemHelper")
-- local Proto = require("ClientProtoNames")

ULLobbyAwardDisplay.tbCurrentOpenWndList = nil
ULLobbyAwardDisplay.szCurWnd = nil
ULLobbyAwardDisplay.OwnerSub = nil

ULLobbyAwardDisplay.tbLastPos = nil
ULLobbyAwardDisplay.tbCurPos = nil
ULLobbyAwardDisplay.bIsDrag = false
ULLobbyAwardDisplay.pActor = nil

ULLobbyAwardDisplay.tbItemTemplate = nil

local function PlayAnimEnd(self)
    self.pWidgetRef.bdrTouch:SetVisibility(ESlateVisibility.Visible)
end

local function SetItemDetailInfo(self, tbNextItemTemplate)
    local nItemExp = ""
    if tbNextItemTemplate.nExpirationTime then
        local nExpirationDays = math.ceil(tbNextItemTemplate.nExpirationTime / TimeUtil.GetOneDaySeconds())
        local nItemExpFormat = UISetUtils.GetL10NTextByKey("UI_DISPLAY_UNLOCK_ITEM_CONTENT_TEXT")
        nItemExp = L10N:Format(nItemExpFormat, nExpirationDays)
    else
        nItemExp = UISetUtils.GetL10NTextByKey("UI_DISPLAY_ITEM_CONTENT_TEXT")
    end
    self.pWidgetRef.txtContent:SetText(nItemExp)
    self.pWidgetRef.KMRichTextBlock_0:SetText(UITextDef.DISPLAY_ITEM_CATEGORY[tbNextItemTemplate.nCategory])
    local l10nName = DisplayItemHelper.GetDisplayIteml10nName(tbNextItemTemplate)
    self.pWidgetRef.KMTextBlock_2:SetText(l10nName)
end

local function UpdateDisplay(self, tbItemTemplate)
    self.Owner:PlayAnimation("animDisplayAwardItemIn", 0, 1, EUMGSequencePlayMode.Forward, 1)

    self.tbItemTemplate = tbItemTemplate
    SetItemDetailInfo(self, tbItemTemplate)
    self.pWidgetRef.bdrTouch:SetVisibility(ESlateVisibility.Collapsed)
    self.pActor = self.Owner:CreateActor(tbItemTemplate, function()
        PlayAnimEnd(self)
    end)
end

local function OnClickedConfirmBtn(self)
    self.OwnerSub:OnWndClose(self.Owner:GetWndName())
    -- local tbNextItemTemplate = self.OwnerSub:GetNextShip()
    -- if not tbNextItemTemplate then
    --     self.OwnerSub:OnWndClose(self.Owner:GetWndName())
    --     return
    -- end
    -- UpdateDisplay(self, tbNextItemTemplate)
end

-- local function OnClickedWearBtn(self)
--     self.OwnerSub:Wear(self.tbItemTemplate)
-- end

local function OnMouseButtonDown(self, pGeometry, pMouseEvent)
    self.bIsDrag = true
    self.tbLastPos = KismetInputLibrary.PointerEvent_GetScreenSpacePosition(pMouseEvent)
    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseMove(self, pGeometry, pMouseEvent)
    if not self.bIsDrag then
        return WidgetBlueprintLibrary.Handled()
    end
    self.tbCurPos = KismetInputLibrary.PointerEvent_GetScreenSpacePosition(pMouseEvent)
    self.OwnerSub:Rotate(self.tbCurPos.X - self.tbLastPos.X, self.pActor)
    self.tbLastPos = self.tbCurPos
    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseButtonUp(self, pGeometry, pMouseEvent)
    self.bIsDrag = false
    self.tbLastPos = nil
    self.tbCurPos = nil
    return WidgetBlueprintLibrary.Handled()
end

------------------------
-- life cycle
------------------------
function ULLobbyAwardDisplay:OnLoad()
    local tbOpenArgs = self.Owner.tbOpenArgs
    self.OwnerSub = tbOpenArgs.OwnerSub
end

function ULLobbyAwardDisplay:OnShow()
end

function ULLobbyAwardDisplay:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSummon_1.OnClicked, self, OnClickedConfirmBtn)
    -- EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSummon_2.OnClicked, self, OnClickedWearBtn)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.bdrTouch.OnMouseButtonDownEvent, self, OnMouseButtonDown)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.bdrTouch.OnMouseMoveEvent, self, OnMouseMove)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.bdrTouch.OnMouseButtonUpEvent, self, OnMouseButtonUp)
end

function ULLobbyAwardDisplay:OnExit()
    self.Owner:StopAnimation("animDisplayAwardItemIn")
end

------------------------
-- 接口
------------------------
function ULLobbyAwardDisplay:UpdateUIDisplay(tbOpenArgs)
    local tbItemTemplate = tbOpenArgs.tbItemTemplate
    self.OwnerSub:SetCamera(self.Owner:GetWndName(), 1)
    -- local pWidgetRef = self.pWidgetRef
    -- if tbOpenArgs.nSourceType and tbOpenArgs.nSourceType == Proto.AwardSourceType.NOOB_SHIP_AWARD then
    --     pWidgetRef.btnSummon_2:SetVisibility(ESlateVisibility.Collapsed)
    -- else
    --     pWidgetRef.btnSummon_2:SetVisibility(ESlateVisibility.Visible)
    -- end

    UpdateDisplay(self, tbItemTemplate)
end

return ULLobbyAwardDisplay