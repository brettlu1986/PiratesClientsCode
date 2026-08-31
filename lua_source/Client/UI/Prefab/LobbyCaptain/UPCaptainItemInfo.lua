-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPCaptainItemInfo = luaclass("UPCaptainItemInfo", PrefabBase)
local SelfTimeCountDownHelper = require("SelfTimeCountDownHelper")
local UILobbyCaptainHelper = require("UILobbyCaptainHelper")
local UITextDef = require("UITextDef")
local UIResourceDef = require("UIResourceDef")
local UISetUtils = require("UISetUtils")
-- local ItemSourceDataTable = require("ItemSourceDataTable")
-- local UIUtils = require("UIUtils")
-- local ShopDataTable = require("ShopDataTable")
-- local ShopSystem = require("ShopSystem")

local COUNT_DOWN_PRECISION = 2

UPCaptainItemInfo.tbInfo = nil
UPCaptainItemInfo.bShowOnly = false

local function StopTimeCountDown(self)
    self.tbTimeCountDownHelper:StopCountDown()
end

local function SetExpirationTime(self, nRemainUseSeconds)
    StopTimeCountDown(self)
    self.tbTimeCountDownHelper:StartCountDown(
        nRemainUseSeconds, SelfTimeCountDownHelper.CountDownType.FRONT_FULL_PRECISION, COUNT_DOWN_PRECISION,
        self.pWidgetRef.kmtxtTime, function ()
            self.pWidgetRef.kmtxtTime:SetText(UITextDef.UIEQUIPMENTTIPS_ITEM_REMOVED)
            self.pWidgetRef.txtTimeAll:SetVisibility(ESlateVisibility.Collapsed)
        end)
end

function UPCaptainItemInfo:OnLoad()
    self.super.OnLoad(self)
    self.tbTimeCountDownHelper = SelfTimeCountDownHelper()
end

function UPCaptainItemInfo:OnUnload()
    self.super.OnUnload()
    StopTimeCountDown(self)
end

-- local function UnlockCurrentDecoration(self)
--     if self.bShowOnly == true then  return end
--     if self.tbInfo ~= nil then
--         local tbEquipState = UILobbyCaptainHelper.tbCaptainItemState
--         if self.tbInfo.nEquipState == tbEquipState.UNGET then
--             local nSourceType = self.tbInfo.tbTemplate.nSourceType
--             if ItemSourceDataTable:IfShowBuyButton(nSourceType) then
--                 local tbGoodsTemplate = ShopDataTable:GetItemGoodsTemplate(self.tbInfo.nTemplateId)
--                 ShopSystem:OnBuyButtonClick(tbGoodsTemplate)
--             else
--                 local l10nToastDesc = ItemSourceDataTable:GetSourceToastDesc(nSourceType)
--                 if l10nToastDesc then
--                     UIUtils.ShowToast(l10nToastDesc)
--                 end
--             end
--         end
--     end
-- end

function UPCaptainItemInfo:OnBindEvent(EventHelper)
   -- EventHelper:RegisterCppDelegate(self.pWidgetRef.btnUnlock.OnClicked, self, UnlockCurrentDecoration)
end

--tbInfo 结构
-- {
--     nTemplateId = nTemplateId, tbTemplate = tbTemplate ,
--     tbResTemplate = ItemDataTable:GetResTemplate(nTemplateId), nEquipState = UILobbyCaptainHelper.tbCaptainItemState.UNGET,
--     nInstanceId = NOT_IN_BAG_ID
-- }
function UPCaptainItemInfo:SetData(tbInfo)
    local pWidgetRef = self.pWidgetRef
    if not tbInfo then return end
    self.tbInfo = tbInfo

    pWidgetRef.txtFirstName:SetText(tbInfo.tbTemplate.l10nName)
    -- pWidgetRef.txtFirstName:SetColorAndOpacity(UIResourceDef.FONT_GRADE_COLOR[tbInfo.tbTemplate.nGrade])
    pWidgetRef.txtSecondName:SetText(nil)
    pWidgetRef.txtLastName:SetText(nil)

    local tbEquipState = UILobbyCaptainHelper.tbCaptainItemState
    pWidgetRef.txtLevel:SetText(string.format("+%d",tbInfo.tbTemplate.nLevel))

    local szGradeIcon = UIResourceDef.ITEM_INFO_GRADE_BG_H[tbInfo.tbTemplate.nGrade]
    UISetUtils.SetBorderBrushRes(pWidgetRef.bdrInfoBg, szGradeIcon:load(), true)

    if tbInfo.nEquipState == tbEquipState.UNGET then
        pWidgetRef.txtUnEquip:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.ImgLock:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.ExpiredTimeBox:SetVisibility(ESlateVisibility.Hidden)
        pWidgetRef.txtEguip:SetVisibility( ESlateVisibility.Collapsed)
    else
        pWidgetRef.txtUnEquip:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.ImgLock:SetVisibility(ESlateVisibility.Collapsed)
        local RemainTime = UILobbyCaptainHelper.GetRemainingTime(tbInfo.nInstanceId)
        if RemainTime then
            pWidgetRef.ExpiredTimeBox:SetVisibility(ESlateVisibility.HitTestInvisible)
            if RemainTime > 0 then
                pWidgetRef.txtTimeAll:SetVisibility(ESlateVisibility.HitTestInvisible)
                SetExpirationTime(self, RemainTime)
            else
                pWidgetRef.kmtxtTime:SetText(UITextDef.UIEQUIPMENTTIPS_ITEM_REMOVED)
                pWidgetRef.txtTimeAll:SetVisibility(ESlateVisibility.Collapsed)
            end
        else
            pWidgetRef.ExpiredTimeBox:SetVisibility(ESlateVisibility.Hidden)
        end
        pWidgetRef.txtEguip:SetVisibility(tbInfo.nEquipState == tbEquipState.EQUIP and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
    end
end

local function ParseFromAvatarData(tbData)
    local tbInfo = {}
    if not tbData.bOwned then
        local tbEquipState = UILobbyCaptainHelper.tbCaptainItemState
        tbInfo.nEquipState = tbEquipState.UNGET
    end
    tbInfo.nTemplateId = tbData.nTemplateId
    tbInfo.tbTemplate = tbData.tbTemplate
    return tbInfo
end

function UPCaptainItemInfo:SetAvatarData(tbData, bShowOnly)

    local pWidgetRef = self.pWidgetRef
    if not tbData then
        return
    end
    self.bShowOnly = bShowOnly
    self.tbInfo = ParseFromAvatarData(tbData)

    pWidgetRef.txtEguip:SetVisibility(tbData.bEquiped and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
    pWidgetRef.txtFirstName:SetText(tbData.l10nFirstName)
    -- pWidgetRef.txtFirstName:SetColorAndOpacity(UIResourceDef.FONT_GRADE_COLOR[tbData.nGrade])
    pWidgetRef.txtSecondName:SetText(tbData.l10nSecondName)
    pWidgetRef.txtLastName:SetText(tbData.l10nLastName)

    pWidgetRef.txtLevel:SetText(nil)

    local szGradeIcon = UIResourceDef.ITEM_INFO_GRADE_BG_H[tbData.nGrade]
    UISetUtils.SetBorderBrushRes(pWidgetRef.bdrInfoBg, szGradeIcon:load(), true)
    if tbData.bOwned then
        pWidgetRef.ImgLock:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.txtUnEquip:SetVisibility(ESlateVisibility.Collapsed)
        -- pWidgetRef.txtEguip:SetVisibility(ESlateVisibility.Collapsed)
        if tbData.nRemainTime and tbData.nRemainTime > 0 then
            pWidgetRef.ExpiredTimeBox:SetVisibility(ESlateVisibility.HitTestInvisible)
            SetExpirationTime(self, tbData.nRemainTime)
        else
            pWidgetRef.ExpiredTimeBox:SetVisibility(ESlateVisibility.Hidden)
        end
    else
        pWidgetRef.ImgLock:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.txtUnEquip:SetText(UITextDef.UI_CAPTAIN_PREVIEW)
        pWidgetRef.txtUnEquip:SetVisibility(ESlateVisibility.HitTestInvisible)
        -- pWidgetRef.txtEguip:SetVisibility(ESlateVisibility.Collapsed)
    end
end

return UPCaptainItemInfo