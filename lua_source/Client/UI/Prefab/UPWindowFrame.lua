local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPWindowFrame = luaclass("UPWindowFrame", PrefabBase)

local SelfTabBarHelper = require("SelfTabBarHelper")
local LuaDelegate = require("LuaDelegate")
local UISetUtils = require("UISetUtils")

UPWindowFrame.tbTabBarHelper = nil
UPWindowFrame.pTabContentSwitcherRef = nil
UPWindowFrame.tbTabContentNames = nil
UPWindowFrame.tbTabContentWidgets = nil
UPWindowFrame.pbActivatedTabContentWidget = nil
UPWindowFrame.pbCurrencyBar = nil
UPWindowFrame.szCurrencyContentName = nil
UPWindowFrame.OnBackDelegate = nil
UPWindowFrame.bBackIsCloseSelf = nil

local function OnClickedBtnBack(self)
    self.OnBackDelegate:Fire()
    if self.bBackIsCloseSelf then
        self.Owner:CloseSelf()
    end
end

local function OnTabBarSelectedChanged(self, nIndex)
    -- Deactivate之前的Tab内容
    local pbActivatedTabContentWidget = self.pbActivatedTabContentWidget
    if pbActivatedTabContentWidget and pbActivatedTabContentWidget.Deactivate then
        pbActivatedTabContentWidget:Deactivate()
    end

    -- 获取当前Activate的Prefab，没有的话新绑
    pbActivatedTabContentWidget = self.tbTabContentWidgets[nIndex]
    if not pbActivatedTabContentWidget then
        pbActivatedTabContentWidget = self.Owner.PrefabHelper:BindPrefab(self.Owner.pWidgetRef[self.tbTabContentNames[nIndex]])
        self.szCurrencyContentName = self.tbTabContentWidgets[nIndex]
        self.tbTabContentWidgets[nIndex] = pbActivatedTabContentWidget
    end

    -- Activate当前的Tab内容
    if pbActivatedTabContentWidget.Activate then
        pbActivatedTabContentWidget:Activate()
    end
    self.pTabContentSwitcherRef:SetActiveWidget(pbActivatedTabContentWidget.pWidgetRef)
    self.pbActivatedTabContentWidget = pbActivatedTabContentWidget
end

function UPWindowFrame:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnBack.OnClicked, self, OnClickedBtnBack)
end

function UPWindowFrame:OnLoad()
    self.bBackIsCloseSelf = true
    self.OnBackDelegate = LuaDelegate()
    self.PrefabHelper:BindPrefab(self.pWidgetRef.pbCutoutScreenAdapter)
    if self.pWidgetRef.TabBar then
        self.tbTabBarHelper = SelfTabBarHelper()
        self.tbTabBarHelper:Init(self, self.pWidgetRef.nsTabBar:GetContent())
    end
    if self.pWidgetRef.CurrencyBar then
        self.pbCurrencyBar = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbCurrencyBar)
    end
    local szKey = self.pWidgetRef.TitleKey
    if szKey and szKey ~= "" then
        self.pWidgetRef.txtTitleName.Key = szKey
        self.pWidgetRef.Title = UISetUtils.GetL10NTextByKey(szKey)
    end
end

function UPWindowFrame:OnUnload()
    if self.tbTabBarHelper then
        self.tbTabBarHelper:Uninit()
        self.tbTabBarHelper = nil
    end
    self.tbTabContentWidgets = nil
end

function UPWindowFrame:OnEnter()
    if self.pTabContentSwitcherRef then
        OnTabBarSelectedChanged(self, 1)
    end
    --RefreshCoinData(self)
    self:PlayEnterAnim()
    --
end

-- function UPWindowFrame:SetOuterWnd(szOuterWnd)
--     self.szOuterWnd = szOuterWnd
-- end

function UPWindowFrame:SetSelectedTabChanged(fnCallback, tbObject)
    self.tbTabBarHelper.OnSelectedChangedDelegate:Bind(fnCallback, tbObject)
end

function UPWindowFrame:BindWidgetSwitcher(pTabContentSwitcherRef, tbTabContentNames)
    self.tbTabContentWidgets = {}
    self.pTabContentSwitcherRef = pTabContentSwitcherRef
    self.tbTabContentNames = tbTabContentNames
    self:SetSelectedTabChanged(OnTabBarSelectedChanged, self)
end

function UPWindowFrame:PlayEnterAnim()
    self:PlayAnimation("animShow", 0, 1, EUMGSequencePlayMode.Forward, 1, function()
        --引导需要
    end)
end

function UPWindowFrame:PlayExitAnim()
    -- self:PlayAnimation("animShow", 0, 1, EUMGSequencePlayMode.Reverse, 1, function()
    --     OnDialogClosed(self)
    -- end)
end

--添加货币显示，在默认显示货币的基础上增加一种货币
function UPWindowFrame:SetSpecialCurrency(nTemplateId)
    if self.pbCurrencyBar then
        self.pWidgetRef.CurrencyBar = true
        self.pbCurrencyBar:SetSpecialCurrency(nTemplateId)
    end
end

--仅显示参数提供的货币
function UPWindowFrame:ReloadCurrency(tbCurrencyList)
    if self.pbCurrencyBar then
        self.pWidgetRef.CurrencyBar = true
        self.pbCurrencyBar:ReloadCurrency(tbCurrencyList)
    end
end

-- 重置货币为默认显示列表
function UPWindowFrame:ResetCurrency()
    if self.pbCurrencyBar then
        self.pWidgetRef.CurrencyBar = true
        self.pbCurrencyBar:ResetCurrency()
    end
end

-- 隐藏/显示货币栏
function UPWindowFrame:HideCurrency(bHide)
    if self.pbCurrencyBar then
        self.pWidgetRef.CurrencyBar = not bHide
        self.pbCurrencyBar:HideCurrency(bHide)
    end
end

function UPWindowFrame:GeTabBarHelper()
    return self.tbTabBarHelper
end

function UPWindowFrame:SetTitle(szName)
    self.pWidgetRef.txtTitleName:SetText(szName)
end

function UPWindowFrame:SetSelectedTab(nIndex)
    self.tbTabBarHelper:SelectByIndex(nIndex)
    OnTabBarSelectedChanged(self, nIndex)
end

function UPWindowFrame:GetActivatedTabPrefab()
    return self.pbActivatedTabContentWidget
end

function UPWindowFrame:SetBackDelegate(fnCallback, tbObject)
    self.OnBackDelegate:Bind(fnCallback, tbObject)
end

function UPWindowFrame:SetBackIsCloseSelf(bCloseSelf)
    self.bBackIsCloseSelf = bCloseSelf
end

return UPWindowFrame

