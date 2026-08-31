local luaclass = require("luaclass")
local ULLobbyCaptainTabViewBase = require("ULLobbyCaptainTabViewBase")

local ULLobbyCaptainHumanFashionTabView = luaclass("ULLobbyCaptainHumanFashionTabView", ULLobbyCaptainTabViewBase)

local ClientEventDef                        = require("ClientEventDef")

local ItemSystem                            = require("ItemSystem")
local ItemDataTable                         = require("ItemDataTable")
local HumanAvatarHelper                     = require("HumanAvatarHelper")
local LobbyCaptainMiscDef                   = require("LobbyCaptainMiscDef")
local UIResourceDef                         = require("UIResourceDef")
local HumanAvatarDef                        = require("HumanAvatarDef")
local LobbyCaptainShortCutOperator          = require("LobbyCaptainShortCutOperator")
local LobbyCaptainHumanFashionTitleOperator = require("LobbyCaptainHumanFashionTitleOperator")
local LobbyCaptainHumanFashionFlagOperator  = require("LobbyCaptainHumanFashionFlagOperator")
local LobbyCaptainHumanFashionToastOperator = require("LobbyCaptainHumanFashionToastOperator")
local LobbyCaptainAvatarEffectInstruction   = require("LobbyCaptainAvatarEffectInstruction")
local LobbyHumanFashion3DOperator           = require("LobbyHumanFashion3DOperator")
local UILobbyCaptainHelper                  = require("UILobbyCaptainHelper")
local HumanArmorDef                         = require("HumanArmorDef")
local GamePlayerSelfHelper                  = require("GamePlayerSelfHelper")
local LobbySubLevelDataTable                = require("LobbySubLevelDataTable")
local LobbySubTypeDef                       = require("LobbySubTypeDef")
local UIDef                                 = require("UIDef")
local ItemCategoryDef                       = require("ItemCategoryDef")
local LobbyCaptainHumanFashionRedDotOperator= require("LobbyCaptainHumanFashionRedDotOperator")


local FashionSlotCategoryExtend = HumanAvatarDef.FashionSlotCategoryExtend
local FashionSlotCategoryExtendToTabIndex = LobbyCaptainMiscDef.FashionSlotCategoryExtendToTabIndex
local TabIndexToFashionSlotCategoryExtend = LobbyCaptainMiscDef.TabIndexToFashionSlotCategoryExtend
local FashionType = HumanAvatarDef.FashionType
local FashionSlotCategory = HumanAvatarDef.FashionSlotCategory

local tbDefaultIcons = UIResourceDef.LOBBY_HUMAN_SLOT_ICON
ULLobbyCaptainHumanFashionTabView.ShortcutOperator = nil
ULLobbyCaptainHumanFashionTabView.EffectInstruction = nil
ULLobbyCaptainHumanFashionTabView.TitleOperator = nil
ULLobbyCaptainHumanFashionTabView.HumanFashion3DOperator = nil

ULLobbyCaptainHumanFashionTabView.nTargetTemplateId = nil

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

local function GetCurrentDisplayFashionTemplates(self, nFashionType)
    local tbResult = {}
    local tbFittingData = self.DataOperator:GetFashionData(nFashionType)
    for _, nSlotType in pairs(FashionSlotCategory) do
        local nFittingTemplateId = tbFittingData[nSlotType]
        if nFittingTemplateId then
            table.insert(tbResult, nFittingTemplateId)
        else
            local tbItem = ItemSystem:GetEquipedFashionItem(nFashionType, nSlotType)
            if tbItem then
                local nEquipedItemTemplateId = tbItem:GetTemplateId()
                table.insert(tbResult, nEquipedItemTemplateId)
            end
        end
    end

    if nFashionType ~= FashionType.Basic then
        local tbItems = ItemSystem:GetEquipedFashionItemsByType(FashionType.Basic)
        for _, tbItem in ipairs(tbItems) do
            local nItemIntanceId = tbItem:GetTemplateId()
            table.insert(tbResult, nItemIntanceId)
        end
    end
    return tbResult
end

local function ShowFashion(self, nFashionType, bUpdateRotate, bOverride)
    local tbPlayer = GamePlayerSelfHelper:Get()
    local nAvatarId = tbPlayer.LobbyPropertyComponent:GetAvatarId()
    local tbAppearanceId = tbPlayer.AppearanceComponent:GetAppearanceIds()
    local tbFashionTemplateIds = GetCurrentDisplayFashionTemplates(self, self.nCurrentCategoryIndex)

    if nFashionType == FashionType.Basic then
        self.HumanFashion3DOperator:SetArmorTypeAndLevel(nil, nil)
    else
        local nArmorType = HumanAvatarHelper.FashionTypeToArmorType[nFashionType]
        self.HumanFashion3DOperator:SetArmorFashionFlag(nArmorType, bOverride)
        self.HumanFashion3DOperator:SetArmorTypeAndLevel(nArmorType, HumanArmorDef.MAX_LEVEL)
    end

    local szAnimKey = UILobbyCaptainHelper.GetHumanAnimationByFashionType(nFashionType)
    self.HumanFashion3DOperator:SetAnimation(szAnimKey)
    self.HumanFashion3DOperator:Display(nAvatarId, tbFashionTemplateIds, tbAppearanceId, bUpdateRotate)
end

local function UpdateCurrentTargetTemplateId(self)
    self.nTargetTemplateId = nil
    local nFashionType = self.nCurrentCategoryIndex
    local nSlotType = TabIndexToFashionSlotCategoryExtend[self.nCurrentSubCategoryIndex]
    local tbTempFashionData = self.DataOperator:GetFashionData(nFashionType)
    if nSlotType == FashionSlotCategoryExtend.Suit then
        self.nTargetTemplateId = self.DataOperator:FindSuitComposed(nFashionType)
    else
        local nTemplateId = tbTempFashionData[nSlotType]
        if nTemplateId then
            self.nTargetTemplateId = nTemplateId
        else
            local tbItem = ItemSystem:GetEquipedFashionItem(nFashionType, nSlotType)
            if tbItem then
                self.nTargetTemplateId = tbItem:GetTemplateId()
            end
        end
    end
end


local function IsOverrideByBasic(self, nFashionType)
    local bOverride = self.FlagOperator:IsOverrideByBasic(nFashionType)
    return bOverride
end


local function UpdateEffectInstruction(self)
    local bOverride = IsOverrideByBasic(self, self.nCurrentCategoryIndex)
    if bOverride and self.nCurrentCategoryIndex ~= FashionType.Basic then
        self.EffectInstruction:Hide()
        return
    end
    if self.nTargetTemplateId then
        local tbTemplate = ItemSystem:GetItemTemplate(self.nTargetTemplateId)
        local tbEffectIds = tbTemplate.tbEffects
        self.EffectInstruction:Show(tbEffectIds)
    else
        self.EffectInstruction:Hide()
    end
end

local function UpdateShortcutOperator(self)
    local bOverride = IsOverrideByBasic(self, self.nCurrentCategoryIndex)
    if bOverride and self.nCurrentCategoryIndex ~= FashionType.Basic then
        self.ShortcutOperator:HideShortCut()
        return
    end
    local nTargetTemplateId = self.nTargetTemplateId
    local bShow = false
    local tbTemplate
    if nTargetTemplateId then
        tbTemplate = ItemSystem:GetItemTemplate(nTargetTemplateId)
        if tbTemplate.nCategory ~= ItemCategoryDef.SUIT then
            local nSuitTemplateId = tbTemplate.nSuitId
            if nSuitTemplateId then  -- 看套装
                nTargetTemplateId = nSuitTemplateId
                tbTemplate = ItemSystem:GetItemTemplate(nTargetTemplateId)
            end
        end
        local bHas, _ = ItemSystem:HasFashionItem(nTargetTemplateId)
        bShow = not bHas
    end

    if bShow then
        self.ShortcutOperator:ShowShortcut(tbTemplate)
    else
        self.ShortcutOperator:HideShortCut()
    end
end

local function UpdateSubCategoryTabContent(self)
    local tbItems = ItemSystem:GetEquipedFashionItemsByType(self.nCurrentCategoryIndex)
    local tItemMap = {}
    for _, tbItem in ipairs(tbItems) do
        local nSlot = tbItem:GetSubCategory()
        tItemMap[nSlot] = tbItem
    end
    local tbSlotState = {}
    local tbSuitToCheck = {}
    for _, nSlot in ipairs(HumanAvatarHelper.PRIORITY_ORDER) do
        local tbItem = tItemMap[nSlot]
        local nTabIndex = FashionSlotCategoryExtendToTabIndex[nSlot]
        if not tbSlotState[nSlot] then
            self.tbSubCategoryTabHelper:SetOverlayIconVisible(nTabIndex, false)
        end

        if tbItem then
            local nTemplateId = tbItem:GetTemplateId()
            local tbItemTemplate = tbItem:GetTemplate()
            local tbResTemplate = ItemDataTable:GetResTemplate(nTemplateId)
            local szIcon = tbResTemplate.szIconPath
            local tbOverlaySlots = tbItemTemplate.tbOverlaySlots
            for _, nOverlaySlot in ipairs(tbOverlaySlots) do
                tbSlotState[nOverlaySlot] = true
                local nSlotIndex = FashionSlotCategoryExtendToTabIndex[nOverlaySlot]
                self.tbSubCategoryTabHelper:SetOverlayIconVisible(nSlotIndex, true)
            end
            self.tbSubCategoryTabHelper:SetTabIcon(nTabIndex, szIcon, szIcon)
            local nSuitId = tbItemTemplate.nSuitId
            if nSuitId and nSuitId > 0 then
                local tbSuit = tbSuitToCheck[nSuitId]
                if not tbSuit then
                    tbSuit = {}
                    tbSuitToCheck[nSuitId] = tbSuit
                end
                table.insert(tbSuit, nTemplateId)
            end
        else
            self.tbSubCategoryTabHelper:SetTabIcon(nTabIndex, tbDefaultIcons[nSlot][1], tbDefaultIcons[nSlot][2])
        end
    end

    -- set suit tab
    local nSuitSlot = FashionSlotCategoryExtend.Suit
    local nSuitTabIndex = FashionSlotCategoryExtendToTabIndex[nSuitSlot]
    self.tbSubCategoryTabHelper:SetOverlayIconVisible(nSuitTabIndex, false)
    self.tbSubCategoryTabHelper:SetTabIcon(nSuitTabIndex, tbDefaultIcons[nSuitSlot][1], tbDefaultIcons[nSuitSlot][2])
    for nSuitId, tbValue in pairs(tbSuitToCheck) do
        -- if tbValue then
        local tbSuitItemTemplate = ItemDataTable:GetTemplate(nSuitId)
        local tbResTemplate = ItemDataTable:GetResTemplate(nSuitId)
        local szIcon = tbResTemplate.szIconPath
        local nCount = #tbSuitItemTemplate.tbSubItemTemplateIds
        if nCount == #tbValue then
            self.tbSubCategoryTabHelper:SetTabIcon(nSuitTabIndex, szIcon, szIcon)
            break
        else
            self.tbSubCategoryTabHelper:SetTabIcon(nSuitTabIndex, tbDefaultIcons[nSuitSlot][1], tbDefaultIcons[nSuitSlot][2])
        end
    end
end

local function SetSelectedIndex(self, tbDatas)
    local tbCurrentFittingFashionData = self.DataOperator:GetFashionData(self.nCurrentCategoryIndex)
    local nSlotCategory = TabIndexToFashionSlotCategoryExtend[self.nCurrentSubCategoryIndex]
    local nIndex
    if nSlotCategory == FashionSlotCategoryExtend.Suit then
        local nSuitTemplateId = self.DataOperator:FindSuitComposed(self.nCurrentCategoryIndex)
        if nSuitTemplateId then
            nIndex = FindIndex(tbDatas, nSuitTemplateId)
        else
            nIndex = -1
        end
    else
        local nItemTemplateId = tbCurrentFittingFashionData[nSlotCategory]
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
    end
    self.DataPicker:SetSelectedIndexState(nIndex)
end

local function OnFittingItem(self, nItemTemplateId, tbItemTemplate)
    UpdateCurrentTargetTemplateId(self)
    UpdateEffectInstruction(self)
    UpdateShortcutOperator(self)
    ShowFashion(self, self.nCurrentCategoryIndex, false)
end

local function OnUnfittingItem(self, nItemTemplateId, tbItemTemplate)
    UpdateCurrentTargetTemplateId(self)
    UpdateEffectInstruction(self)
    UpdateShortcutOperator(self)
    ShowFashion(self, self.nCurrentCategoryIndex, false)
end

local function CheckDataMatch(tbTakeOffInstanceIds, tbPutOnInstanceIds)
    return UILobbyCaptainHelper.CheckDataMatch(tbTakeOffInstanceIds, ItemCategoryDef.FASHION)
        or UILobbyCaptainHelper.CheckDataMatch(tbPutOnInstanceIds, ItemCategoryDef.FASHION)
end

local function OnFashionDoChanged(self, tbTakeOffInstanceIds, tbPutOnInstanceIds)
    if CheckDataMatch(tbTakeOffInstanceIds, tbPutOnInstanceIds) then
        self.DataOperator:OnFashionDoChanged(tbTakeOffInstanceIds, tbPutOnInstanceIds)
        self:RefreshCurrentDataPicker(false)
        UpdateCurrentTargetTemplateId(self)
        UpdateEffectInstruction(self)
        UpdateShortcutOperator(self)
        UpdateSubCategoryTabContent(self)
        ShowFashion(self, self.nCurrentCategoryIndex, false)
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
    self.TitleOperator = LobbyCaptainHumanFashionTitleOperator()
    self.TitleOperator:Init(self)
end

local function DestroyTitleOperator(self)
    if self.TitleOperator then
        self.TitleOperator:Uninit()
        self.TitleOperator = nil
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

local function Set3DOperatorLocationAndRotation(self, szUIWnd)
    local tbSubLevelTemplate = LobbySubLevelDataTable:GetTemplate(LobbySubTypeDef.CAPTAIN, szUIWnd)
    assert(tbSubLevelTemplate)
    local szActorTag = tbSubLevelTemplate.tbActorTag[1]
    if not szActorTag then
        logerror("LobbyCaptainArmorFeature, szActorTag is invalid.")
        return
    end
    local pLoctaion, pRotator = self.tbOwnerSystem:GetLocationAndRotationByTag(LobbySubTypeDef.CAPTAIN, szUIWnd, szActorTag)
    if pLoctaion then
        self.HumanFashion3DOperator:SetActorLocation(pLoctaion)
    end
    if pRotator then
        self.HumanFashion3DOperator:SetActorRotator(pRotator)
    end
end

local function UpdateCamera(self)
    self.tbOwnerSystem:SetCamera(UIDef.UI_LOBBY_CAPTAIN_VISUAL, 1)
end


local function CreateToastOperator(self)
    self.LobbyCaptainHumanFashionToastOperator = LobbyCaptainHumanFashionToastOperator()
    self.LobbyCaptainHumanFashionToastOperator:Init()
end

local function DestroyToastOperator(self)
    if self.LobbyCaptainHumanFashionToastOperator then
        self.LobbyCaptainHumanFashionToastOperator:Uninit()
        self.LobbyCaptainHumanFashionToastOperator = nil
    end
end

local function CreateRedDotOperator(self)
    self.LobbyCaptainHumanFashionRedDotOperator = LobbyCaptainHumanFashionRedDotOperator()
    self.LobbyCaptainHumanFashionRedDotOperator:Init(self)
end

local function DestroyRedDotOperator(self)
    if self.LobbyCaptainHumanFashionRedDotOperator then
        self.LobbyCaptainHumanFashionRedDotOperator:Uninit()
        self.LobbyCaptainHumanFashionRedDotOperator = nil
    end
end

local function ActivateRedDotOperator(self)
    if self.LobbyCaptainHumanFashionRedDotOperator then
        self.LobbyCaptainHumanFashionRedDotOperator:Activate()
    end
end

local function DeactivateRedDotOperator(self)
    if self.LobbyCaptainHumanFashionRedDotOperator then
        self.LobbyCaptainHumanFashionRedDotOperator:Deactivate()
    end
end

local function CreateHuman3DOperator(self)
    self.HumanFashion3DOperator = LobbyHumanFashion3DOperator()
    local tbParam = {}
    tbParam.bdrWidget = self.pWidgetRef.kmBdrActor
    self.HumanFashion3DOperator:Init(tbParam)
    Set3DOperatorLocationAndRotation(self, UIDef.UI_LOBBY_CAPTAIN_VISUAL)
end

local function DestroyHuman3DOperator(self)
    if self.HumanFashion3DOperator then
        self.HumanFashion3DOperator:Uninit()
        self.HumanFashion3DOperator = nil
    end
end

local function ActivateHuman3DOperator(self)
    if self.HumanFashion3DOperator then
        self.HumanFashion3DOperator:Activate()
    end
end

local function DeactivateHuman3DOperator(self)
    if self.HumanFashion3DOperator then
        self.HumanFashion3DOperator:Deactivate()
    end
end

local function CreateFlagOperator(self)
    self.FlagOperator = LobbyCaptainHumanFashionFlagOperator()
    self.FlagOperator:Init(self)
end

local function DestroyFlagOperator(self)
    if self.FlagOperator then
        self.FlagOperator:Uninit()
        self.FlagOperator = nil
    end
end



local function OnFlagModified(self)
    local nFashionType = self.nCurrentCategoryIndex
    UpdateShortcutOperator(self)
    UpdateEffectInstruction(self)
    self.LobbyCaptainHumanFashionToastOperator:OnFlagChanged(nFashionType)
    local bOverride = IsOverrideByBasic(self, nFashionType)
    ShowFashion(self, nFashionType, true, bOverride)
end

function ULLobbyCaptainHumanFashionTabView:GetPickerClass()
    return "LobbyCaptainDataPicker"
end

function ULLobbyCaptainHumanFashionTabView:GetFilterClass()
    return "LobbyCaptainHumanFashionFilterImpl"
end

function ULLobbyCaptainHumanFashionTabView:GetDataOperatorClass()
    return "LobbyCaptainHumanFashionDataOperator"
end

function ULLobbyCaptainHumanFashionTabView:Init(tbOwnerSystem)
    ULLobbyCaptainHumanFashionTabView.super.Init(self, tbOwnerSystem)
end


function ULLobbyCaptainHumanFashionTabView:Uninit()
    ULLobbyCaptainHumanFashionTabView.super.Uninit(self)
end

function ULLobbyCaptainHumanFashionTabView:Activate(tbParams)
    CreateHuman3DOperator(self)
    CreateShortCutOperator(self)
    CreateToastOperator(self)
    CreateEffectInstruction(self)
    CreateTitleOperator(self)
    CreateFlagOperator(self)
    CreateRedDotOperator(self)
    ULLobbyCaptainHumanFashionTabView.super.Activate(self, tbParams)
    UpdateSubCategoryTabContent(self)
    ActivateHuman3DOperator(self)
    ActivateRedDotOperator(self)
    UpdateCamera(self)
end

function ULLobbyCaptainHumanFashionTabView:ProcessActivateParams(tbParams)
    if tbParams and tbParams.nItemTemplateId then
        local tbItemTemplate = ItemSystem:GetItemTemplate(tbParams.nItemTemplateId)
        self.nCurrentCategoryIndex = tbItemTemplate.nFashionType
        if tbItemTemplate.nCategory == ItemCategoryDef.Suit then
            self.nCurrentSubCategoryIndex = FashionSlotCategoryExtendToTabIndex[FashionSlotCategoryExtend.Suit]
        elseif tbItemTemplate.nCategory == ItemCategoryDef.FASHION then
            self.nCurrentSubCategoryIndex = FashionSlotCategoryExtendToTabIndex[tbItemTemplate.nSubCategory]
        end
    end
end

function ULLobbyCaptainHumanFashionTabView:Deactivate()
    DeactivateRedDotOperator(self)
    DeactivateHuman3DOperator(self)
    ULLobbyCaptainHumanFashionTabView.super.Deactivate(self)
    DestroyRedDotOperator(self)
    DestroyToastOperator(self)
    DestroyFlagOperator(self)
    DestroyHuman3DOperator(self)
    DestroyTitleOperator(self)
    DestroyShortCutOperator(self)
    DestroyEffectInstruction(self)
end

function ULLobbyCaptainHumanFashionTabView:BindEventOnActivate()
    ULLobbyCaptainHumanFashionTabView.super.BindEventOnActivate(self)
    self.TitleOperator:BindEventOnActivate()
    self.ShortcutOperator:BindEventOnActivate()
    self.FlagOperator:BindEventOnActivate()
    self.EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_CAPTAIN_FITTING_AVATAR_ITEM, self, OnFittingItem)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_CAPTAIN_UNFITTING_AVATAR_ITEM, self, OnUnfittingItem)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_FASHION_DO_CHANGED, self, OnFashionDoChanged)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_NOTIFY_FASHION_FLAG_CHANGED, self, OnFlagModified)
end

function ULLobbyCaptainHumanFashionTabView:UnbindEventOnDeactivate()
    ULLobbyCaptainHumanFashionTabView.super.UnbindEventOnDeactivate(self)
    self.TitleOperator:UnbindEventOnDeactivate()
    self.ShortcutOperator:UnbindEventOnDeactivate()
    self.FlagOperator:UnbindEventOnDeactivate()
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_LOBBY_CAPTAIN_FITTING_AVATAR_ITEM, self, OnFittingItem)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_LOBBY_CAPTAIN_UNFITTING_AVATAR_ITEM, self, OnUnfittingItem)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_LOBBY_FASHION_DO_CHANGED, self, OnFashionDoChanged)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_NOTIFY_FASHION_FLAG_CHANGED, self, OnFlagModified)
end


function ULLobbyCaptainHumanFashionTabView:OnCategoryTabChanged()
    UpdateSubCategoryTabContent(self)
    local nFashionType = self.nCurrentCategoryIndex
    self.DataOperator:ClearAllFashionData()
    self.TitleOperator:SetTitleInfo({nFashionType = nFashionType})
    self.TitleOperator:SetTipCheckState(false)
    self.FlagOperator:UpdateFashionType(nFashionType)
    self.LobbyCaptainHumanFashionRedDotOperator:UpdateFashionType(nFashionType)
    local bOverride = IsOverrideByBasic(self, nFashionType)
    ShowFashion(self, nFashionType, true, bOverride)
end

function ULLobbyCaptainHumanFashionTabView:OnSubCategoryChanged()
    UpdateCurrentTargetTemplateId(self)
    UpdateEffectInstruction(self)
    UpdateShortcutOperator(self)
end



function ULLobbyCaptainHumanFashionTabView:RefreshCurrentDataPicker(bResort)
    local tbDatas = ULLobbyCaptainHumanFashionTabView.super.RefreshCurrentDataPicker(self, bResort)
    -- set index selected
    SetSelectedIndex(self, tbDatas)
    return tbDatas
end

function ULLobbyCaptainHumanFashionTabView:OnPickItem(nItemTemplateId)
    ULLobbyCaptainHumanFashionTabView.super.OnPickItem(self, nItemTemplateId)
    self.LobbyCaptainHumanFashionToastOperator:OnPickItem(nItemTemplateId, self.DataOperator:GetFashionData(self.nCurrentCategoryIndex))
end

-- lifecycle callback

-- function ULLobbyCaptainHumanFashionTabView:OnCreate()
-- end

-- function ULLobbyCaptainHumanFashionTabView:OnDestroy()
-- end

-- function ULLobbyCaptainHumanFashionTabView:OnLoad()
-- end

-- function ULLobbyCaptainHumanFashionTabView:OnUnload()
-- end

-- function ULLobbyCaptainHumanFashionTabView:OnEnter()
-- end

-- function ULLobbyCaptainHumanFashionTabView:OnShow()
-- end

-- function ULLobbyCaptainHumanFashionTabView:OnHide()
-- end

-- function ULLobbyCaptainHumanFashionTabView:OnExit()
-- end

-- function ULLobbyCaptainHumanFashionTabView:OnBindEvent(EventHelper)
-- end

-- function ULLobbyCaptainHumanFashionTabView:OnUnbindEvent(EventHelper)
-- end


return ULLobbyCaptainHumanFashionTabView