local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULSailorEquippingBase = luaclass("ULSailorEquippingBase", UILogicBase)
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UILobbySailorDef = require("UILobbySailorDef")
local SailorSlotDataTable = require("SailorSlotDataTable")
local UIResourceDef = require("UIResourceDef")
local UISetUtils = require("UISetUtils")
local ClientEventDef = require("ClientEventDef")
local CurrencyIni = require("CurrencyIni")
local CostCurrencyHelper = require("CostCurrencyHelper")

local UIUtils = require("UIUtils")
local L10N = require("L10N")
local UIDef = require("UIDef")

ULSailorEquippingBase.nSailorCategory = nil
ULSailorEquippingBase.szSailorItemBdrName = nil
-- ULSailorEquippingBase.szSailorItemLineName = nil
ULSailorEquippingBase.tbSailorItems = nil

local UNEXCHANGED_ID = CurrencyIni.tbExchange.nUnchangedId

local DRAW_TYPE_NONE = ESlateBrushDrawType.NoDrawType
local DRAW_TYPE_IMAGE = ESlateBrushDrawType.Image
-- local MAX_UNLOCK_LINE = 9
local GRADE_TEXT_OFFSET  = Margin{Left=0, Top=45, Right=0, Bottom=0}
local COIN_TEXT_OFFSET  = Margin{Left=0, Top=45, Right=0, Bottom=0}
local MARGIN_ORIGIN  = Margin{Left=0, Top=0, Right=0, Bottom=0}

local function GetSailorComponent()
    local tbPlayer = GamePlayerSelfHelper:Get()
    return tbPlayer and tbPlayer.SailorComponent
end

local function OnSailorItemSelected(self, pSailorItemScript)
    self.EventHelper:FireEvent(ClientEventDef.EV_LOBBYSAILOR_EQUIPITEM_SELECT, pSailorItemScript)
end

local function UpdateEquippingUnlockState(self, nIndex, tbEquipData)
    if tbEquipData and tbEquipData.bUnlocked then
        local tbSailorItem = self.tbSailorItems[nIndex]
        local pBdrParent = tbSailorItem.pParent
        pBdrParent.Background.DrawAs = DRAW_TYPE_NONE
        if tbSailorItem.pSailorItemScript == nil then
            pBdrParent:ClearChildren()
            tbSailorItem.pSailorItemScript = self.PrefabHelper:CreatePrefab(UIDef.UP_LOBBY_SAILOR_SLOT_ITEM)
            tbSailorItem.pSailorItemScript.OnItemSelected:Bind(OnSailorItemSelected, self)
            local pWidgetRef = tbSailorItem.pSailorItemScript.pWidgetRef
            if pWidgetRef then
                local pSlot = pBdrParent:AddChild(pWidgetRef)
                pSlot:SetPadding(MARGIN_ORIGIN)
                pSlot:SetHorizontalAlignment(EHorizontalAlignment.HAlign_Center)
                pSlot:SetVerticalAlignment(EVerticalAlignment.VAlign_Center)
            end
        end
        -- if nIndex <= MAX_UNLOCK_LINE then
        --     local szWidgetName = string.format(self.szSailorItemLineName, nIndex)
        --     local pTargetRef = self.pWidgetRef[szWidgetName]
        --     UISetUtils.SetImageBrushColor(pTargetRef, UIResourceDef.COLOR.YELLOW1)
        -- end
        tbSailorItem.pSailorItemScript:SetSlotInfo(self.nSailorCategory, nIndex)
        tbSailorItem.pSailorItemScript:SetEquippingData(tbEquipData)
        tbSailorItem.nState = UILobbySailorDef.EquippingItemState.UNLOCK
    end
end

local function CreateTextBlockWithText(self, szText, pParent, pPaddingOffset)
    local WidgetHelper = self.WidgetHelper
    pParent:ClearChildren()
    local pTextBlock = WidgetHelper:CreateWidget(TextBlock)
    pTextBlock:SetText(szText)
    UISetUtils.SetTextblockFont(pTextBlock, UIResourceDef.FFA_FONT_RES_PINGFANG:load(), "Bold")
    UISetUtils.SetTextblockFontSize(pTextBlock, UIResourceDef.FONT_SIZE.NORMAL3)
    local pSlot = pParent:AddChild(pTextBlock)
    pSlot:SetPadding(pPaddingOffset)
    pSlot:SetHorizontalAlignment(EHorizontalAlignment.HAlign_Center)
    pSlot:SetVerticalAlignment(EVerticalAlignment.VAlign_Center)
end

local function UpdateEquippingLockStateByGrade(self, nIndex, nUnlockGrade)
    local tbSailorItem = self.tbSailorItems[nIndex]
    tbSailorItem.nState = UILobbySailorDef.EquippingItemState.LOCK_WITH_GRADE
    CreateTextBlockWithText(self, L10N:Format(UISetUtils.GetL10NTextByKey("SAILOR_SLOT_LEVEL_TIPS"), nUnlockGrade),
         tbSailorItem.pParent, GRADE_TEXT_OFFSET)
end

local function UpdateEquippingLockStateByCoin(self, nIndex, nUnlockGrade)
    local tbSailorItem = self.tbSailorItems[nIndex]
    tbSailorItem.nState = UILobbySailorDef.EquippingItemState.LOCK_WITH_COIN
    tbSailorItem.pParent.Background.DrawAs = DRAW_TYPE_IMAGE
    UISetUtils.SetBorderBrushRes(tbSailorItem.pParent, UIResourceDef.LOBBY_SAILOR_LOCK_COIN:load(), true)
    CreateTextBlockWithText(self, UISetUtils.GetL10NTextByKey("UI_STATIC_ACCESSOROYSHIP_UNLOCK"),
        tbSailorItem.pParent, COIN_TEXT_OFFSET)
end

local function RequestUnlockSailorSlot(nSailorCategory, nIndex, bAutoExchange)
    GamePlayerSelfHelper:Get().SailorComponent:RequestUnlockSailorSlot(nSailorCategory, nIndex, bAutoExchange)
end

local function TryRequestUnlockSailorSlot(nSailorCategory, nIndex, tbPrice)

    local nCurrencyId = tbPrice.nCurrencyId

    local firstRequest = function ()
        RequestUnlockSailorSlot(nSailorCategory, nIndex, false)
    end

    local secondRequest = nil
    if nCurrencyId == UNEXCHANGED_ID then
        secondRequest = function ()
            RequestUnlockSailorSlot(nSailorCategory, nIndex, true)
        end
    end
    CostCurrencyHelper:SetData(nCurrencyId, tbPrice.nPrice, firstRequest, secondRequest, UISetUtils.GetL10NTextByKey("MONEY_IS_NOT_ENOUGH_UNLOCK_SAILOR_SLOT"))
    CostCurrencyHelper:FirstRequest()
end

local function OnSelectSailorBorder(self, index)
    if self.tbSailorItems[index] ~= nil then
        local nState = self.tbSailorItems[index].nState
        if nState == UILobbySailorDef.EquippingItemState.LOCK_WITH_COIN or
            nState == UILobbySailorDef.EquippingItemState.LOCK_WITH_GRADE then
            local tbPrice = SailorSlotDataTable:GetSlotPrice(self.nSailorCategory, index)
            local l10nTitle = UISetUtils.GetL10NTextByKey("SAILOR_SLOT_PURCHASE_TITLE")
            local l10nMessage = L10N:Format(UISetUtils.GetL10NTextByKey("SAILOR_SLOT_PURCHASE_MESSAGE"), tbPrice.nPrice)
            UIUtils.ShowChoiceDialog(l10nTitle, l10nMessage, function()
                TryRequestUnlockSailorSlot(self.nSailorCategory, index, tbPrice)
            end)
        elseif nState == UILobbySailorDef.EquippingItemState.LOCK then
            local nGrade = SailorSlotDataTable:GetSlotUnlockGrade(self.nSailorCategory, index)
            local l10nMessage = L10N:Format(UISetUtils.GetL10NTextByKey("SAILOR_SLOT_AUTO_UNLOCK_TIPS"), nGrade)
            UIUtils.ShowToast(l10nMessage)
        end
    end
end

function ULSailorEquippingBase:GetEmptyUnlockSlot()
    for i = 1, #self.tbSailorItems do
        if self.tbSailorItems[i].pSailorItemScript ~= nil then
            if self.tbSailorItems[i].pSailorItemScript:IsEmptyUnlockedSlot() then
                return self.tbSailorItems[i].pSailorItemScript
            end
        end
    end
    return nil
end

function ULSailorEquippingBase:EmptySailorItem()
    for i = 1, #self.tbSailorItems do
        if self.tbSailorItems[i].pSailorItemScript ~= nil then
            self.tbSailorItems[i].pSailorItemScript:SetSailorId(nil)
        end
    end
end

function ULSailorEquippingBase:Unlock(nIndex)
    local tbSailorItem = self.tbSailorItems[nIndex]
    local pBdrParent = tbSailorItem.pParent
    pBdrParent:ClearChildren()
    pBdrParent.Background.DrawAs = DRAW_TYPE_NONE
    if tbSailorItem.pSailorItemScript == nil then
        tbSailorItem.pSailorItemScript = self.PrefabHelper:CreatePrefab(UIDef.UP_LOBBY_SAILOR_SLOT_ITEM)
        tbSailorItem.pSailorItemScript.OnItemSelected:Bind(OnSailorItemSelected, self)
    end
    tbSailorItem.pSailorItemScript:SetSlotInfo(self.nSailorCategory, nIndex)
    tbSailorItem.pSailorItemScript:Unlock()
    tbSailorItem.pSailorItemScript:PlayUnlockAnim()
    tbSailorItem.pSailorItemScript:SetSailorId(nil)
    tbSailorItem.nState = UILobbySailorDef.EquippingItemState.UNLOCK
    local pWidgetRef = tbSailorItem.pSailorItemScript.pWidgetRef
    if pWidgetRef then
        local pSlot = pBdrParent:AddChild(pWidgetRef)
        pSlot:SetPadding(MARGIN_ORIGIN)
        pSlot:SetHorizontalAlignment(EHorizontalAlignment.HAlign_Center)
        pSlot:SetVerticalAlignment(EVerticalAlignment.VAlign_Center)
    end
end

function ULSailorEquippingBase:SetSailorId(nSailorType, nIndex, nSailorId, bWithAnim)
    if self.nSailorCategory == nSailorType then
        local tbSailorItem = self.tbSailorItems[nIndex]
        if tbSailorItem.pSailorItemScript ~= nil then
            tbSailorItem.pSailorItemScript:SetSailorId(nSailorId)
        end
    end
end

function ULSailorEquippingBase:PlayAddItemAnim(nSailorType, nIndex)
    if self.nSailorCategory == nSailorType then
        local tbSailorItem = self.tbSailorItems[nIndex]
        if tbSailorItem.pSailorItemScript ~= nil then
            tbSailorItem.pSailorItemScript:PlaySlotAddItem()
        end
    end
end

function ULSailorEquippingBase:InitSlots()
    local pWidgetRef = self.pWidgetRef
    self.tbSailorItems = {}
    for i = 1, UILobbySailorDef.MAX_SLOT_COUNT_PER_TYPE do
        local tbSailorItem = {}
        tbSailorItem.nState = UILobbySailorDef.EquippingItemState.LOCK
        tbSailorItem.pSailorItemScript = nil
        tbSailorItem.pParent = pWidgetRef[string.format(self.szSailorItemBdrName, i)]
        table.insert(self.tbSailorItems, tbSailorItem)
    end
end

function ULSailorEquippingBase:InitSlotsUnlockInfo()
    local tbSlotInfos = GetSailorComponent():GetSailorSlotInfo()
    for nSailorType,v in pairs(tbSlotInfos) do
        if nSailorType == self.nSailorCategory then
            for i, tbEquippedData in ipairs(v) do
                UpdateEquippingUnlockState(self, i, tbEquippedData)
            end
            break
        end
    end
end

function ULSailorEquippingBase:InitSlotsLockInfo()
    local tbUnlockIndexList = {}
    local tbUnlockGradeList = {}
    local nMinUnlcokGrade = 999
    -- 首先需要获取到每个类型槽位下一个可解锁位置
    local tbSlotInfos = GetSailorComponent():GetSailorSlotInfo()
    for nSailorType, v in ipairs(tbSlotInfos) do
        for i, tbSlotInfo in pairs(v) do
            if tbSlotInfo.bUnlocked ~= true then
                local nUnlockGrade = SailorSlotDataTable:GetSlotUnlockGrade(nSailorType, i)
                nMinUnlcokGrade = math.min(nMinUnlcokGrade, nUnlockGrade)
                tbUnlockIndexList[nSailorType] = i
                tbUnlockGradeList[nSailorType] = nUnlockGrade
                break
            end
        end
    end

    for nSailorType, nNextUnlockIndex in pairs(tbUnlockIndexList) do
        if nSailorType == self.nSailorCategory then
            local nUnlockGrade = tbUnlockGradeList[nSailorType]
            if nUnlockGrade == nMinUnlcokGrade then
                UpdateEquippingLockStateByGrade(self, nNextUnlockIndex, nUnlockGrade )
            else
                UpdateEquippingLockStateByCoin(self, nNextUnlockIndex, nUnlockGrade )
            end
        end
    end
end

function ULSailorEquippingBase:Activate()
    local szBg = UILobbySailorDef.Bg[self.nSailorCategory]
    local pWidgetRef = self.pWidgetRef 
    UISetUtils.SetImageBrushRes(pWidgetRef.ImgEqupBg, szBg:load())
end

function ULSailorEquippingBase:Deactivate()
end

function ULSailorEquippingBase:OnCreate()
end

function ULSailorEquippingBase:OnLoad()
end

function ULSailorEquippingBase:OnEnter()
end

function ULSailorEquippingBase:OnBindEvent( EventHelper )
    local pWidgetRef = self.pWidgetRef
    for i = 1, UILobbySailorDef.MAX_SLOT_COUNT_PER_TYPE do
        EventHelper:RegisterCppDelegate(pWidgetRef[string.format(self.szSailorItemBdrName, i)].OnMouseButtonDownEvent, self, function(pGeometry, pMouseEvent)
            OnSelectSailorBorder(self, i)
            return WidgetBlueprintLibrary.Handled()
        end)
    end
end


return ULSailorEquippingBase