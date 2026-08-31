-----------------------------------------------------
--File Name    : UPSevenDaySub2.lua
--Author       : lu zheng
--Create Time  : 2019-5-16
--Description  : 7天登陆子项
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local CheckInTable = require("CheckInTable")
local AwardDataTable = require("AwardDataTable")
local ItemDataTable = require("ItemDataTable")
local ScheduleSystem = require("ScheduleSystem")
local UIToolTipHelper = require("UIToolTipHelper")

local UPSevenDaySub2 = luaclass("UPSevenDaySub2", PrefabBase)
local UISetUtils = require("UISetUtils")

local END_DAY = 7
local ANIMATION_NAME = "animGlow"

UPSevenDaySub2.tbData = nil

local function GetAwardItem(nCheckinNumber)
    local tbTemplate = CheckInTable:GetTemplate(nCheckinNumber)
    if tbTemplate == nil then return nil end
    return AwardDataTable:GetAwardItem(tbTemplate.nAwardId)
end

local function HasAward(bHasAward, pWidgetRef)
    if bHasAward then
        pWidgetRef.imgBlack:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        pWidgetRef.hbGeted:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    else
        pWidgetRef.imgBlack:SetVisibility(ESlateVisibility_Collapsed)
        pWidgetRef.hbGeted:SetVisibility(ESlateVisibility_Collapsed)
    end
end

local function CanAward(self, bCanAward, nIndex, pWidgetRef, pbRewardItem)
    if bCanAward then
        if nIndex ~= END_DAY then
            -- pWidgetRef.olToday:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
            pWidgetRef.imgBg:SetVisibility(ESlateVisibility_Visible)
            pWidgetRef.parStarFlash:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        end
        self:PlayAnimation(ANIMATION_NAME, 0, 1, EUMGSequencePlayMode.Reverse, 1)
        -- pWidgetRef.btnItem:SetVisibility(ESlateVisibility_HitTestInvisible)
        pWidgetRef.imgNeed:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    else
        if nIndex ~= END_DAY then
            -- pWidgetRef.olToday:SetVisibility(ESlateVisibility_Collapsed)
            pWidgetRef.imgBg:SetVisibility(ESlateVisibility_Visible)
            pWidgetRef.parStarFlash:SetVisibility(ESlateVisibility_Collapsed)
        end
        -- pWidgetRef.btnItem:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        pWidgetRef.imgNeed:SetVisibility(ESlateVisibility_Collapsed)
    end
end

local function OnClickedItem(self)
    if not self.tbData.bCanAward then
        return
    end
    ScheduleSystem:RequestSevenDayGetReward()  
end


local function OnPressed(self)
    local tbTipData = {}
    local nItemTemplateId = self.nItemId
    local pWidgetRef = self.pWidgetRef.btnItem
    local nCount = self.nCount
    tbTipData.tbResTemplate = ItemDataTable:GetResTemplate(nItemTemplateId)
    tbTipData.tbTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    tbTipData.nCount = nCount
    UIToolTipHelper:ShowTipInAutoLayout(UIToolTipHelper.TipType.ITEM_TIP,tbTipData,pWidgetRef)
end

local function OnReleased(self)
    UIToolTipHelper:HideTip()
end

function UPSevenDaySub2:SetData(tbData)
    self.tbData = tbData

    local nIndex = tbData.nIndex
    local bHasAward = tbData.bHasAward
    local bCanAward = tbData.bCanAward

    local pWidgetRef = self.pWidgetRef

    -- local szSingleNumber = L10N:ToString(UITextDef.COMMON_SINGLE_NUMBER[nIndex])
    -- local szDayNum = L10N:Format(UITextDef.DAY_NUM, szSingleNumber)
    pWidgetRef.txtDay:SetText(nIndex)

    local tbItems = GetAwardItem(nIndex)
    if tbItems == nil or #tbItems ~= 1 then return end
    local nItemId = tbItems[1].nItemId
    self.nItemId = nItemId
    local nCount = tbItems[1].nCount
    self.nCount = nCount
    pWidgetRef.txtCount:SetText(self.nCount)
    local tbItemResTemplate = ItemDataTable:GetResTemplate(nItemId)
    UISetUtils.SetButtonBrushRes(pWidgetRef.btnItem, tbItemResTemplate.szIconPath:load())
    -- pWidgetRef.btnItem:SetDisplayItemData(nItemId, nCount, true)

    if nIndex ~= END_DAY then
        pWidgetRef.olToday:SetVisibility((tbData.nCheckInCount == tbData.nIndex) and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Collapsed)
    end
    HasAward(bHasAward, pWidgetRef)
    CanAward(self, bCanAward, nIndex, pWidgetRef, self.pbRewardItem)
end

function UPSevenDaySub2:OnBindEvent(EventHelper)
    local btnItem = self.pWidgetRef.btnItem
    EventHelper:RegisterCppDelegate(btnItem.OnClicked, self, OnClickedItem)
    EventHelper:RegisterCppDelegate(btnItem.OnPressed, self, OnPressed)
    EventHelper:RegisterCppDelegate(btnItem.OnReleased, self, OnReleased)
end

function UPSevenDaySub2:OnLoad()
end

function UPSevenDaySub2:OnDestroy()
    self.tbData = nil
end

return UPSevenDaySub2