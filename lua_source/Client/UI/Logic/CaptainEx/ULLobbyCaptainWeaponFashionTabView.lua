local luaclass = require("luaclass")
local ULLobbyCaptainTabViewBase = require("ULLobbyCaptainTabViewBase")

local ULLobbyCaptainWeaponFashionTabView = luaclass("ULLobbyCaptainWeaponFashionTabView", ULLobbyCaptainTabViewBase)

local ClientEventDef = require("ClientEventDef")
local LobbyCaptainShortCutOperator = require("LobbyCaptainShortCutOperator")
local LobbyHumanWeapon3DOperator = require("LobbyHumanWeapon3DOperator")
local LobbyCaptainAvatarEffectInstruction = require("LobbyCaptainAvatarEffectInstruction")
local ItemSystem = require("ItemSystem")
local LobbyCaptainWeaponFashionTitleOperator = require("LobbyCaptainWeaponFashionTitleOperator")
local LobbyHumanFashion3DOperator = require("LobbyHumanFashion3DOperator")
local LobbyWeaponMiscDataTable = require("LobbyWeaponMiscDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local LobbySubLevelDataTable = require("LobbySubLevelDataTable")
local LobbySubTypeDef = require("LobbySubTypeDef")
local UIDef = require("UIDef")
local SaveGameDef = require("SaveGameDef")
local LobbyCaptainWeaponFashionToastOperator = require("LobbyCaptainWeaponFashionToastOperator")
local LobbyCaptainWeaponFashionRedDotOperator = require("LobbyCaptainWeaponFashionRedDotOperator")
local ItemCategoryDef = require("ItemCategoryDef")
local UILobbyCaptainHelper = require("UILobbyCaptainHelper")


ULLobbyCaptainWeaponFashionTabView.ShortcutOperator = nil
ULLobbyCaptainWeaponFashionTabView.EffectInstruction = nil
ULLobbyCaptainWeaponFashionTabView.TitleOperator = nil
ULLobbyCaptainWeaponFashionTabView.HumanFashion3DOperator = nil
ULLobbyCaptainWeaponFashionTabView.WeaponFashion3DOperator = nil

ULLobbyCaptainWeaponFashionTabView.nTargetTemplateId = nil
ULLobbyCaptainWeaponFashionTabView.nCurrentMode = nil

local DISPLAY_MODE = 
{
    HUMAN  = 1,
    WEAPON = 2,
}

local TAG_INDEX = 
{
    [DISPLAY_MODE.WEAPON] = 2,
    [DISPLAY_MODE.HUMAN] = 3
}

local function UpdateFashion(self, nWeaponInstanceType, bUpdateRotate)
    if self.nCurrentMode == DISPLAY_MODE.HUMAN then
        self.HumanFashion3DOperator:ChangeWeapon(nWeaponInstanceType, self.nTargetTemplateId)
    else
        local tbDisplayMiscData = LobbyWeaponMiscDataTable:GetDisplayMiscData(nWeaponInstanceType, LobbyWeaponMiscDataTable.DisplayKey.UICaptain)
        self.WeaponFashion3DOperator:Display(nWeaponInstanceType, self.nTargetTemplateId, tbDisplayMiscData)
    end
end

local function UpdateCurrentTargetTemplateId(self)
    self.nTargetTemplateId = nil
    local nWeaponInstanceType = self.nCurrentCategoryIndex
    local nTemplateId = self.DataOperator:GetFashionData(nWeaponInstanceType)

    if nTemplateId then
        self.nTargetTemplateId = nTemplateId
    else
        local tbItem = ItemSystem:GetEquippedWeaponFashionItem(nWeaponInstanceType)
        if tbItem then
            self.nTargetTemplateId = tbItem:GetTemplateId()
        end
    end
end


local function UpdateEffectInstruction(self)
    if self.nTargetTemplateId then
        local tbTemplate = ItemSystem:GetItemTemplate(self.nTargetTemplateId)
        local tbEffectIds = tbTemplate.tbEffects
        self.EffectInstruction:Show(tbEffectIds)
    else
        self.EffectInstruction:Hide()
    end
end

local function UpdateShortcutOperator(self)
    local nTargetTemplateId = self.nTargetTemplateId
    local bShow = false
    if nTargetTemplateId then
        local tbItems = ItemSystem:GetItemsByTemplateId(nTargetTemplateId)
        if #tbItems > 0 then
            bShow = false
        else
            bShow = true
        end
    else
        bShow = false
    end

    if bShow then
        local tbTemplate = ItemSystem:GetItemTemplate(nTargetTemplateId)
        self.ShortcutOperator:ShowShortcut(tbTemplate)
    else
        self.ShortcutOperator:HideShortCut()
    end
end

local function OnFittingItem(self, nItemTemplateId, tbItemTemplate)
    UpdateCurrentTargetTemplateId(self)
    UpdateEffectInstruction(self)
    UpdateShortcutOperator(self)
    UpdateFashion(self, self.nCurrentCategoryIndex)
end

local function OnUnfittingItem(self, nItemTemplateId, tbItemTemplate)
    UpdateCurrentTargetTemplateId(self)
    UpdateEffectInstruction(self)
    UpdateShortcutOperator(self)
    UpdateFashion(self, self.nCurrentCategoryIndex)
end

local function FindIndex(tbDatas, nTemplateId)
    local nTemp = 1
    for _, tbData in ipairs(tbDatas) do
        if tbData.nTemplateId == nTemplateId then
            return nTemp
        end
        nTemp = nTemp + 1
    end
    return -1
end


local function SetSelectedIndex(self, tbDatas)
    local nIndex
    local nItemTemplateId = self.DataOperator:GetFashionData(self.nCurrentCategoryIndex)
    if nItemTemplateId then
        nIndex = FindIndex(tbDatas, nItemTemplateId)
    else
        nIndex = -1
        for nIdx = 1, #tbDatas do
            local tbData = tbDatas[nIdx]
            if tbData.bEquiped then
                nIndex = nIdx
                break
            end
        end
    end
    self.DataPicker:SetSelectedIndexState(nIndex)
end

local function CheckDataMatch(tbTakeOffInstanceIds, tbPutOnInstanceIds)
    return UILobbyCaptainHelper.CheckDataMatch(tbTakeOffInstanceIds, ItemCategoryDef.HUMAN_WEAPON_FASHION)
        or UILobbyCaptainHelper.CheckDataMatch(tbPutOnInstanceIds, ItemCategoryDef.HUMAN_WEAPON_FASHION)
end

local function OnFashionDoChanged(self, tbTakeOffInstanceIds, tbPutOnInstanceIds)
    if CheckDataMatch(tbTakeOffInstanceIds, tbPutOnInstanceIds) then
        self.DataOperator:OnFashionDoChanged(tbTakeOffInstanceIds, tbPutOnInstanceIds)
        self:RefreshCurrentDataPicker(false)
        UpdateCurrentTargetTemplateId(self)
        UpdateEffectInstruction(self)
        UpdateShortcutOperator(self)
        UpdateFashion(self, self.nCurrentCategoryIndex)
    end
end

local function CreateShortCutOperator(self)
    self.ShortcutOperator = LobbyCaptainShortCutOperator()
    self.ShortcutOperator:Init(self)
end

local function DestroyShortCutOperator(self)
    if self.ShortcutOperator then
        self.ShortcutOperator:Uninit()
        self.ShortcutOperator = nil
    end
end

local function CreateTitleOperator(self)
    self.TitleOperator = LobbyCaptainWeaponFashionTitleOperator()
    self.TitleOperator:Init(self)
end

local function DestroyTitleOperator(self)
    if self.TitleOperator then
        self.TitleOperator:Uninit()
        self.TitleOperator = nil
    end
end

local function CreateToastOperator(self)
    self.LobbyCaptainWeaponFashionToastOperator = LobbyCaptainWeaponFashionToastOperator()
    self.LobbyCaptainWeaponFashionToastOperator:Init()
end

local function DestroyToastOperator(self)
    if self.LobbyCaptainWeaponFashionToastOperator then
        self.LobbyCaptainWeaponFashionToastOperator:Uninit()
        self.LobbyCaptainWeaponFashionToastOperator = nil
    end
end

local function CreateEffectInstruction(self)
    self.EffectInstruction = LobbyCaptainAvatarEffectInstruction()
    self.EffectInstruction:Init(self)
end

local function DestroyEffectInstruction(self)
    if self.EffectInstruction then
        self.EffectInstruction:Uninit()
        self.EffectInstruction = nil
    end
end

local function Set3DOperatorLocationAndRotation(self, tbOperator, szUIWnd, nIndex)
    local tbSubLevelTemplate = LobbySubLevelDataTable:GetTemplate(LobbySubTypeDef.CAPTAIN, szUIWnd)
    assert(tbSubLevelTemplate)
    local szActorTag = tbSubLevelTemplate.tbActorTag[nIndex]
    if not szActorTag then
        logerror("LobbyCaptainArmorFeature, szActorTag is invalid.")
        return
    end
    local pLoctaion, pRotator = self.tbOwnerSystem:GetLocationAndRotationByTag(LobbySubTypeDef.CAPTAIN, szUIWnd, szActorTag)
    if pLoctaion then
        tbOperator:SetActorLocation(pLoctaion)
    end
    if pRotator then
        tbOperator:SetActorRotator(pRotator)
    end
end

local function CreateHuman3DOperator(self)
    self.HumanFashion3DOperator = LobbyHumanFashion3DOperator()
    local tbParam = {}
    tbParam.bdrWidget = self.pWidgetRef.kmBdrActor
    self.HumanFashion3DOperator:Init(tbParam)
    Set3DOperatorLocationAndRotation(self, self.HumanFashion3DOperator, UIDef.UI_LOBBY_CAPTAIN_VISUAL, TAG_INDEX[DISPLAY_MODE.HUMAN])

    local tbPlayer = GamePlayerSelfHelper:Get()
    local nAvatarId = tbPlayer.LobbyPropertyComponent:GetHumanTemplateId()
    local tbAppearanceId = tbPlayer.AppearanceComponent:GetAppearanceIds()
    local tbItems = ItemSystem:GetEquippedFashionItems()
    local tbFashionTemplateIds = {}
    for _, tbItem in ipairs(tbItems) do
        table.insert(tbFashionTemplateIds, tbItem:GetTemplateId())
    end
    self.HumanFashion3DOperator:Display(nAvatarId, tbFashionTemplateIds, tbAppearanceId)
end

local function DestroyHuman3DOperator(self)
    if self.HumanFashion3DOperator then
        self.HumanFashion3DOperator:Uninit()
        self.HumanFashion3DOperator = nil
    end
end

local function CreateWeapon3DOperator(self)
    self.WeaponFashion3DOperator = LobbyHumanWeapon3DOperator()
    local tbParam = {}
    tbParam.bdrWidget = self.pWidgetRef.kmBdrActor
    self.WeaponFashion3DOperator:Init(tbParam)
    Set3DOperatorLocationAndRotation(self, self.WeaponFashion3DOperator, UIDef.UI_LOBBY_CAPTAIN_VISUAL, TAG_INDEX[DISPLAY_MODE.WEAPON])
end

local function DestroyWeapon3DOperator(self)
    if self.WeaponFashion3DOperator then
        self.WeaponFashion3DOperator:Uninit()
        self.WeaponFashion3DOperator = nil
    end
end

local function GetDefaultMode(self)
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    local nMode = pSaveGameMgr:GetIntDataWithDefault(SaveGameDef.LOBBY_CAPTAIN_WEAPON_MODE  , DISPLAY_MODE.HUMAN)
    return nMode
end

local function SaveMode(self, nMode)
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    pSaveGameMgr:AddIntData(SaveGameDef.LOBBY_CAPTAIN_WEAPON_MODE, nMode)
    pSaveGameMgr:Save()
end

local function InitMode(self)
    self.nCurrentMode = GetDefaultMode(self)
end

local function _UpdateCamera(self, nMode)
    if nMode == DISPLAY_MODE.HUMAN or nMode == DISPLAY_MODE.WEAPON then
        self.tbOwnerSystem:SetCamera(UIDef.UI_LOBBY_CAPTAIN_VISUAL, TAG_INDEX[nMode])
        -- self.tbOwnerSystem:SetCameraWithBlend(UIDef.UI_LOBBY_CAPTAIN_VISUAL, TAG_INDEX[nMode], 0.5, EViewTargetBlendFunction.VTBlend_EaseOut, 5)
    else
        logerror("ULLobbyCaptainWeaponFashionTabView, UpdateCamera error, mode : ", nMode)
    end
end

local function Activate3DOpeartorByMode(self, nMode)
    if nMode == DISPLAY_MODE.HUMAN then
        self.WeaponFashion3DOperator:Deactivate()
        self.HumanFashion3DOperator:Activate()
    elseif nMode == DISPLAY_MODE.WEAPON then
        self.HumanFashion3DOperator:Deactivate()
        self.WeaponFashion3DOperator:Activate()
    else
        logerror("ULLobbyCaptainWeaponFashionTabView, Activate3DOpeartorByMode error, mode : ", nMode)
    end
end

local function Deactivate3DOpeartorByMode(self, nMode)
    if nMode == DISPLAY_MODE.HUMAN and self.HumanFashion3DOperator then
        self.HumanFashion3DOperator:Deactivate()
    elseif nMode == DISPLAY_MODE.WEAPON and self.WeaponFashion3DOperator then
        self.WeaponFashion3DOperator:Deactivate()
    end
end

local function OnModeChanged(self, bChecked)
    if bChecked then
        self.nCurrentMode = DISPLAY_MODE.WEAPON
    else
        self.nCurrentMode = DISPLAY_MODE.HUMAN
    end
    Activate3DOpeartorByMode(self, self.nCurrentMode)
    UpdateFashion(self, self.nCurrentCategoryIndex)
    SaveMode(self, self.nCurrentMode)
    -- UpdateCamera(self, self.nCurrentMode)
end

local function SetModeCheckBoxState(self, bChecked)
    self.pWidgetRef.chboxWeaponMode:SetIsChecked(bChecked)
    OnModeChanged(self, bChecked)
    UpdateFashion(self, self.nCurrentCategoryIndex)
end

local function SetModeOperateState(self, bActive)
    if bActive then
        self.pWidgetRef.chboxWeaponMode:SetVisibility(ESlateVisibility_Visible)
    else    
        self.pWidgetRef.chboxWeaponMode:SetVisibility(ESlateVisibility_Collapsed)
    end
end

local function CreateRedDotOperator(self)
    self.LobbyCaptainWeaponFashionRedDotOperator = LobbyCaptainWeaponFashionRedDotOperator()
    self.LobbyCaptainWeaponFashionRedDotOperator:Init(self)
end

local function DestroyRedDotOperator(self)
    if self.LobbyCaptainWeaponFashionRedDotOperator then
        self.LobbyCaptainWeaponFashionRedDotOperator:Uninit()
        self.LobbyCaptainWeaponFashionRedDotOperator = nil
    end
end

local function ActivateRedDotOperator(self)
    if self.LobbyCaptainWeaponFashionRedDotOperator then
        self.LobbyCaptainWeaponFashionRedDotOperator:Activate()
    end
end

local function DeactivateRedDotOperator(self)
    if self.LobbyCaptainWeaponFashionRedDotOperator then
        self.LobbyCaptainWeaponFashionRedDotOperator:Deactivate()
    end
end

function ULLobbyCaptainWeaponFashionTabView:GetPickerClass()
    return "LobbyCaptainDataPicker"
end

function ULLobbyCaptainWeaponFashionTabView:GetFilterClass()
    return "LobbyCaptainWeaponFashionFilterImpl"
end

function ULLobbyCaptainWeaponFashionTabView:GetDataOperatorClass()
    return "LobbyCaptainWeaponFashionDataOperator"
end

function ULLobbyCaptainWeaponFashionTabView:Init(tbOwnerSystem)
    ULLobbyCaptainWeaponFashionTabView.super.Init(self, tbOwnerSystem)
    SetModeOperateState(self, false)
end


function ULLobbyCaptainWeaponFashionTabView:Uninit()
    ULLobbyCaptainWeaponFashionTabView.super.Uninit(self)
end


function ULLobbyCaptainWeaponFashionTabView:Activate(tbParams)
    CreateHuman3DOperator(self)
    CreateWeapon3DOperator(self)
    CreateShortCutOperator(self)
    CreateToastOperator(self)
    CreateEffectInstruction(self)
    CreateTitleOperator(self)
    CreateRedDotOperator(self)
    InitMode(self)
    ULLobbyCaptainWeaponFashionTabView.super.Activate(self, tbParams)
    SetModeOperateState(self, true)
    SetModeCheckBoxState(self, self.nCurrentMode == DISPLAY_MODE.WEAPON)
    -- Activate3DOpeartorByMode(self,  self.nCurrentMode)
    ActivateRedDotOperator(self)
end


function ULLobbyCaptainWeaponFashionTabView:Deactivate()
    DeactivateRedDotOperator(self)
    SetModeOperateState(self, false)
    Deactivate3DOpeartorByMode(self,  self.nCurrentMode)
    ULLobbyCaptainWeaponFashionTabView.super.Deactivate(self)
    DestroyToastOperator(self)
    DestroyRedDotOperator(self)
    DestroyWeapon3DOperator(self)
    DestroyHuman3DOperator(self)
    DestroyTitleOperator(self)
    DestroyShortCutOperator(self)
    DestroyEffectInstruction(self)
end

function ULLobbyCaptainWeaponFashionTabView:BindEventOnActivate()
    ULLobbyCaptainWeaponFashionTabView.super.BindEventOnActivate(self)
    self.TitleOperator:BindEventOnActivate()
    self.ShortcutOperator:BindEventOnActivate()
    self.EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_CAPTAIN_FITTING_AVATAR_ITEM, self, OnFittingItem)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_CAPTAIN_UNFITTING_AVATAR_ITEM, self, OnUnfittingItem)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_FASHION_DO_CHANGED, self, OnFashionDoChanged)
    self.SwitchModeDelegate = self.EventHelper:RegisterCppDelegate(self.pWidgetRef.chboxWeaponMode.OnCheckStateChanged, self, OnModeChanged)
end

function ULLobbyCaptainWeaponFashionTabView:UnbindEventOnDeactivate()
    ULLobbyCaptainWeaponFashionTabView.super.UnbindEventOnDeactivate(self)
    self.TitleOperator:UnbindEventOnDeactivate()
    self.ShortcutOperator:UnbindEventOnDeactivate()
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_LOBBY_CAPTAIN_FITTING_AVATAR_ITEM, self, OnFittingItem)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_LOBBY_CAPTAIN_UNFITTING_AVATAR_ITEM, self, OnUnfittingItem)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_LOBBY_FASHION_DO_CHANGED, self, OnFashionDoChanged)
    self.EventHelper:UnregisterCppDelegate(self.SwitchModeDelegate)
end

function ULLobbyCaptainWeaponFashionTabView:OnPickItem(nItemTemplateId)
    ULLobbyCaptainWeaponFashionTabView.super.OnPickItem(self, nItemTemplateId)
    self.LobbyCaptainWeaponFashionToastOperator:OnPickItem(nItemTemplateId)
end

function ULLobbyCaptainWeaponFashionTabView:ProcessActivateParams(tbParams)
    if tbParams and tbParams.nItemTemplateId then
        local tbItemTemplate = ItemSystem:GetItemTemplate(tbParams.nItemTemplateId)
        self.nCurrentCategoryIndex = tbItemTemplate.nSubCategory
    end
end

function ULLobbyCaptainWeaponFashionTabView:OnCategoryTabChanged()
    local nWeaponInstanceType = self.nCurrentCategoryIndex
    self.DataOperator:ClearAllFashionData()
    self.TitleOperator:SetTitleInfo({nWeaponInstanceType = nWeaponInstanceType})
    self.TitleOperator:SetTipCheckState(false)
    UpdateCurrentTargetTemplateId(self)
    UpdateEffectInstruction(self)
    UpdateShortcutOperator(self)
    UpdateFashion(self, self.nCurrentCategoryIndex)
end

function ULLobbyCaptainWeaponFashionTabView:RefreshCurrentDataPicker(bResort)
    local tbDatas = ULLobbyCaptainWeaponFashionTabView.super.RefreshCurrentDataPicker(self, bResort)
    -- set index selected
    SetSelectedIndex(self, tbDatas)
    return tbDatas
end

-- lifecycle callback

-- function ULLobbyCaptainWeaponFashionTabView:OnCreate()
-- end

-- function ULLobbyCaptainWeaponFashionTabView:OnDestroy()
-- end

-- function ULLobbyCaptainWeaponFashionTabView:OnLoad()
-- end

-- function ULLobbyCaptainWeaponFashionTabView:OnUnload()
-- end

-- function ULLobbyCaptainWeaponFashionTabView:OnEnter()
-- end

-- function ULLobbyCaptainWeaponFashionTabView:OnShow()
-- end

-- function ULLobbyCaptainWeaponFashionTabView:OnHide()
-- end

-- function ULLobbyCaptainWeaponFashionTabView:OnExit()
-- end

-- function ULLobbyCaptainWeaponFashionTabView:OnBindEvent(EventHelper)
-- end

-- function ULLobbyCaptainWeaponFashionTabView:OnUnbindEvent(EventHelper)
-- end


return ULLobbyCaptainWeaponFashionTabView