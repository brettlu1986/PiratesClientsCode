-----------------------------------------------------
--File Name    : ULFFAToastBoard.lua
--Description  : ffa战斗击杀提示
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULFFAToastBoard = luaclass("ULFFAToastBoard", UILogicBase)
local ClientEventDef = require("ClientEventDef")
local DelayTimer = require("DelayTimer")
local WidgetAnimationHandle = require("WidgetAnimationHandle")

local MAX_ITEM_TOAST_COUNT = 3
local ITEM_DISTANCE = -50
local FUNC_MAKE_VECTOR_2D = KismetMathLibrary.MakeVector2D


ULFFAToastBoard.tbFreeItemList     = nil
ULFFAToastBoard.tbUsedItemList     = nil
ULFFAToastBoard.tbWaitMessageList  = nil
ULFFAToastBoard.bCanvasMoved       = false

local function SetItemPosition(ToastItem, nIndex)
    ToastItem.pWidgetRef.Slot:SetPosition(FUNC_MAKE_VECTOR_2D(0, ITEM_DISTANCE * nIndex))
end

local function ClearDelayHandle(self)
    if self.tbDelayHandle then
        DelayTimer:ClearTimer(self.tbDelayHandle)
        self.tbDelayHandle = nil
    end
end

-- 添加新的获取道具Toast
local function HandleNextToast(self)
    local tbMessageInfo = self.tbWaitMessageList[1]
    local ToastItem = self.tbFreeItemList[1]
    if tbMessageInfo and ToastItem then
        table.remove(self.tbWaitMessageList, 1)
        table.remove(self.tbFreeItemList, 1)
        table.insert(self.tbUsedItemList, ToastItem)

        ToastItem.pWidgetRef:SetVisibility(ESlateVisibility.HitTestInvisible)
        SetItemPosition(ToastItem, 1)
        ToastItem:ShowToast(tbMessageInfo.nKillerInstanceId, tbMessageInfo.nDeadInstanceId,
            tbMessageInfo.szKillerName, tbMessageInfo.szDeadName, tbMessageInfo.nKillType,
            tbMessageInfo.nAttackMethod, tbMessageInfo.nWeaponTemplateId)
    end
end

local function RevertToastCanvasMoveUp(self)
    self.bCanvasMoved = false
    self.Owner:PlayAnimation("animToastMoveUp", 0.5, 1, EUMGSequencePlayMode.Reverse, 1)
    local nUsedItemCount = #self.tbUsedItemList
    for i,v in ipairs(self.tbUsedItemList) do
        SetItemPosition(v, nUsedItemCount + 1 - i)
    end
end

local function ToastCanvasMoveUp(self)
    if (not self.bCanvasMoved) and (#self.tbWaitMessageList > 0) then
        self.bCanvasMoved = true
        self.Owner:PlayAnimation("animToastMoveUp", 0, 1, EUMGSequencePlayMode.Forward, 1)

        if #self.tbUsedItemList == MAX_ITEM_TOAST_COUNT - 1 then
            self.tbUsedItemList[1]:HideToast()
        end
    end
end

local function OnAnimToastMoveUpFinished(self)
    if self.bCanvasMoved then
        HandleNextToast(self)
        RevertToastCanvasMoveUp(self)
    end
end

local function OnToastHideFinished(self, ToastItem)
    ToastItem.pWidgetRef:SetVisibility(ESlateVisibility.Hidden)
    table.remove(self.tbUsedItemList, 1)
    table.insert(self.tbFreeItemList, ToastItem)
end

local function OnToastShowFinished(self, ToastItem)
    ToastCanvasMoveUp(self)
end

-- local function ShowTeamMemberKillInfo(self, szKillerName, szDeadName, nKillType, nAttackMethod,
--     nKillerInstanceId, nDeadInstanceId, nWeaponTemplateId)

--     local nPlayerSelfInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
--     local tbToastTemplate = FFAToastDataTable:GetTemplate(nAttackMethod, nWeaponTemplateId)
--     if not tbToastTemplate then
--         logerror("ShowTeamMemberKillInfo:tbToastTemplate is nil, nAttackMethod, nWeaponTemplateId=", nAttackMethod, nWeaponTemplateId)
--         return
--     end
--     local txtTeamMemberKillInfo = self.pWidgetRef.txtTeamMemberKillInfo
--     local szFormat = nil
--     local l10nKillName = nil
--     local l10nDeadName = nil
--     local l10nToast = nil
--     local l10nWeaponName = ""
--     local tbItemTemplate = BattleItemDataTable:GetTemplate(nWeaponTemplateId)
--     if tbItemTemplate then
--         l10nWeaponName = tbItemTemplate.l10nName
--     end
--     if nKillerInstanceId == nPlayerSelfInstanceId then
--         --自己击杀别的玩家
--         l10nKillName = UISetUtils.GetL10NTextByKey("FFA_YOU")
--         l10nToast = tbToastTemplate.l10nKillerToast
--         txtTeamMemberKillInfo:SetColorAndOpacity(UIResourceDef.COLOR.BLUE1.LINEAR_COLOR)
--     elseif BattleTeammateSystem:CheckTeammateWithSelf(nKillerInstanceId) then
--         l10nKillName = L10N:Format(UISetUtils.GetL10NTextByKey("FFA_YOUR_TEAM_MEMBER"), szKillerName)
--         l10nToast = tbToastTemplate.l10nKillerToast
--         txtTeamMemberKillInfo:SetColorAndOpacity(UIResourceDef.COLOR.BLUE1.LINEAR_COLOR)
--     end
--     if nDeadInstanceId == nPlayerSelfInstanceId then
--         l10nDeadName = UISetUtils.GetL10NTextByKey("FFA_YOU")
--         l10nToast = tbToastTemplate.l10nDeadToast
--         txtTeamMemberKillInfo:SetColorAndOpacity(UIResourceDef.COLOR.RED.LINEAR_COLOR)
--     elseif BattleTeammateSystem:CheckTeammateWithSelf(nDeadInstanceId) then
--         l10nDeadName = L10N:Format(UISetUtils.GetL10NTextByKey("FFA_YOUR_TEAM_MEMBER"), szDeadName)
--         l10nToast = tbToastTemplate.l10nDeadToast
--         txtTeamMemberKillInfo:SetColorAndOpacity(UIResourceDef.COLOR.RED.LINEAR_COLOR)
--     end
--     if not l10nKillName and not l10nDeadName then
--         return
--     end
--     if not l10nKillName then
--         l10nKillName = szKillerName
--     end
--     if not l10nDeadName then
--         l10nDeadName = szDeadName
--     end
--     szFormat = L10N:Format(l10nToast, l10nKillName, l10nDeadName, KILL_STATE_INFO[nKillType], l10nWeaponName)
--     txtTeamMemberKillInfo:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
--     txtTeamMemberKillInfo:SetText(szFormat)
--     ClearDelayHandle(self)
--     self.tbDelayHandle = DelayTimer:DelayRun(function()
--         txtTeamMemberKillInfo:SetVisibility(ESlateVisibility.Collapsed)
--     end, TEAM_MEMBER_KILL_SHOW_TIME)
-- end

local function OnFFABattleToast(self,
        nKillType,
        szKillerName,
        szDeadName,
        nKillerInstanceId,
        nDeadInstanceId,
        nAttackMethod,
        nWeaponTemplateId)

    --self.pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    log("FFABattleToast:", szKillerName, szDeadName, nAttackMethod, nKillType, nWeaponTemplateId)
    local tbMessageInfo = {}
    tbMessageInfo.nKillerInstanceId = nKillerInstanceId
    tbMessageInfo.nDeadInstanceId = nDeadInstanceId
    tbMessageInfo.szKillerName = szKillerName
    tbMessageInfo.szDeadName = szDeadName
    tbMessageInfo.nKillType = nKillType
    tbMessageInfo.nAttackMethod = nAttackMethod
    tbMessageInfo.nWeaponTemplateId = nWeaponTemplateId
    table.insert(self.tbWaitMessageList, tbMessageInfo)
    if #self.tbUsedItemList == 0 then
        HandleNextToast(self)
    else
        ToastCanvasMoveUp(self)
    end
    -- ShowTeamMemberKillInfo(self, szKillerName, szDeadName, nKillType,
    --     nAttackMethod, nKillerInstanceId, nDeadInstanceId, nWeaponTemplateId)
end

function ULFFAToastBoard:OnLoad()
    self.tbFreeItemList = {}
    self.tbUsedItemList = {}
    self.tbWaitMessageList = {}

    for i = 1, MAX_ITEM_TOAST_COUNT do
        self.tbFreeItemList[i] = self.PrefabHelper:BindPrefab(self.pWidgetRef["pbToastItem0"..i])
    end
end

function ULFFAToastBoard:OnBindEvent(Helper)
    for i,v in ipairs(self.tbFreeItemList) do
        Helper:RegisterLuaDelegate(v.tbOnShowFinished, function() OnToastShowFinished(self, v) end)
        Helper:RegisterLuaDelegate(v.tbOnHideFinished, function() OnToastHideFinished(self, v) end)
    end
    Helper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(self.pWidgetRef, self.pWidgetRef.animToastMoveUp, OnAnimToastMoveUpFinished, self))
    Helper:RegisterEvent(ClientEventDef.EV_FFA_BATTLE_TOAST, self, OnFFABattleToast)
end

function ULFFAToastBoard:OnDestroy()
    ClearDelayHandle(self)
end

return ULFFAToastBoard