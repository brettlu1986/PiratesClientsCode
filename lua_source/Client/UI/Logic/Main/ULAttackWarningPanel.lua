-----------------------------------------------------
--File Name    : ULAttackWarningPanel.lua
--Author       : Song Fuhao
--Create Time  : 2019-01-04
--Description  : 伤害提醒
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULAttackWarningPanel = luaclass("ULAttackWarningPanel", UILogicBase)

local UIDef = require("UIDef")
local ProtoDR = require("DungeonRepProtoNames")
local ClientEventDef = require("ClientEventDef")
local CommonEventDef = require("CommonEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

ULAttackWarningPanel.tbFreeItemList = nil
ULAttackWarningPanel.tbUsedItemMap = nil

local function OnWarningFinished(self, tbWarningItem)
    tbWarningItem.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    table.insert(self.tbFreeItemList, tbWarningItem)
    for k,v in pairs(self.tbUsedItemMap) do
        if v == tbWarningItem then
            self.tbUsedItemMap[k] = nil
            break
        end
    end
end

local function IsValidTaker(self, tbTaker)
    return GamePlayerSelfHelper:Get() == tbTaker
    and tbTaker.pUEActor
end

local function IsValidCauser(self, tbCauser)
    return tbCauser
    and (GamePlayerSelfHelper:Get() ~= tbCauser)
    and (not self.tbUsedItemMap[tbCauser])
    and tbCauser.pUEActor
end

local function GetValidItem(self)
    local nFreeItemLastIdx = #self.tbFreeItemList
    local tbFreeItem = self.tbFreeItemList[nFreeItemLastIdx]
    if tbFreeItem then
        tbFreeItem.pWidgetRef:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.tbFreeItemList[nFreeItemLastIdx] = nil
    else
        tbFreeItem = self.PrefabHelper:CreatePrefab(UIDef.UP_ATTACK_WARNING_ITEM)
        tbFreeItem.OnWarningFinished:Bind(OnWarningFinished, self)

        local pSlot = self.pWidgetRef.ovlAttackWarning:AddChild(tbFreeItem.pWidgetRef)
        pSlot:SetHorizontalAlignment(EHorizontalAlignment.HAlign_Fill)
        pSlot:SetVerticalAlignment(EVerticalAlignment.VAlign_Fill)
    end
    return tbFreeItem
end

local function GetAttackRotationAngle(pTaker, pCauser)
    local pTakerLocation = pTaker:K2_GetActorLocation()
    local pCauserLocation = pCauser:K2_GetActorLocation()
    local pAttackDirection = KismetMathLibrary.Subtract_VectorVector(pCauserLocation, pTakerLocation)
    local nAttackYaw = ExtendBlueprintFunctions.GetYawFromVector(pAttackDirection)

    local pCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    local pCameraRotation = pCameraManager:GetCameraRotation()
    local _, _, nCameraYaw = KismetMathLibrary.BreakRotator(pCameraRotation)

    return KismetMathLibrary.NormalizeAxis(nAttackYaw - nCameraYaw)
end

local function OnTakeDamage(self, tbTaker, tbCauser)
    if IsValidTaker(self, tbTaker) and IsValidCauser(self, tbCauser) then
        local tbWarningItem = GetValidItem(self)
        self.tbUsedItemMap[tbCauser] = tbWarningItem

        local nAngle = GetAttackRotationAngle(tbTaker.pUEActor, tbCauser.pUEActor)
        tbWarningItem:ShowWarning(nAngle)
    end
end

local function OnFFAProcessStateChanged(self, nState)
    -- 跳伞后重置受击提示
    if nState == ProtoDR.rFFAProcessState_EState.PARACHUTING then
        for k, v in pairs(self.tbUsedItemMap) do
            v:InterruptWarning()
        end
    end
end

function ULAttackWarningPanel:OnLoad()
    self.tbFreeItemList = {}
    self.tbUsedItemMap = {}
end

function ULAttackWarningPanel:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_TAKE_DAMAGE, self, OnTakeDamage)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_PROCESS_STATE_CHANGED, self, OnFFAProcessStateChanged)
end

return ULAttackWarningPanel