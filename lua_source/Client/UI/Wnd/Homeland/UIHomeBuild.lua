-----------------------------------------------------
--File Name    : UIHomeBuild.lua
--Author       : zheng
--Create Time  : 2019-04-25
--Description  : 家园建造界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIHomeBuild = luaclass("UIHomeBuild", WndBase)
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local UIManager = require("UIManager")
local UIStateDef = require("UIStateDef")
local HomelandSceneSystem = require("HomelandSceneSystem")
local UIDef = require("UIDef")
local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local HomelandSystem = require("HomelandSystem")
local BuildingDataTable = require("BuildingDataTable")
local UISetUtils = require("UISetUtils")
local ItemSystem = require("ItemSystem")
local BlockTypeDataTable = require("BlockTypeDataTable")
local ItemCategoryDef = require("ItemCategoryDef")
local LobbyItemUiHelper = require("LobbyItemUiHelper")
local UIResourceDef = require("UIResourceDef")

local ILLEGAL_INSTANCE_ID = -1

UIHomeBuild.ListHelper = nil
UIHomeBuild.nCurrentBlockId = -1
UIHomeBuild.nCurrentBuildId = -1
UIHomeBuild.nCurrentInstanceId = ILLEGAL_INSTANCE_ID
UIHomeBuild.tbCurrentBlockObj = nil
UIHomeBuild.nRotId = 1

local DEFAULT_INDEX = 1
local MIN_ROT_ID = 1
local MAX_ROT_ID = 4

local function InitUIWidget(self)
    --select default item
    self.ListHelper:SetSelectedIndex(DEFAULT_INDEX)
end

local function PlayFocusCamera(self)
    self.EventHelper:FireEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, GameCameraModeGroupDef.BuildingView, { pTarget = self.tbCurrentBlockObj.pUEActor })
end

local function PlayUnfocusCamera(self)
    self.EventHelper:FireEvent(ClientEventDef.EV_DEACTIVE_CAMERA_GROUP, GameCameraModeGroupDef.BuildingView)
end

local function OnPlaceItemBuilding(self, nBlockId, nItemInstanceId, nRotationId)
    if nItemInstanceId == self.nCurrentInstanceId then
        PlayUnfocusCamera(self)
        HomelandSceneSystem:CreateBuilding(self.nCurrentBlockId, self.nCurrentBuildId)

        UIManager:PopState(UIStateDef.StateName.UI_HOMELAND_BUILD_STATE)
        --UIManager:PushState(UIStateDef.StateName.UI_HOMELAND_STATE, {}, true)
    end
end

local function OnBuild(self)
    if self.nCurrentInstanceId ~= ILLEGAL_INSTANCE_ID then
        HomelandSystem:RequestPlaceItemBuilding(self.nCurrentBlockId, self.nCurrentInstanceId, self.nRotId)
    end
end

local function OnCancel(self)
    PlayUnfocusCamera(self)
    HomelandSceneSystem:RemoveBuilding(self.nCurrentBlockId)

    UIManager:PopState(UIStateDef.StateName.UI_HOMELAND_BUILD_STATE)
    --UIManager:PushState(UIStateDef.StateName.UI_HOMELAND_STATE, {}, true)
end

local function OnDecorationItemSelect(self, nSelectIdx)
    local pWidgetRef = self.pWidgetRef
    local tbItemData = self.ListHelper:GetSelectedData()
    if not tbItemData then
        return
    end
    local nCount = tbItemData.nAvailableCount
    local tbTemplate
    if nCount > 0 then
        local tbItem = tbItemData.Item
        tbTemplate = tbItem:GetTemplate()
        self.nCurrentInstanceId = tbItem.nInstanceId
    else
        tbTemplate = tbItemData.ItemTemplate
        self.nCurrentInstanceId = ILLEGAL_INSTANCE_ID
    end

    pWidgetRef.txtName:SetText(tbTemplate.l10nName)
    pWidgetRef.kmtxtDesc:SetText(tbTemplate.l10nIntro)

    local nBuildId = tbTemplate.nBuildingId
    local tbBuildTemplate = BuildingDataTable:GetTemplate(nBuildId)
    local szIconRes = tbBuildTemplate.szIcon
    local pRes = szIconRes:load()
    UISetUtils.SetImageBrushRes(pWidgetRef.Image_1, pRes)
    self.nCurrentBuildId = nBuildId
    self.nRotId = MIN_ROT_ID
    pWidgetRef.kmtxtSize:SetText(LobbyItemUiHelper.GetBuildingSizeDesc(tbTemplate))
    UISetUtils.SetImageBrushRes(pWidgetRef.imgCost, pRes)

    if nCount > 0  then
        pWidgetRef.kmtxtCostCount:SetColorAndOpacity(UIResourceDef.COLOR.GREEN.SLATE_COLOR)
        pWidgetRef.btnBuild:SetIsEnabled(true)
    else
        pWidgetRef.kmtxtCostCount:SetColorAndOpacity(UIResourceDef.COLOR.RED.SLATE_COLOR)
        pWidgetRef.btnBuild:SetIsEnabled(false)
    end
    HomelandSceneSystem:PreviewBuilding(self.nCurrentBlockId, self.nCurrentBuildId)
    HomelandSceneSystem:ChangeBuildingRotaion(self.nCurrentBlockId, self.nRotId)
end

local function OnLeftRotate(self)
    self.nRotId = self.nRotId - 1
    if self.nRotId < MIN_ROT_ID then
        self.nRotId = MAX_ROT_ID
    end
    HomelandSceneSystem:ChangeBuildingRotaion(self.nCurrentBlockId, self.nRotId)
end

local function OnRightRotate(self)
    self.nRotId = self.nRotId + 1
    if self.nRotId > MAX_ROT_ID then
        self.nRotId = MIN_ROT_ID
    end
    HomelandSceneSystem:ChangeBuildingRotaion(self.nCurrentBlockId, self.nRotId)
end

local function LockPlayerInput(self, bLock)
    local SelfObj = GamePlayerSelfHelper:Get()
    if SelfObj then
        SelfObj.pUEActor.PlayerInputComponent:SetMoveEnabled(not bLock)
    end
end

local function GetDecorationDatas(self)
    local tbRetItems = {}
    local tbBlockData = HomelandSystem:GetBlockData(self.nCurrentBlockId)
    local nBlockType = tbBlockData.nBlockType
    local tbBlockTemplate = BlockTypeDataTable:GetTemplate(nBlockType)
    local nBlockWidth = tbBlockTemplate.nWidth
    local nBlockLength = tbBlockTemplate.nLength

    local HomelandItemSystem = HomelandSystem:GetSubSystem("HomelandItemSystem")
    local tbAvailableItems = HomelandItemSystem:GetAllAvailableItems()
    local tbOwnedTemplates = {}

    for _, tbItemData in ipairs(tbAvailableItems) do
        local tbItem = tbItemData.Item
        local nTemplateId =  tbItem:GetTemplateId()
        local tbTemplate = tbItem:GetTemplate()
        local nBuildingId = tbTemplate.nBuildingId
        local tbBuildingTemplate = BuildingDataTable:GetTemplate(nBuildingId)
        local nLength = tbBuildingTemplate.nLength
        local nWidth = tbBuildingTemplate.nWidth
        if nBlockWidth == nWidth and nBlockLength == nLength then
            tbOwnedTemplates[nTemplateId] = true
            local tbItemDataNew = {}
            tbItemDataNew.Item = tbItem
            tbItemDataNew.nAvailableCount = tbItemData.nAvailableCount
            table.insert(tbRetItems, tbItemDataNew)
        end
    end

    local tbItemTemplates = ItemSystem:GetItemTemplatesByCategory(ItemCategoryDef.DECORATIVE_BUILDING)
    for nId, v in pairs(tbItemTemplates) do
        local nBuildingId = v.nBuildingId
        local tbBuildingTemplate = BuildingDataTable:GetTemplate(nBuildingId)
        local nLength = tbBuildingTemplate.nLength
        local nWidth = tbBuildingTemplate.nWidth
        if nBlockWidth == nWidth and nBlockLength == nLength and not tbOwnedTemplates[nId] then
            local tbItemDataNew = {}
            tbItemDataNew.ItemTemplate = v
            tbItemDataNew.nAvailableCount = 0
            table.insert(tbRetItems, tbItemDataNew)
        end
    end
    return tbRetItems
end

function UIHomeBuild:OnLoad()
    --当前地块的id，用于查找 TriggerActor
    self.nCurrentBlockId = self.tbOpenArgs.nBlockId
    self.tbCurrentBlockObj = HomelandSceneSystem:GetBlock(self.nCurrentBlockId)
    LockPlayerInput(self, true)

    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    PrefabHelper:BindPrefab(pWidgetRef.pbCutoutScreenAdapter)
    PrefabHelper:BindPrefab(pWidgetRef.pbCurrencyBar)

    self.ListHelper = SelfVerticalListHelper()
    local tbDecorations = GetDecorationDatas(self)
    self.ListHelper:Init(self, self.pWidgetRef.BuildingList, tbDecorations, UIDef.UP_HOME_DECORATION_ITEM)
    self.ListHelper.OnSelectedChangedDelegate:Bind(OnDecorationItemSelect, self)
end

function UIHomeBuild:OnUnload()
    LockPlayerInput(self, false)
    self.ListHelper:Uninit()
end

function UIHomeBuild:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnBuild.OnClicked, self, OnBuild)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnCancel.OnClicked, self, OnCancel)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnLeft.OnClicked, self, OnLeftRotate)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnRight.OnClicked, self, OnRightRotate)

    EventHelper:RegisterEvent(ClientEventDef.EV_PLACE_ITEM_BUILDING, self, OnPlaceItemBuilding)
end

function UIHomeBuild:OnEnter()
    InitUIWidget(self)
    PlayFocusCamera(self)
end

function UIHomeBuild:OnHide()

end

return UIHomeBuild