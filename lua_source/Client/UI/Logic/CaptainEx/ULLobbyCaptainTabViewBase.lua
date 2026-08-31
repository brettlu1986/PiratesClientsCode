local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")

local ULLobbyCaptainTabViewBase = luaclass("ULLobbyCaptainTabViewBase", UILogicBase)

local ClientEventDef                        = require("ClientEventDef")
local SelfTabBarHelper                      = require("SelfTabBarHelper")
local LobbyCaptainSubCategoryTabBarHelper   = require("LobbyCaptainSubCategoryTabBarHelper")
local LobbyCaptainTabViewMiscDef            = require("LobbyCaptainTabViewMiscDef")

ULLobbyCaptainTabViewBase.nCurrentCategoryIndex = nil
ULLobbyCaptainTabViewBase.nCurrentSubCategoryIndex = nil
ULLobbyCaptainTabViewBase.tbOwnerSystem = nil

 
ULLobbyCaptainTabViewBase.tbCategoryTabHelper = nil
ULLobbyCaptainTabViewBase.tbSubCategoryTabHelper = nil

ULLobbyCaptainTabViewBase.DataFilter = nil      -- sub class of LobbyCaptainTabViewFilter, 过滤候选数据
ULLobbyCaptainTabViewBase.DataPicker = nil      -- sub class of LobbyCaptainDataPicker
ULLobbyCaptainTabViewBase.DataOperator = nil    -- sub class of LobbyCaptainDataOperator, 选中后处理逻辑

ULLobbyCaptainTabViewBase.bActive = false

ULLobbyCaptainTabViewBase.bCategoryChanged = false

local DEFUALT_CATEGORY_INDEX = 1
local DEFUALT_SUBCATEGORY_INDEX = 1


local function OnSubCategoryChanged(self, nIndex)
    if not nIndex or self.nCurrentSubCategoryIndex ~= nIndex or self.bCategoryChanged then
        self.nCurrentSubCategoryIndex = nIndex
        self:RefreshCurrentDataPicker(true)
        self:OnSubCategoryChanged()
        self.bCategoryChanged = false
    end
end

local function DoOnCategoryTabChanged(self, nCategoryTabIndex, nSubCategoryIndex)
    self.nCurrentCategoryIndex = nCategoryTabIndex
    if self.tbSubCategoryTabHelper then
        if nSubCategoryIndex then
            self.tbSubCategoryTabHelper:SelectByIndex(nSubCategoryIndex, true)
        else
            self.tbSubCategoryTabHelper:SelectByIndex(DEFUALT_SUBCATEGORY_INDEX, true)
        end
    else
        OnSubCategoryChanged(self, nil)
    end
    self:OnCategoryTabChanged()
end

local function OnCategoryTabChanged(self, nIndex)
    if self.nCurrentCategoryIndex ~= nIndex then
        self.bCategoryChanged = true
        DoOnCategoryTabChanged(self, nIndex)
    end
end

local function BindCategoryTabs(self)
    local tbInfos = self.DataFilter:GetCategoryInfos()
    if not tbInfos or not next(tbInfos) then
        error("ULLobbyCaptainTabViewBase error, category info can not be nil or empty!!")
    end
    if not self.tbCategoryTabHelper then
        self.tbCategoryTabHelper = SelfTabBarHelper()
        self.tbCategoryTabHelper:Init(self, self.pWidgetRef.vboxContainerCategory, DEFUALT_CATEGORY_INDEX)
        self.tbCategoryTabHelper.OnSelectedChangedDelegate:Bind(OnCategoryTabChanged, self)
        for nIdx = 1, LobbyCaptainTabViewMiscDef.MAX_CATEGORY_INDEX do
            local tbInfo = tbInfos[nIdx]
            if tbInfo then
                self.tbCategoryTabHelper:SetVisibilityByIndex(nIdx, ESlateVisibility_Visible)
                self.tbCategoryTabHelper:SetTabText(nIdx, tbInfo[LobbyCaptainTabViewMiscDef.KEY_DESC])
                self.tbCategoryTabHelper:SetTipIconVisible(nIdx, false)
            else
                self.tbCategoryTabHelper:SetVisibilityByIndex(nIdx, ESlateVisibility_Collapsed)
            end
        end
    end
end

local function BindSubCategoryTabs(self)
    local tbInfos = self.DataFilter:GetSubCategoryInfos()
    if not tbInfos or not next(tbInfos) then
        self.pWidgetRef.ovlSubCategory:SetVisibility(ESlateVisibility.Collapsed)
    else
        self.pWidgetRef.ovlSubCategory:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        if not self.tbSubCategoryTabHelper then
            self.tbSubCategoryTabHelper = LobbyCaptainSubCategoryTabBarHelper()
            self.tbSubCategoryTabHelper:Init(self, self.pWidgetRef.vboxContainerSubCategory, DEFUALT_SUBCATEGORY_INDEX)
            self.tbSubCategoryTabHelper.OnSelectedChangedDelegate:Bind(OnSubCategoryChanged, self)
            for nIdx = 1, LobbyCaptainTabViewMiscDef.MAX_SUBCATEGORY_INDEX  do
                local tbInfo = tbInfos[nIdx]
                if tbInfo then
                    self.tbSubCategoryTabHelper:SetVisibilityByIndex(nIdx, ESlateVisibility_Visible)
                    self.tbSubCategoryTabHelper:SetTabText(nIdx, tbInfo[1])
                    self.tbSubCategoryTabHelper:SetTipIconVisible(nIdx, false)
                    self.tbSubCategoryTabHelper:SetTabIcon(nIdx, tbInfo[LobbyCaptainTabViewMiscDef.KEY_ICON_SELECTED], tbInfo[LobbyCaptainTabViewMiscDef.KEY_ICON_UNSELECTED])
                else
                    self.tbSubCategoryTabHelper:SetVisibilityByIndex(nIdx, ESlateVisibility_Collapsed)
                end
            end
        end
    end
end

local function UnbindCategoryTabs(self)
    if self.tbCategoryTabHelper then
        self.tbCategoryTabHelper:Uninit()
        self.tbCategoryTabHelper = nil
    end
end

local function UnbindSubCategoryTabs(self)
    if self.tbSubCategoryTabHelper then
        self.tbSubCategoryTabHelper:Uninit()
        self.tbSubCategoryTabHelper = nil
    end
end


local function UpdateSelectTab(self)
    if self.nCurrentCategoryIndex then
        self.tbCategoryTabHelper:SelectByIndex(self.nCurrentCategoryIndex, false)
        DoOnCategoryTabChanged(self, self.nCurrentCategoryIndex, self.nSubCategoryIndex)
    else
        self.tbCategoryTabHelper:SelectByIndex(DEFUALT_CATEGORY_INDEX, true)
    end
end

local function CreateDataFilter(self)
    if not self.DataFilter then
        local szClassName = self:GetFilterClass()
        local FilterClass = require(szClassName)
        self.DataFilter = FilterClass()
    end
end

local function DestroyDataFilter(self)
    if self.DataFilter then
        self.DataFilter = nil
    end
end

local function ResetMisc(self)
    self.nCurrentCategoryIndex = nil
    self.nCurrentSubCategoryIndex = nil
end


local function CreateDataPicker(self)
    if not self.DataPicker then
        local szClassName = self:GetPickerClass()
        local PickerClass = require(szClassName)
        self.DataPicker = PickerClass()
    end
end

local function DestroyDataPicker(self)
    if self.DataFilter then
        self.DataFilter = nil
    end
end

local function ActivateDataPicker(self)
    self.DataPicker:SetOwnerPrefab(self.Owner)
    self.DataPicker:Activate()
end

local function DeactivateDataPicker(self)
    self.DataPicker:Deactivate()
    self.DataPicker:SetOwnerPrefab(nil)
end

local function CreateDataOperator(self)
    if not self.DataOperator then
        local szClassName = self:GetDataOperatorClass()
        local OpeartorClass = require(szClassName)
        self.DataOperator = OpeartorClass()
    end
end

local function DestroyDataOperator(self)
    if self.DataOperator then
        self.DataOperator = nil
    end
end

function ULLobbyCaptainTabViewBase:RefreshCurrentDataPicker(bResort)
    local tbDatas
    if bResort then
        tbDatas = self.DataFilter:FilterData(self.nCurrentCategoryIndex, self.nCurrentSubCategoryIndex)
    else
        tbDatas = self.DataFilter:UpdateCurrentDatas()
    end
    self.DataPicker:SetDatas(tbDatas)
    return tbDatas
end

function ULLobbyCaptainTabViewBase:OnPickItem(nItemTemplateId)
    self.DataOperator:ProcessOnPickItem(nItemTemplateId)
    self:RefreshCurrentDataPicker(false)
end

function ULLobbyCaptainTabViewBase:OnUnpickItem(nItemTemplateId)
    self.DataOperator:ProcessOnUnpickItem(nItemTemplateId)
    self:RefreshCurrentDataPicker(false)
end

function ULLobbyCaptainTabViewBase:OnCategoryTabChanged()
    -- call back for sub class
end
function ULLobbyCaptainTabViewBase:OnSubCategoryChanged(tbDatas)
    -- call back for sub class
end

function ULLobbyCaptainTabViewBase:BindEventOnActivate()
    self.EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_CAPTAIN_PICK_ITEM, self, self.OnPickItem)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_CAPTAIN_UNPICK_ITEM, self, self.OnUnpickItem)
end

function ULLobbyCaptainTabViewBase:UnbindEventOnDeactivate()
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_LOBBY_CAPTAIN_PICK_ITEM, self, self.OnPickItem)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_LOBBY_CAPTAIN_UNPICK_ITEM, self, self.OnUnpickItem)
end

function ULLobbyCaptainTabViewBase:GetPickerClass()
    -- should be overrided in child class
end

function ULLobbyCaptainTabViewBase:GetFilterClass()
    -- should be overrided in child class
end

function ULLobbyCaptainTabViewBase:GetDataOperatorClass()
    -- should be overrided in child class
end


function ULLobbyCaptainTabViewBase:Init(tbOwnerSystem)
    self.tbOwnerSystem = tbOwnerSystem
    CreateDataOperator(self)
    CreateDataFilter(self)
    CreateDataPicker(self)
end


function ULLobbyCaptainTabViewBase:Uninit()
    self.tbOwnerSystem = nil
    self:Deactivate()
    DestroyDataPicker(self)
    DestroyDataFilter(self)
    DestroyDataOperator(self)
end


function ULLobbyCaptainTabViewBase:ProcessActivateParams(tbParams)
end

function ULLobbyCaptainTabViewBase:Activate(tbParams)
    if not self.bActive then
        ResetMisc(self)
        self:ProcessActivateParams(tbParams)
        BindCategoryTabs(self)
        BindSubCategoryTabs(self)
        ActivateDataPicker(self)
        UpdateSelectTab(self)
        self:BindEventOnActivate()
        self.bActive = true
    end
end


function ULLobbyCaptainTabViewBase:Deactivate()
    if self.bActive then
        UnbindCategoryTabs(self)
        UnbindSubCategoryTabs(self)
        DeactivateDataPicker(self)
        self:UnbindEventOnDeactivate()
        self.bActive = false
    end
end




-- lifecycle callback

-- function ULLobbyCaptainTabViewBase:OnCreate()
-- end

-- function ULLobbyCaptainTabViewBase:OnDestroy()
-- end

-- function ULLobbyCaptainTabViewBase:OnLoad()

-- end

-- function ULLobbyCaptainTabViewBase:OnUnload()
-- end

-- function ULLobbyCaptainTabViewBase:OnEnter()
-- end

-- function ULLobbyCaptainTabViewBase:OnShow()
-- end

-- function ULLobbyCaptainTabViewBase:OnHide()
-- end

-- function ULLobbyCaptainTabViewBase:OnExit()
-- end

-- function ULLobbyCaptainTabViewBase:OnBindEvent(EventHelper)
-- end

-- function ULLobbyCaptainTabViewBase:OnUnbindEvent(EventHelper)
-- end


return ULLobbyCaptainTabViewBase