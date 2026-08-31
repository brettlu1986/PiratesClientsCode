-----------------------------------------------------
--File Name    : UPFFAToastItem.lua
--Description  : Prefab Toast Item
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPFFAToastItem = luaclass("UPFFAToastItem", PrefabBase)

-- require
local LuaDelegate = require("LuaDelegate")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local FFAToastDataTable = require("FFAToastDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleTeammateSystem = require("BattleTeammateSystem")
local Proto = require("DungeonCommonProtoNames")
local L10N = require("L10N")
local BattleItemDataTable = require("BattleItemDataTable")
local WidgetAnimationHandle = require("WidgetAnimationHandle")


local DEFAULT_WAIT_TIME = 5
-- local KILLER_TEAM_FORMAT = '<text color="#0898F2">%s</>'
-- local DEAD_TEAM_FORMAT = '<text color="#E30D4D">%s</>'

local STATE_ICON =
{
    [Proto.d2c_BattleKillToast_EType.KILL] = UIResourceDef.FFA_BATTLE_TOAST_ID_KILL,
    [Proto.d2c_BattleKillToast_EType.INJURY] = UIResourceDef.FFA_BATTLE_TOAST_ID_SERIOUS
}

-- member variable
UPFFAToastItem.tbOnHideFinished = nil
UPFFAToastItem.tbOnShowFinished = nil
UPFFAToastItem.nWaitTime = DEFAULT_WAIT_TIME

-- public function
function UPFFAToastItem:OnLoad()
    self.tbOnHideFinished = LuaDelegate()
    self.tbOnShowFinished = LuaDelegate()
end

function UPFFAToastItem:OnBindEvent(EventHelper)
    local OnWaitTimeEndEvent = function()
        self:PlayAnimation("FadeOutAnim", 0, 1, EUMGSequencePlayMode.Forward, 1)
    end
    local OnFadeInFinishedEvent = function()
        self.TimerHelper:NewTimer(OnWaitTimeEndEvent, self.nWaitTime)
        self.tbOnShowFinished:Fire()
    end
    local OnFadeOutFinishedEvent = function()
        self.tbOnHideFinished:Fire()
    end
    EventHelper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(self.pWidgetRef, self.pWidgetRef.FadeInAnim, OnFadeInFinishedEvent))
    EventHelper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(self.pWidgetRef, self.pWidgetRef.FadeOutAnim, OnFadeOutFinishedEvent))
end

function UPFFAToastItem:ShowToast(nKillerInstanceId, nDeadInstanceId, szKillerName, szDeadName,
    nKillType, nAttackMethod, nWeaponTemplateId, nWaitTime)
    local tbToastTemplate = FFAToastDataTable:GetTemplate(nAttackMethod, nWeaponTemplateId)
    if not tbToastTemplate then
        logerror("UPFFAToastItem:ShowToast,tbToastTemplate is nil, nAttackMethod, nWeaponTemplateId=", nAttackMethod, nWeaponTemplateId)
        return
    end

    local pWidgetRef = self.pWidgetRef
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    local nPlayerSelfInstanceId = tbPlayerSelf:GetServerInstanceId()
    local ktxtKillerName = pWidgetRef.ktxtKillerName
    local ktxtDieName = pWidgetRef.ktxtDieName

    local l10nKillName = szKillerName
    local l10nDeadName = szDeadName
    --local l10nToast = tbToastTemplate.l10nToastText
    local l10nWeaponName = ""
    local pLinearColor = UIResourceDef.COLOR.WHITE.LINEAR_COLOR
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nWeaponTemplateId)
    if tbItemTemplate then
        l10nWeaponName = tbItemTemplate.l10nName
    end

    if nKillerInstanceId == nPlayerSelfInstanceId then
        --自己击杀别的玩家
        l10nKillName = UISetUtils.GetL10NTextByKey("FFA_YOU")
        pLinearColor = UIResourceDef.COLOR.BLUE1.LINEAR_COLOR
        --l10nToast = tbToastTemplate.l10nKillerToast
        --txtTeamMemberKillInfo:SetColorAndOpacity(UIResourceDef.COLOR.BLUE1.LINEAR_COLOR)
    elseif BattleTeammateSystem:CheckTeammateWithSelf(nKillerInstanceId) then
        --自己或队友击杀别的玩家
        l10nKillName = L10N:Format(UISetUtils.GetL10NTextByKey("FFA_YOUR_TEAM_MEMBER"), szKillerName)
        pLinearColor = UIResourceDef.COLOR.BLUE1.LINEAR_COLOR
        --ktxtKillerName:SetColorAndOpacity(UIResourceDef.COLOR.BLUE1.LINEAR_COLOR)
        --ktxtDieName:SetColorAndOpacity(UIResourceDef.COLOR.BLUE1.LINEAR_COLOR)
        --pWidgetRef.imgAttackMethod:SetColorAndOpacity(UIResourceDef.COLOR.BLUE1.LINEAR_COLOR)
        --pWidgetRef.imgState:SetColorAndOpacity(UIResourceDef.COLOR.BLUE1.LINEAR_COLOR)
        --bKillerTeamMember = true
    end
    if nDeadInstanceId == nPlayerSelfInstanceId then
        l10nDeadName = UISetUtils.GetL10NTextByKey("FFA_YOU")
        pLinearColor = UIResourceDef.COLOR.RED.LINEAR_COLOR
    elseif BattleTeammateSystem:CheckTeammateWithSelf(nDeadInstanceId) then
        l10nDeadName = L10N:Format(UISetUtils.GetL10NTextByKey("FFA_YOUR_TEAM_MEMBER"), szDeadName)
        pLinearColor = UIResourceDef.COLOR.RED.LINEAR_COLOR
        -- ktxtKillerName:SetColorAndOpacity(UIResourceDef.COLOR.RED.LINEAR_COLOR)
        -- ktxtDieName:SetColorAndOpacity(UIResourceDef.COLOR.RED.LINEAR_COLOR)
        -- pWidgetRef.imgAttackMethod:SetColorAndOpacity(UIResourceDef.COLOR.RED.LINEAR_COLOR)
        -- pWidgetRef.imgState:SetColorAndOpacity(UIResourceDef.COLOR.RED.LINEAR_COLOR)
        -- bDeadTeamMember = true
    end
    -- if not bKillerTeamMember and not bDeadTeamMember then
    --     ktxtKillerName:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.LINEAR_COLOR)
    --     ktxtDieName:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.LINEAR_COLOR)
    --     pWidgetRef.imgAttackMethod:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.LINEAR_COLOR)
    --     pWidgetRef.imgState:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.LINEAR_COLOR)
    -- end
    ktxtKillerName:SetColorAndOpacity(pLinearColor)
    ktxtDieName:SetColorAndOpacity(pLinearColor)
    pWidgetRef.txtSouceDamage:SetColorAndOpacity(pLinearColor)
    --pWidgetRef.imgAttackMethod:SetColorAndOpacity(pLinearColor)
    pWidgetRef.imgState:SetColorAndOpacity(pLinearColor)

    local l10nDamageFormat = nil
    if l10nWeaponName then
        l10nDamageFormat = L10N:Format(tbToastTemplate.l10nDamageText, l10nWeaponName)
    end

    ktxtKillerName:SetText(l10nKillName)
    pWidgetRef.txtSouceDamage:SetText(l10nDamageFormat)
    ktxtDieName:SetText(l10nDeadName)

    if l10nKillName == nil then
        ktxtKillerName:SetVisibility(ESlateVisibility_Collapsed)
    end
    --attack state
    local szStateIcon = STATE_ICON[nKillType]
    if szStateIcon then
        pWidgetRef.imgState:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        UISetUtils.SetAsyncImageBrushFromSprite(pWidgetRef.imgState, szStateIcon)
    else
        pWidgetRef.imgState:SetVisibility(ESlateVisibility_Collapsed)
    end
    -- --attack method
    -- local tbToastDataTable = FFAToastDataTable:GetTemplate(nAttackMethod, nWeaponTemplateId)
    -- if tbToastDataTable then
    --     pWidgetRef.imgAttackMethod:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    --     local szIcon = tbToastDataTable.szIcon
    --     if szIcon then
    --         UISetUtils.SetAsyncImageBrushFromSprite(pWidgetRef.imgAttackMethod, szIcon)
    --     else
    --         logerror("UPFFAToastItem:ShowToast, Can't find icon in ToastDataTable, nAttackMethod=",nAttackMethod)
    --     end
    -- else
    --     logwarning("UPFFAToastItem:ShowToast, Can't find attack method in ToastDataTable, nAttackMethod=",nAttackMethod)
    --     pWidgetRef.imgAttackMethod:SetVisibility(ESlateVisibility_Collapsed)
    -- end

    if nWaitTime ~= nil and nWaitTime > 0 then
        self.nWaitTime = nWaitTime
    else
        self.nWaitTime = DEFAULT_WAIT_TIME
    end
    self:PlayAnimation("FadeInAnim", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UPFFAToastItem:HideToast()
    self.TimerHelper:ClearAllTimer()
    self:PlayAnimation("FadeOutAnim", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

return UPFFAToastItem
