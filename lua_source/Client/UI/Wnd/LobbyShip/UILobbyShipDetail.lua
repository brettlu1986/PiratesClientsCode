-----------------------------------------------------
--File Name    : UILobbyShipDetail.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-20
--Description  : 船详情界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbyShipDetail = luaclass("UILobbyShipDetail", WndBase)

local L10N = require("L10N")
local UITextDef = require("UITextDef")
local UISetUtils = require("UISetUtils")
local ItemSystem = require("ItemSystem")
local ShopSystem = require("ShopSystem")
local LuaDelegate = require("LuaDelegate")
local ItemDataTable = require("ItemDataTable")
local ShopDataTable = require("ShopDataTable")
local UIResourceDef = require("UIResourceDef")
local ClientEventDef = require("ClientEventDef")
local CurrencySystem = require("CurrencySystem")
local SkillDataTable = require("SkillDataTable")
local ItemCategoryDef = require("ItemCategoryDef")
local UIToolTipHelper = require("UIToolTipHelper")
local SelfTabBarHelper = require("SelfTabBarHelper")
local ShipResDataTable = require("ShipResDataTable")
local SelfGalleryHelper = require("SelfGalleryHelper")
local ItemSourceDataTable = require("ItemSourceDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BuildShipTipsContentHelper = require("BuildShipTipsContentHelper")

local SKILL_COUNT_MAX = 4
local EXPIRATION_TIME_REFRESH_INTERVAL = 1

UILobbyShipDetail.ulLobbyShipDisplay = nil
UILobbyShipDetail.uLShipDetailContent = nil
UILobbyShipDetail.pbWindowFrame = nil
UILobbyShipDetail.pbShipMaterials = nil
UILobbyShipDetail.TabBarHelper = nil
UILobbyShipDetail.GalleryHelper = nil
UILobbyShipDetail.tbPbBuildShipSkills = nil
UILobbyShipDetail.tbShipResTemplate = nil
UILobbyShipDetail.nShipIndex = -1
UILobbyShipDetail.tbGoodsTemplate = nil
UILobbyShipDetail.bPosterMode = false

local function GetShipPreparationComponent()
    return GamePlayerSelfHelper:Get().ShipPreparationComponent
end

local function InitSortedShipTemplates(self)
    self.tbSortedShipTemplates = GetShipPreparationComponent():GetSortedShipTemplates()
end

local function BindShipSkillPrefabs(self)
    self.OnSkillButtonPressedDelegate = LuaDelegate()
    self.OnSkillButtonReleasedDelegate = LuaDelegate()

    local pWidgetRef = self.pWidgetRef
    self.tbPbBuildShipSkills = {}
    local tbPbBuildShipSkills = self.tbPbBuildShipSkills
    for i = 1, SKILL_COUNT_MAX  do
        local pbShipSkill = self.PrefabHelper:BindPrefab(pWidgetRef["pbBuildShipSkill0"..i])
        pbShipSkill:SetOnSkillButtonPressedDelegate(self.OnSkillButtonPressedDelegate)
        pbShipSkill:SetOnSkillButtonReleasedDelegate(self.OnSkillButtonReleasedDelegate)
        tbPbBuildShipSkills[i] = pbShipSkill
    end
end

-- 刷新购买价格数据
local function UpdatePurchasePrice(self, tbTemplate)
    local nItemTemplateId = tbTemplate.nId
    local tbGoodsTemplate = ShopDataTable:GetItemGoodsTemplate(nItemTemplateId)
    if not tbGoodsTemplate then
        self.pWidgetRef.hboxPurchase:SetVisibility(ESlateVisibility.Collapsed)
        logerror("Cannot find item price!", nItemTemplateId)
        return
    end

    self.tbGoodsTemplate = tbGoodsTemplate
    local nCurrencyId1 = tbGoodsTemplate.nCurrencyId1
    local nCurrencyPrice1 = tbGoodsTemplate.nCurrencyCount1
    local nCurrencyCount1 = CurrencySystem:GetCurrencyCount(nCurrencyId1)
    local bEnough1 = nCurrencyCount1 >= nCurrencyPrice1
    local szCurrencySmallIcon1 = CurrencySystem:GetCurrencySmallIcon(nCurrencyId1)
    self.pWidgetRef.txtPrice1:SetText(nCurrencyPrice1)
    self.pWidgetRef.txtPrice1:SetColorAndOpacity(bEnough1 and UIResourceDef.COLOR.WHITE.SLATE_COLOR or UIResourceDef.COLOR.RED.SLATE_COLOR)
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgCurrency1, szCurrencySmallIcon1:load())
    self.nCurrencyId1 = nCurrencyId1
    self.l10nCurrencyName1 = ItemSystem:GetItemTemplate(nCurrencyId1).l10nName

    if tbGoodsTemplate.bHasSecondCurrencyPrice then
        local nCurrencyId2 = tbGoodsTemplate.nCurrencyId2
        local nCurrencyPrice2 = tbGoodsTemplate.nCurrencyCount2
        local nCurrencyCount2 = CurrencySystem:GetCurrencyCount(nCurrencyId2)
        local bEnough2 = nCurrencyCount2 >= nCurrencyPrice2
        local szCurrencySmallIcon2 = CurrencySystem:GetCurrencySmallIcon(nCurrencyId2)
        self.pWidgetRef.txtPrice2:SetText(nCurrencyPrice2)
        self.pWidgetRef.txtPrice2:SetColorAndOpacity(bEnough2 and UIResourceDef.COLOR.WHITE.SLATE_COLOR or UIResourceDef.COLOR.RED.SLATE_COLOR)
        UISetUtils.SetImageBrushRes(self.pWidgetRef.imgCurrency2, szCurrencySmallIcon2:load())
        self.nCurrencyId2 = nCurrencyId2
        self.l10nCurrencyName2 = ItemSystem:GetItemTemplate(nCurrencyId2).l10nName
    end
end

-- 刷新皮肤数据
local function UpdateShipSkinGallery(self, nNewShipSkinTemplateId)
    local nShipItemId = self.nTemplateId
    local tbDatas = {}
    local nSelectedIndex = 1
    local tbTemplates = ItemSystem:GetItemTemplatesByCategory(ItemCategoryDef.SHIP_SKIN)
    for _, tbTemplate in pairs(tbTemplates) do
        if tbTemplate.nShipItemId == nShipItemId then
            table.insert(tbDatas, tbTemplate)
            if self.tbOpenArgs.nShipSkinTemplateId == tbTemplate.nId then
                nSelectedIndex = #tbDatas
                self.tbOpenArgs.nShipSkinTemplateId = nil
            elseif nNewShipSkinTemplateId == tbTemplate.nId then
                nSelectedIndex = #tbDatas
            elseif GetShipPreparationComponent():IsEquippedShipSkin(nShipItemId, tbTemplate.nId) then
                nSelectedIndex = #tbDatas
            end
        end
    end
    self.GalleryHelper:SetData(tbDatas)
    self.GalleryHelper:SelectItemByIndex(nSelectedIndex, false)
end

-- 刷新皮肤显示
local function UpdateShipSkin(self)
    local tbShipSkinTemplate = self.GalleryHelper:GetSelectedData()
    if not tbShipSkinTemplate then
        return
    end
    self.tbShipResTemplate = ShipResDataTable:GetTemplate(tbShipSkinTemplate.nShipResId)

    -- 设置皮肤名称，默认时不显示
    if tbShipSkinTemplate.bDefaultSkin then
        self.pWidgetRef.txtSkinName:SetVisibility(ESlateVisibility.Collapsed)
    else
        self.pWidgetRef.txtSkinName:SetText(tbShipSkinTemplate.l10nPrefixName)
        self.pWidgetRef.txtSkinName:SetColorAndOpacity(KMUMGLibrary.GetSlateColorFromHex(L10N:ToString(UITextDef.ITEM_GRADE_COLOR_TEXT[tbShipSkinTemplate.nGrade])))
        self.pWidgetRef.txtSkinName:SetVisibility(ESlateVisibility.HitTestInvisible)
    end

    if self.bPosterMode then
        UISetUtils.SetImageBrushRes(self.pbWindowFrame.pWidgetRef.imgBg, self.tbShipResTemplate.szBigPicPath:load())
    else
        self.ulLobbyShipDisplay:SetShipResTemplate(self.tbShipResTemplate)
    end
end

-- 刷新技能图标数据
local function UpdateSkillInfo(self, tbSkillIds)
    for i = 1, SKILL_COUNT_MAX do
        local pbBuildShipSkill = self.tbPbBuildShipSkills[i]
        if #tbSkillIds >= i then
            pbBuildShipSkill:Refresh(tbSkillIds[i])
            pbBuildShipSkill:ShowSkillName()
        else
            pbBuildShipSkill:Collapsed()
        end
    end
end

-- 刷新获得途径
local function RefreshItemSource(self, tbTemplate)
    local nSourceType = tbTemplate.nSourceType
    if ItemSourceDataTable:IfShowBuyButton(nSourceType) then
        UpdatePurchasePrice(self, tbTemplate)
        self.pWidgetRef.hboxPurchase:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.pWidgetRef.txtSourceDesc:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.ovlPurchaseInfo:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.pWidgetRef.hboxPurchase:SetVisibility(ESlateVisibility.Collapsed)
        local l10nSourceDesc = ItemSourceDataTable:GetSourceDesc(nSourceType)
        if l10nSourceDesc ~= nil then
            self.pWidgetRef.txtSourceDesc:SetVisibility(ESlateVisibility.HitTestInvisible)
            self.pWidgetRef.txtSourceDesc:SetText(l10nSourceDesc)
            self.pWidgetRef.ovlPurchaseInfo:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        else
            self.pWidgetRef.txtSourceDesc:SetVisibility(ESlateVisibility.Collapsed)
            self.pWidgetRef.ovlPurchaseInfo:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
end

-- 在体验卡期间
local function TemporaryUnlockShip(self, nExpirationTime, tbTemplate)
    self.pWidgetRef.txtExpirationTime:StartTimer(nExpirationTime, EXPIRATION_TIME_REFRESH_INTERVAL, UITextDef.TIMER_TEXT_BLOCK_FORMAT_FULL, EMinTimeUnit.Second)
    self.pWidgetRef.hboxExpirationTime:SetVisibility(ESlateVisibility.HitTestInvisible)

    RefreshItemSource(self, tbTemplate)
end

-- 解锁舰船
local function UnlockShip(self)
    self.pWidgetRef.hboxPurchase:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.txtSourceDesc:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.ovlPurchaseInfo:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.hboxExpirationTime:SetVisibility(ESlateVisibility.Collapsed)
end

-- 锁定舰船
local function LockShip(self, tbTemplate)
    RefreshItemSource(self, tbTemplate)

    self.pWidgetRef.hboxExpirationTime:SetVisibility(ESlateVisibility.Collapsed)
end

local function SetShipIndex(self, nIndex)
    local nTemplatesLength = #self.tbSortedShipTemplates
    if nIndex <= 0 then
        nIndex = nTemplatesLength
    elseif nIndex > nTemplatesLength then
        nIndex = 1
    end
    self.nShipIndex = nIndex

    local tbTemplate = self.tbSortedShipTemplates[nIndex]
    local nTemplateId = tbTemplate.nId
    local nBattleItemId = tbTemplate.nBattleItemId
    self.nTemplateId = nTemplateId

    -- 设置舰船名称
    self.pWidgetRef.txtShipName:SetText(tbTemplate.l10nName)

    -- 设置舰船描述
    local nShipDescFormat = UISetUtils.GetL10NTextByKey("SHIP_DESC_FORMAT")
    local nShipDesc = L10N:Format(nShipDescFormat, UITextDef.SHIP_GRADE_TEXT[tbTemplate.nGrade])
    self.pWidgetRef.txtShipType:SetText(nShipDesc)

    -- 刷新战斗内建造材料
    self.pbShipMaterials:SetBuildId(nBattleItemId)

    -- 刷新战斗数值
    self.uLShipDetailContent:SetShipTemplateId(nBattleItemId)
    self.uLShipDetailContent:UpdateShipProperties()

    -- 刷新皮肤
    self.GalleryHelper:Reset()
    UpdateShipSkinGallery(self)
    UpdateShipSkin(self)

    -- 刷新技能数据
    local tbShipTipsDatas = BuildShipTipsContentHelper.GetShipTipsDatas(nBattleItemId)
    UpdateSkillInfo(self, tbShipTipsDatas.tbSkillIds)

    -- 解锁舰船
    local ShipPreparationComponent = GetShipPreparationComponent()
    if ShipPreparationComponent:IsItemUnlocked(nTemplateId) then
        local nExpirationTime = ShipPreparationComponent:GetItemExpirationTime(nTemplateId)
        if nExpirationTime > 0 then
            TemporaryUnlockShip(self, nExpirationTime, tbTemplate)
        else
            self.pWidgetRef.txtExpirationTime:StopTimer()
            UnlockShip(self)
        end
    else
        LockShip(self, tbTemplate)
    end
end

local function OnClickedBtnLastShip(self)
    SetShipIndex(self, self.nShipIndex - 1)
end

local function OnClickedBtnNextShip(self)
    SetShipIndex(self, self.nShipIndex + 1)
end

local function OnPosterCheckStateChanged(self, bIsChecked)
    self.bPosterMode = bIsChecked
    if bIsChecked then
        self.pWidgetRef.bdrActorListener:SetVisibility(ESlateVisibility.Collapsed)
        self.pbWindowFrame.pWidgetRef.imgBg:SetVisibility(ESlateVisibility.HitTestInvisible)
        UISetUtils.SetImageBrushRes(self.pbWindowFrame.pWidgetRef.imgBg, self.tbShipResTemplate.szBigPicPath:load())
    else
        self.pWidgetRef.bdrActorListener:SetVisibility(ESlateVisibility.Visible)
        self.pbWindowFrame.pWidgetRef.imgBg:SetVisibility(ESlateVisibility.Collapsed)
        self.ulLobbyShipDisplay:SetShipResTemplate(self.tbShipResTemplate)
    end
end

local function OnClickedBtnPurchase(self)
    ShopSystem:OnBuyButtonClick(self.tbGoodsTemplate)
end

local function OnExpirationTimeEnd(self)
    self.pWidgetRef.hboxExpirationTime:SetVisibility(ESlateVisibility.Collapsed)
    UpdateShipSkinGallery(self)
end

local function HiddenTips(self)
    UIToolTipHelper:HideTip()
end

local function ShowSkillTips(self, nSkillId, pPressedWidgetRef)
    local tbSkillResTemplate = SkillDataTable:GetResTemplate(nSkillId)

    local tbTipData = {
        szTitle = tbSkillResTemplate.l10nName,
        szDetail = tbSkillResTemplate.l10nDesc,
    }
    UIToolTipHelper:ShowTipInAutoLayout(UIToolTipHelper.TipType.TEXT_TIP, tbTipData, pPressedWidgetRef)
end

local function OnSkillButtonPressed(self, nSkillId, pPressedWidgetRef)
    ShowSkillTips(self, nSkillId, pPressedWidgetRef)
end

local function OnSkillButtonReleased(self, nSkillId)
    HiddenTips(self)
end

local function OnShipSkinSelectedChanged(self)
    UpdateShipSkin(self)
end

local function OnTabBarSelectedChanged(self, nIndex)
    self.pWidgetRef.wsDetail:SetActiveWidgetIndex(nIndex - 1)
end

local function OnAddItem(self, Item)
    local nItemTemplateId = Item:GetTemplateId()
    local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    if nCategory == ItemCategoryDef.SHIP then
        if nItemTemplateId == self.nTemplateId then
            UnlockShip(self)
        end
    elseif nCategory == ItemCategoryDef.SHIP_SKIN then
        if tbItemTemplate.nShipItemId == self.nTemplateId then
            UpdateShipSkinGallery(self, nItemTemplateId)
        end
    end
end

local function OnItemChangeExpiredAt(self, nItemInstanceId, bPermanent)
    if not bPermanent then
        return
    end
    local Item = ItemSystem:GetItem(nItemInstanceId)
    OnAddItem(self, Item)
end

local function OnReceiveShipSkinChanged(self, nShipTemplateId)
    if nShipTemplateId == self.nTemplateId then
        UpdateShipSkinGallery(self)
    end
end

function UILobbyShipDetail:OnLoad()
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbShipMaterials = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbShipMaterials)

    -- 初始化3D模型显示
    self.ulLobbyShipDisplay =self.UILogicHelper:CreateUILogic("ULLobbyShipDisplay")

    -- 初始化详细信息
    self.uLShipDetailContent = self.UILogicHelper:CreateUILogic("ULShipDetailContent")
    self.uLShipDetailContent:InitListHelper(self.pWidgetRef.listShipProperties)

    -- 初始化皮肤列表
    self.GalleryHelper = SelfGalleryHelper()
    self.GalleryHelper:Init(self, self.pWidgetRef.glrySkin)
    self.GalleryHelper.OnSelectedChangedDelegate:Bind(OnShipSkinSelectedChanged, self)

    -- 初始化右侧TabBar
    self.TabBarHelper = SelfTabBarHelper()
    self.TabBarHelper:Init(self, self.pWidgetRef.hboxTabBar)
    self.TabBarHelper.OnSelectedChangedDelegate:Bind(OnTabBarSelectedChanged, self)

    -- 初始化技能相关图标
    BindShipSkillPrefabs(self)

    -- 设置舰船体验时间显示位数
    self.pWidgetRef.txtExpirationTime:SetPrecision(2)

    -- 初始化排过序的舰船模板数据
    InitSortedShipTemplates(self)
end

function UILobbyShipDetail:OnUnload()
    self.GalleryHelper:Uninit()
    self.GalleryHelper = nil
    self.TabBarHelper:Uninit()
    self.TabBarHelper = nil
end

function UILobbyShipDetail:OnBindEvent(EventHelper)
    EventHelper:RegisterLuaDelegate(self.OnSkillButtonPressedDelegate, OnSkillButtonPressed, self)
    EventHelper:RegisterLuaDelegate(self.OnSkillButtonReleasedDelegate, OnSkillButtonReleased, self)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnLastShip.OnClicked, self, OnClickedBtnLastShip)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnNextShip.OnClicked, self, OnClickedBtnNextShip)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.chkPoster.OnCheckStateChanged, self, OnPosterCheckStateChanged)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnPurchase.OnClicked, self, OnClickedBtnPurchase)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.txtExpirationTime.OnCompleteTimer, self, OnExpirationTimeEnd)
    EventHelper:RegisterEvent(ClientEventDef.EV_ADD_LOBBY_ITEM, self, OnAddItem)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHANGE_LOBBY_ITEM_EXPIRED_AT, self, OnItemChangeExpiredAt)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SHIP_SKIN_CHANGED, self, OnReceiveShipSkinChanged)
end

function UILobbyShipDetail:OnEnter()
    for i, v in ipairs(self.tbSortedShipTemplates) do
        if v.nId == self.tbOpenArgs.nShipTemplateId then
            SetShipIndex(self, i)
            break
        end
    end
end

return UILobbyShipDetail