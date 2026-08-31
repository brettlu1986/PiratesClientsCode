local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UISeasonBattleTierBuy = luaclass("UISeasonBattleTierBuy", WndBase)
local SeasonSystem = require("SeasonSystem")
local L10N = require("L10N")
local UISetUtils = require("UISetUtils")
local BattleTierDataTable = require("BattleTierDataTable")
local ItemSystem = require("ItemSystem")
local ItemDataTable = require("ItemDataTable")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local BattleTierRewardDataTable = require("BattleTierRewardDataTable")
local AwardDataTable = require("AwardDataTable")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local LuaDelegateClass = require("LuaDelegate")
local LobbySystem = require("LobbySystem")
local LobbySubTypeDef = require("LobbySubTypeDef")
local UIUtils = require("UIUtils")
local ClientEventDef = require("ClientEventDef")
local BattleTierRewardEffectDataTable = require("BattleTierRewardEffectDataTable")
local UIResourceDef = require("UIResourceDef")

local EFFECT_IMAGES = {
    "imgGreen",
    "imgBlue",
    "imgPurple",
    "imgOrange"
}

UISeasonBattleTierBuy.nCount = nil
UISeasonBattleTierBuy.ListHelper = nil
UISeasonBattleTierBuy.pbAwardDesc = nil
UISeasonBattleTierBuy.pbWindowFrame = nil

UISeasonBattleTierBuy.bCanDrag = nil
UISeasonBattleTierBuy.bIsDrag = nil
UISeasonBattleTierBuy.tbLastPos = nil
UISeasonBattleTierBuy.tbCurPos = nil

local function OnItemSelected(self, nItemTemplateId, tbData)
    local tbItemTemplate = ItemSystem:GetItemTemplate(nItemTemplateId or 0)
    local pWidgetRef = self.pWidgetRef
    if tbItemTemplate == nil then
        pWidgetRef.olItem:SetVisibility(ESlateVisibility_Collapsed)
        self.pbAwardDesc:OnRefresh()
        return
    end
    self.pbAwardDesc:OnRefresh(tbItemTemplate)
    if LobbySystem:GetSub(LobbySubTypeDef.SEASON):SetViewTarget(tbItemTemplate, UIDef.UI_SEASON_BATTLE_TIER_BUY) then
        local tbSelectedData = {nTemplateId = nItemTemplateId, 
        nSelectIndex = tbData.nIndex, 
        nTier = tbData.nTier, 
        nEffectId = tbData.nEffectId, 
        bAdvance = tbData.bAdvance,
        nBuyCount = self.nCount,
        tbData = tbData}
        self.pbAwardDesc:SetSelectedData(tbSelectedData)
        self.bCanDrag = true
        pWidgetRef.olItem:SetVisibility(ESlateVisibility_Collapsed)
    else
        self.bCanDrag = false
        local tbItemResTemplate = ItemDataTable:GetResTemplate(nItemTemplateId)
        local szIconPath = tbItemResTemplate.szIconPath
        UISetUtils.SetImageBrushRes(pWidgetRef.imgSelectedItem, szIconPath:load())
        pWidgetRef.olItem:SetVisibility(ESlateVisibility_Visible)

        local fnHideEffect = function()
            for i, v in ipairs(EFFECT_IMAGES) do
                pWidgetRef[v]:SetVisibility(ESlateVisibility_Collapsed)
            end
        end        
        local nEffectId = tbData and tbData.nEffectId or 0
        if nEffectId > 0 and nEffectId <= #EFFECT_IMAGES then
            local SelfHitTestInvisible = ESlateVisibility.SelfHitTestInvisible
            pWidgetRef[EFFECT_IMAGES[nEffectId]]:SetVisibility(SelfHitTestInvisible)
        else
            fnHideEffect()
        end
        local szGradeIcon = UIResourceDef.ITEM_COLOR_GRADE_BG[tbItemTemplate.nGrade]
        if szGradeIcon ~= nil then
            UISetUtils.SetImageBrushRes(pWidgetRef.imgPackItemBg, szGradeIcon:load())
        end
    end

    self.ListHelper:SetSelectedIndex(tbData.nIndex)
end


local function GetEffectId(tbItemEffects, nIndex)
    local nEffectId = 0
    if tbItemEffects == nil then
        return nEffectId
    end
    for i, v in ipairs(tbItemEffects) do
        if nIndex == i then
            nEffectId = v.nEffect
            break
        end
    end
    return nEffectId
end

local function RefreshRewardList(self, tbBattleTier)
    local nCurTier = tbBattleTier.battle_tier
    local SeasonComponent = SeasonSystem:GetComponent()
    local bActive  = SeasonComponent:IsPassActive()
    local tbAwards = {}
    local nIndex = 0
    for i = nCurTier + 1, nCurTier + self.nCount do
        local tbTierAwardData = BattleTierRewardDataTable:GetTemplate(i)
        if tbTierAwardData ~= nil then
            local tbAwards1 = AwardDataTable:GetAwardItem(tbTierAwardData.nWarriorAwardId)
            local tbNormalItemEffects = BattleTierRewardEffectDataTable:GetWarriorAwardEffectTemplate(i)
            local tbAdvanceItemEffects = BattleTierRewardEffectDataTable:GetHeroAwardEffectTemplate(i)
            if tbAwards1 ~= nil then
                for j, v in ipairs(tbAwards1) do
                    nIndex = nIndex + 1
                    local nEffectId = GetEffectId(tbNormalItemEffects, j)        
                    table.insert(tbAwards, {nItemTemplateId = v.nItemId, bAdvance = false, nIndex = nIndex, nTier = i, nEffectId = nEffectId, nCount = v.nCount, bCanClick = true, OnItemPressedDelegate = self.OnItemPressedDelegate})
                end
            end
            if bActive then
                local tbAwards2 = AwardDataTable:GetAwardItem(tbTierAwardData.nHeroAwardId)
                if tbAwards2 ~= nil then
                    for j, v in ipairs(tbAwards2) do
                        nIndex = nIndex + 1
                        local nEffectId = GetEffectId(tbAdvanceItemEffects, j)        
                        table.insert(tbAwards, {nItemTemplateId = v.nItemId, bAdvance = true, nIndex = nIndex, nTier = i, nEffectId = nEffectId, nCount = v.nCount, bCanClick = true, OnItemPressedDelegate = self.OnItemPressedDelegate})
                    end
                end
            end
        end
    end 

    local tbData = self.ListHelper:GetData()
    if tbData == nil or #tbData == 0 then 
        if #tbAwards > 0 then
            OnItemSelected(self, tbAwards[1].nItemTemplateId, tbAwards[1])
        else
            OnItemSelected(self)
        end
    end
    self.ListHelper:SetData(tbAwards)
end

local function RefreshUI(self)
    local SeasonComponent = SeasonSystem:GetComponent()
    local tbBattlePass = SeasonComponent:GetBattlePass()

    local pWidgetRef = self.pWidgetRef

    pWidgetRef.txtCurTier:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("SEASON_BATTLETIER"), tbBattlePass.battle_tier))
    pWidgetRef.txtToTier:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("SEASON_BATTLETIER"), tbBattlePass.battle_tier + self.nCount))
    pWidgetRef.txtTier:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("SEASON_BATTLETIER"), self.nCount))

    local Component = SeasonSystem:GetComponent()
    local tbBattleTier = Component:GetBattlePass()
    local nCurTier = tbBattleTier.battle_tier

    local tbBattleTierData = BattleTierDataTable:GetTemplate(nCurTier)
    local tbItemData = ItemSystem:GetItemTemplate(tbBattleTierData.nCurrencyId)
    if tbItemData ~= nil then
        local tbItemResTemplate = ItemDataTable:GetResTemplate(tbBattleTierData.nCurrencyId)
        local szIconPath = tbItemResTemplate.szIconPath
        UISetUtils.SetImageBrushRes(pWidgetRef.imgCostMoney, szIconPath:load())

        self.pbWindowFrame:ReloadCurrency({tbBattleTierData.nCurrencyId})
    end
    
    local nCost = 0
    for i = 1, self.nCount do
        local tbTemp = BattleTierDataTable:GetTemplate(nCurTier + i - 1)
        if tbTemp ~= nil then
            nCost = nCost + tbTemp.nCurrencyCost
        end    
    end
    pWidgetRef.txtMoney:SetText(nCost)

    RefreshRewardList(self, tbBattleTier)
end

local function SetBuyCount(self, nCount)
    self.nCount = nCount
    RefreshUI(self)    
end

local function OnClickAdd(self)
    local Component = SeasonSystem:GetComponent()
    local tbBattleTier = Component:GetBattlePass()
    local nCurTier = tbBattleTier.battle_tier
    local nMaxTier = tbBattleTier.battle_max_tier
    local nCount = self.nCount + 1
    if nCount > nMaxTier - nCurTier then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("SEASON_BUYTIER_ISMAXTIER"))
        return
    end  
    SetBuyCount(self, nCount)
end

local function OnClickReduce(self)
    local nCount = self.nCount - 1
    if nCount <= 0 then
        return
    end
    SetBuyCount(self, nCount) 
end

local function OnClickAdd10(self)
    local Component = SeasonSystem:GetComponent()
    local tbBattleTier = Component:GetBattlePass()
    local nCurTier = tbBattleTier.battle_tier
    local nMaxTier = tbBattleTier.battle_max_tier
    local nCount = math.min(self.nCount + 10, nMaxTier - nCurTier)
    if nCount > nMaxTier - nCurTier or nCount == self.nCount then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("SEASON_BUYTIER_ISMAXTIER"))
        return
    end  
    SetBuyCount(self, nCount)
end

local function OnClickReduce10(self)
    local nCount = math.max(self.nCount - 10, 1)
    if nCount <= 0 then
        return
    end
    SetBuyCount(self, nCount) 
end

local function OnClickPurchase(self)
    SeasonSystem:RequestBuyBattleTier(self.nCount)
end

local function OnClickClose(self)
    self:CloseSelf()
    UIManager:OpenWnd(UIDef.UI_SEASON_BATTLEPASS)
end

local function OnRefreshSeason(self)
    SetBuyCount(self, 1)
end

local function OnMouseButtonDown(self, pGeometry, pMouseEvent)
    if self.bCanDrag then
        self.bIsDrag = true
        self.tbLastPos = KismetInputLibrary.PointerEvent_GetScreenSpacePosition(pMouseEvent)
    end
    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseMove(self, pGeometry, pMouseEvent)
    if self.bIsDrag then
        self.tbCurPos = KismetInputLibrary.PointerEvent_GetScreenSpacePosition(pMouseEvent)
        LobbySystem:GetSub(LobbySubTypeDef.SEASON):RotateActor((self.tbCurPos.X - self.tbLastPos.X) * 0.5)
        self.tbLastPos = self.tbCurPos
    end

    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseButtonUp(self, pGeometry, pMouseEvent)
    self.bIsDrag = nil
    self.tbLastPos = nil
    self.tbCurPos = nil

    return WidgetBlueprintLibrary.Handled()
end

function UISeasonBattleTierBuy:OnLoad()
    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, self.pWidgetRef.kmlistItems, {}, UIDef.UP_LOBBY_ITEM_SUB)

    self.pbAwardDesc = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbAwardDesc, UIDef.UP_SEASON_AWARD_DESC)
    self.pbAwardDesc.Owner = UIDef.UI_SEASON_BATTLE_TIER_BUY
    self.OnItemPressedDelegate = LuaDelegateClass()
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetBackDelegate(OnClickClose, self)
    --self.pbCurrencyBar = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbCurrencyBar)
end

function UISeasonBattleTierBuy:OnBindEvent(EventHelper)
    EventHelper:RegisterLuaDelegate(self.OnItemPressedDelegate, OnItemSelected, self)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAdd.OnClicked,  self, OnClickAdd)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnReduce.OnClicked,  self, OnClickReduce)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAdd10.OnClicked,  self, OnClickAdd10)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnReduce10.OnClicked,  self, OnClickReduce10)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnPurchase.OnClicked,  self, OnClickPurchase)
    --EventHelper:RegisterCppDelegate(pWidgetRef.btnClose.OnClicked,  self, OnClickClose)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_SEASON_PASS, self, OnRefreshSeason)

    EventHelper:RegisterCppDelegate(pWidgetRef.bdrActorListener.OnMouseButtonDownEvent, self, OnMouseButtonDown)
    EventHelper:RegisterCppDelegate(pWidgetRef.bdrActorListener.OnMouseMoveEvent, self, OnMouseMove)
    EventHelper:RegisterCppDelegate(pWidgetRef.bdrActorListener.OnMouseButtonUpEvent, self, OnMouseButtonUp)
end

function UISeasonBattleTierBuy:OnUnload()
    self.ListHelper:Uninit()
    self.ListHelper = nil
end

function UISeasonBattleTierBuy:OnShow()
    UIUtils.BottomMenuHide(true)
    self:PlayAnimation("anim_SeasonBattleTierBuyIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
    UIManager:CloseWnd(UIDef.UI_SEASON_BATTLEPASS)
    if self.tbOpenArgs.tbExtendData ~= nil then
        SetBuyCount(self, self.tbOpenArgs.tbExtendData.nBuyCount)
        OnItemSelected(self, self.tbOpenArgs.tbExtendData.nTemplateId, self.tbOpenArgs.tbExtendData.tbData)
    else
        SetBuyCount(self, 1)
    end
end

function UISeasonBattleTierBuy:OnHide()
    UIUtils.BottomMenuHide(false)
end

function UISeasonBattleTierBuy:OnDestroy()
end

return UISeasonBattleTierBuy