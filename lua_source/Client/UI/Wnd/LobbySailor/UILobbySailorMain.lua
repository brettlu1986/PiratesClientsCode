
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbySailorMain = luaclass("UILobbySailorMain", WndBase)
local UILobbySailorDef = require("UILobbySailorDef")
local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local SailorRedDotDef = require("SailorRedDotDef")
local SelfTabBarHelper = require("SelfTabBarHelper")
local SailorCategoryDef = require("SailorCategoryDef")
local ItemSystem = require("ItemSystem")
local UIUtils = require("UIUtils")

UILobbySailorMain.tbTabBarHelper = nil
UILobbySailorMain.pbWindowFrame = nil

local function OnSelectSailorTab(self, nIndex)
    self.EventHelper:FireEvent(ClientEventDef.EV_LOBBYSAILOR_TO_NEXT, UILobbySailorDef.UI[nIndex])
end

local function SetRedDotVisible(self, nIndex, bRedVisible)
    self.tbTabBarHelper:SetTipIconVisible(nIndex, bRedVisible)
end

local function RefreshRedDotVisible(self)
    local SailorComponent = GamePlayerSelfHelper:Get().SailorComponent
    for i=1, SailorRedDotDef.MAX do
        local bRedVisible = SailorComponent:GetSailorRedDotVisible(i)
        SetRedDotVisible(self, i, bRedVisible)
    end
end

local function GetSailorComponent()
    local tbPlayer = GamePlayerSelfHelper:Get()
    return tbPlayer and tbPlayer.SailorComponent
end

local function RefreshSailorLevels(self)
    local tbSailorEquippedData = GetSailorComponent():GetSailorEquippedData()
    local nTotalGrade, nTotalAtt, nTotalDef, nTotalHelp = 0,0,0,0
    for nSailorId, nCount in pairs(tbSailorEquippedData) do
        if nCount > 0 then
            local tbTemplate = ItemSystem:GetItemTemplate(nSailorId)
            if tbTemplate.nSubCategory == SailorCategoryDef.Cannon then
                nTotalAtt = nTotalAtt + (tbTemplate.nGrade + 1) * nCount
            elseif tbTemplate.nSubCategory == SailorCategoryDef.Deck then
                nTotalDef = nTotalDef + (tbTemplate.nGrade + 1) * nCount
            elseif tbTemplate.nSubCategory == SailorCategoryDef.Logistics then
                nTotalHelp = nTotalHelp + (tbTemplate.nGrade + 1) * nCount
            end
            nTotalGrade = nTotalGrade + (tbTemplate.nGrade + 1) * nCount
        end
    end

    self.pWidgetRef.TxtTotalLv:SetText(nTotalGrade)
    self.pWidgetRef.TxtAttLv:SetText(nTotalAtt)
    self.pWidgetRef.TxtDefLv:SetText(nTotalDef)
    self.pWidgetRef.TxtHelpLv:SetText(nTotalHelp)
end

local function OnRedDotVisibleChanged(self)
    RefreshRedDotVisible(self)
end

local function OnBack()
    UIUtils.BottomMenuSelect(1, true)
end

function UILobbySailorMain:OnLoad()
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetBackDelegate(OnBack, self)
    self.pbWindowFrame:SetSpecialCurrency(UILobbySailorDef.CURRENCY_ID)
    self.tbTabBarHelper = SelfTabBarHelper()
    self.tbTabBarHelper:Init(self, self.pWidgetRef.vboxTab, -1)
    self.tbTabBarHelper.OnSelectedChangedDelegate:Bind(OnSelectSailorTab, self)
    UILobbySailorMain.super.OnLoad(self)
end

function UILobbySailorMain:OnUnload()
    if self.tbTabBarHelper then
        self.tbTabBarHelper:Uninit()
        self.tbTabBarHelper = nil
    end
end

function UILobbySailorMain:OnShow()
    UILobbySailorMain.super.OnShow(self)
    RefreshRedDotVisible(self)
    RefreshSailorLevels(self)
    self:PlayAnimation("anim_LobbySailorMainIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
    self:PlayAnimation("anim_LobbySailorMainIn02", 0, 1, EUMGSequencePlayMode.Forward, 1)
    self:PlayAnimation("animGlow01", 0, 0, EUMGSequencePlayMode.Forward, 1)
end

function UILobbySailorMain:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SAILOR_RED_DOT_VISIBLE_CHANGED, self, OnRedDotVisibleChanged)
    
end

return UILobbySailorMain
