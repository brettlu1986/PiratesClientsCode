-----------------------------------------------------
--File Name    : UPSeaAdventureReward.lua
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSeaAdventureReward = luaclass("UPSeaAdventureReward", PrefabBase)

local SeaAdventureHelper = require("SeaAdventureHelper")
local UIToolTipHelper = require("UIToolTipHelper")
local ItemDataTable = require("ItemDataTable")
local UISetUtils = require("UISetUtils")

UPSeaAdventureReward.nTemplateId = nil
UPSeaAdventureReward.nIndex = nil
UPSeaAdventureReward.nState = nil

local nStateDef = SeaAdventureHelper.CIRCLE_REWARD_STATE

local function OnItemButtonPressed(self)
    if self.nTemplateId ~= nil then 
        local tbTipData = {}
        local pWidgetRef = self.pWidgetRef.btnItem
        tbTipData.tbResTemplate = ItemDataTable:GetResTemplate(self.nTemplateId)
        tbTipData.tbTemplate =  ItemDataTable:GetTemplate(self.nTemplateId)
        UIToolTipHelper:ShowTipInAutoLayout(UIToolTipHelper.TipType.ITEM_TIP,tbTipData,pWidgetRef)
    end
end

local function OnItemButtonReleased(self)
    UIToolTipHelper:HideTip()
end

local function OnItemButtonClicked(self)
    if self.nState == nStateDef.CANGET then 
        local tbInstance = self.Owner.tbInstance
        tbInstance:RequestGetDiceReward(self.nIndex)
    end
end

function UPSeaAdventureReward:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnPressed, self, OnItemButtonPressed)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnReleased, self, OnItemButtonReleased)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnClicked, self, OnItemButtonClicked)
end

function UPSeaAdventureReward:OnLoad()
end

function UPSeaAdventureReward:OnDestroy()
end

function UPSeaAdventureReward:SetRewardData(nTemplateId, nIndex)
    self.nTemplateId = nTemplateId
    self.nIndex = nIndex
    local tbItemRes = ItemDataTable:GetResTemplate(nTemplateId)
    local szImgRes = tbItemRes.szIconPath
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgItem, szImgRes:load())
end

local function ShowEff(self, bShow)
    local pWidgetRef = self.pWidgetRef
    local VISIBLE, COLLAPSED = ESlateVisibility.SelfHitTestInvisible, ESlateVisibility.Collapsed
    pWidgetRef.imgFxTrail01:SetVisibility(bShow and VISIBLE or COLLAPSED)
    pWidgetRef.imgFxTrail02:SetVisibility(bShow and VISIBLE or COLLAPSED)
    pWidgetRef.parItemStars:SetVisibility(bShow and VISIBLE or COLLAPSED)
end

function UPSeaAdventureReward:SetRewardState(nState)
    
    self.nState = nState == nil and nStateDef.UNGET or nState
    local pWidgetRef = self.pWidgetRef
    local VISIBLE, COLLAPSED = ESlateVisibility.SelfHitTestInvisible, ESlateVisibility.Collapsed
    pWidgetRef.imgSelect:SetVisibility(self.nState == nStateDef.GET and VISIBLE or COLLAPSED)
    pWidgetRef.imgBlack:SetVisibility(self.nState == nStateDef.UNGET and VISIBLE or COLLAPSED)
    pWidgetRef.imgBingo:SetVisibility(self.nState == nStateDef.GET and VISIBLE or COLLAPSED)

    if self.nState == nStateDef.CANGET then   
        self:PlayAnimation("animFxOn", 0, 0, EUMGSequencePlayMode.Forward, 1)
        ShowEff(self, true)
    else 
        self:StopAnimation("animFxOn")
        ShowEff(self, false)
    end
end

return UPSeaAdventureReward