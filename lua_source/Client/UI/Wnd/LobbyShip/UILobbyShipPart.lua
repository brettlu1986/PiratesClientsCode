-----------------------------------------------------
--File Name    : UILobbyShipPart.lua
--Author       : chenyixin
--Description  : 舰船零件界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbyShipPart = luaclass("UILobbyShipPart", WndBase)

-- local ItemSystem = require("ItemSystem")
local ItemDataTable = require("ItemDataTable")
-- local ItemSourceDataTable = require("ItemSourceDataTable")
local ClientEventDef = require("ClientEventDef")
-- local ShipPartTypeDef = require("ShipPartTypeDef")
local ItemCategoryDef = require("ItemCategoryDef")
local SelfTabBarHelper = require("SelfTabBarHelper")

UILobbyShipPart.OwnerSub = nil
UILobbyShipPart.tbTemplateData = nil
UILobbyShipPart.tbPartTitles = {}
UILobbyShipPart.nSelectedPosition = nil
UILobbyShipPart.nSelectedTitle = nil
UILobbyShipPart.tbTabBarHelper = nil
UILobbyShipPart.pbWindowFrame = nil
UILobbyShipPart.ulLobbyShipPart = nil

UILobbyShipPart.nPreSelectedCategory = nil

local MAX_TITLE_COUNT = 2

local function TryRequestEquip(self, tbTemplate)
    local OwnerSub = self.OwnerSub
    local ShipPreparationComponent = OwnerSub:GetShipPreparationComponent()
    -- local tbTemplate = self:GetSelectedPartTemplate()
    if ShipPreparationComponent:IsItemUnlocked(tbTemplate.nId) then
        local nActivePart = ShipPreparationComponent:GetActivePartId(tbTemplate.nSubCategory)
        if nActivePart ~= tbTemplate.nId then
            ShipPreparationComponent:RequestActivatePart(tbTemplate.nId)
        end
    else
        OwnerSub:RequestGetItem(tbTemplate)
    end
end

local function UpdateTabBarTips(self)
    local ShipPreparationComponent = self.OwnerSub:GetShipPreparationComponent()
    for nSubCategory, tbAllPartsInCategory in pairs(self.tbTemplateData) do
        local bHasNew = false
        for _, v in pairs(tbAllPartsInCategory) do
            if ShipPreparationComponent:IsNewShipItem(v.nId) then
                bHasNew = true
                break
            end
        end
        self.tbTabBarHelper:SetTipIconVisible(nSubCategory, bHasNew)
    end
end

local function UpdateTitlesData(self)
    local tbTemplates = self:GetSelectedPositionTemplates()
    for i = 1, MAX_TITLE_COUNT do
        self.tbPartTitles[i]:SetData(tbTemplates[i])
        if self.tbPartTitles[i]:IsSelected() then
            self.nSelectedTitle = i
        end
    end
end

local function UpdatePartDisplay(self)
    local tbActivePartIds = self.OwnerSub:GetShipPreparationComponent():GetActivePartIds()
    for _, nId in pairs(tbActivePartIds) do
        self.ulLobbyShipPart:DisplayPart(nId)
    end
end

local function OnReceiveActivatePartResult(self, nPartCategory, nTemplateId)
    local tbPositionTemplates = self.tbTemplateData[nPartCategory]
    local nSlot = nil
    for nIndex, tbTemplate in pairs(tbPositionTemplates) do
        if tbTemplate.nId == nTemplateId then
            nSlot = nIndex
            break
        end
    end
    local tbPartTitle = self.tbPartTitles[nSlot]
    if self.nSelectedTitle and nSlot ~= self.nSelectedTitle then
        self.tbPartTitles[self.nSelectedTitle]:SetSelected(false)
    end
    tbPartTitle:OnActive()
    self.nSelectedTitle = nSlot
    UpdatePartDisplay(self)
end

local function OnPartTitleSelected(self, nSlot)
    local tbPositionTemplates = self:GetSelectedPositionTemplates()
    local tbTemplate = tbPositionTemplates[nSlot]
    TryRequestEquip(self, tbTemplate)

    local ShipPreparationComponent = self.OwnerSub:GetShipPreparationComponent()
    if ShipPreparationComponent:IsNewShipItem(tbTemplate.nId) then
        ShipPreparationComponent:UnmarkNewShipItem(tbTemplate.nId)
        UpdateTabBarTips(self)
        self.tbPartTitles[nSlot]:Refresh()
    end
end

local function OnPartPositionSelected(self, nSelectIndex)
    self.nSelectedPosition = nSelectIndex
    UpdateTitlesData(self)
    self.OwnerSub:ShowShipDisplayScene(true, nSelectIndex, 0.5)
end

local function OnBtnBackClicked(self)
    self.OwnerSub:Return(self:GetWndName())
end

local function InitPartData(self)
    local tbTemplateData = {}
    local tbShipPartTemplates = ItemDataTable:GetTemplatesByCategory(ItemCategoryDef.SHIP_PART)
    for _, tbTemplate in pairs(tbShipPartTemplates) do
        local nCategory = tbTemplate.nSubCategory
        tbTemplateData[nCategory] = tbTemplateData[nCategory] or {}
        table.insert(tbTemplateData[nCategory], tbTemplate)
        
        local nPreSelectedId = self.tbOpenArgs.nItemTemplateId
        if nPreSelectedId and nPreSelectedId == tbTemplate.nId then
            self.nPreselectedCategory = nCategory
        end
    end
    for i, v in ipairs(tbTemplateData) do
        table.sort(v, function(A, B) return A.nId < B.nId end)
    end
    self.tbTemplateData = tbTemplateData
end

local function InitPartTitles(self)
    local pWidgetRef = self.pWidgetRef
    for i = 1, MAX_TITLE_COUNT do
        local tbTitle = self.PrefabHelper:BindPrefab(pWidgetRef["pbPartTitle" .. i])
        tbTitle:BindCallbacks(
            function()
                OnPartTitleSelected(self, i)
            end
        )
        self.tbPartTitles[i] = tbTitle
    end
end

function UILobbyShipPart:OnLoad()
    local tbOpenArgs = self.tbOpenArgs
    self.OwnerSub = tbOpenArgs.OwnerSub
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetBackDelegate(OnBtnBackClicked, self)
    InitPartData(self)
    InitPartTitles(self)
    self.tbTabBarHelper = SelfTabBarHelper()
    self.tbTabBarHelper:Init(self, self.pWidgetRef.vboxTab, 1)
    self.tbTabBarHelper.OnSelectedChangedDelegate:Bind(OnPartPositionSelected, self)
    self.ulLobbyShipPart = self.UILogicHelper:CreateUILogic("ULLobbyShipPart")
end

function UILobbyShipPart:OnUnload()
    if self.tbTabBarHelper then
        self.tbTabBarHelper:Uninit()
        self.tbTabBarHelper = nil
    end
end

function UILobbyShipPart:OnShow()
    local nSelectIndex = 1
    self.OwnerSub:ShowShipDisplayScene(true)

    if self.nPreselectedCategory then
        nSelectIndex = self.nPreselectedCategory
        self.nPreselectedCategory = nil
    end
    UpdateTabBarTips(self)
    self.tbTabBarHelper:SelectByIndex(nSelectIndex, true)
    UpdatePartDisplay(self)
    self:PlayAnimation("anim_LobbyShipPartIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UILobbyShipPart:OnExit()
end

function UILobbyShipPart:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_ACTIVATE_SHIP_PART_RESULT, self, OnReceiveActivatePartResult)
    
end

function UILobbyShipPart:GetSelectedPositionTemplates()
    return self.tbTemplateData[self.nSelectedPosition]
end

function UILobbyShipPart:GetSelectedPartTemplate()
    local tbPositionTemplates = self:GetSelectedPositionTemplates()
    return tbPositionTemplates[self.nSelectedTitle]
end

return UILobbyShipPart