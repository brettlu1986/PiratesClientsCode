-----------------------------------------------------
--File Name    : LobbyCaptain.lua
--Author       : WuJizhou
--Create Time  : 5/6/2020, 10:17:30 AM
--Description  : LobbyCaptain
-----------------------------------------------------

local luaclass = require("luaclass")
local LobbySubBase = require("LobbySubBase")
local LobbyCaptain = luaclass("LobbyCaptain", LobbySubBase)

local UIDef                 = require("UIDef")
local UIUtils               = require("UIUtils")
local UITextDef             = require("UITextDef")
local UIManager             = require("UIManager")
local UISetUtils            = require("UISetUtils")
local ItemDataTable         = require("ItemDataTable")
local ClientEventDef        = require("ClientEventDef")
local ItemCategoryDef       = require("ItemCategoryDef")
local BlackScreenHelper     = require("BlackScreenHelper")
local LobbyCaptainMiscDef   = require("LobbyCaptainMiscDef")


local FeatureType = LobbyCaptainMiscDef.FeatureType

local tbFeatureOverrideFunctionNames =
{
    "Init",
    "Uninit",
    "Activate",
    "Deactivate",
    "MakeContext",
    "ParseContext"
}

LobbyCaptain.tbFeatures = nil
LobbyCaptain.EventHelper = nil
LobbyCaptain.nCurFeatureType = nil
LobbyCaptain.bActive = false


local function DoRegisterFeature(self, nFeatureType, szFeatureScriptName, l10nTabKey)
    local tbFeatures = self.tbFeatures
    if not tbFeatures then
        tbFeatures = {}
        self.tbFeatures = tbFeatures
    end
    if tbFeatures[nFeatureType] then
        logerror("LobbyCaptain", string.format("feature already exists, type is %d", nFeatureType))
        return
    end
    local tbScript = require(szFeatureScriptName)
    local bCheckFuncExist = true
    for _, szFuncName in ipairs(tbFeatureOverrideFunctionNames) do
        local fnFunc = tbScript[szFuncName]
        if not fnFunc or type(fnFunc) ~= "function" then
            logerror("LobbyCaptain", string.format("feature function does not exist, func is %s", szFuncName))
            bCheckFuncExist = false
            break
        end
    end
    if not bCheckFuncExist then
        return
    end
    tbFeatures[nFeatureType] = {tbScript = tbScript, l10nTabKey = l10nTabKey}
end

local function RegisterFeatures(self)
    DoRegisterFeature(self, FeatureType.Visual,     "LobbyCaptainVisual", UITextDef.UI_STATIC_LOBBY_CAPTAIN_VISUAL)
    DoRegisterFeature(self, FeatureType.Decoration, "LobbyCaptainDecoration", UITextDef.UI_STATIC_LOBBY_CAPTAIN_DECORATION)
end

local function GetFeatureScript(self, nFeatureType)
    local tbFeatureData = self.tbFeatures[nFeatureType]
    if tbFeatureData then
        return tbFeatureData.tbScript
    end
end

local function InitFeatures(self)
    for _, nFeatureType in pairs(FeatureType) do
        local tbScript = GetFeatureScript(self, nFeatureType)
        if tbScript then
            tbScript:Init()
        end
    end
end

local function UninitFeatures(self)
    for _, nFeatureType in pairs(FeatureType) do
        local tbScript = GetFeatureScript(self, nFeatureType)
        if tbScript then
            tbScript:Uninit()
        end
    end
end


local function ShowOverviewUI(self)
    local tbParams = {}
    tbParams.tbFeatures = self.tbFeatures
    UIManager:OpenWnd(UIDef.UI_LOBBY_CAPTAIN, tbParams)
end


local function CloseOverViewUI(self)
    UIManager:CloseWnd(UIDef.UI_LOBBY_CAPTAIN)
end

local function ShowOverviewScene(self)
    self:SetShouldBeVisible(UIDef.UI_LOBBY_CAPTAIN, true)
    self:SetCamera(UIDef.UI_LOBBY_CAPTAIN, 1)
end


local function ActivateOverview(self)
    ShowOverviewScene(self)
    ShowOverviewUI(self)
end

local function NoFunc()
    UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_FUNCTION_NOT_OPEN"), 0.2)
end

local function OnCallActivateFeature(self, nType, tbParam)
    local FullDisplayCallback = function ()
        local tbFeature = GetFeatureScript(self, nType)
        if tbFeature then
            self:SetShouldBeVisible(UIDef.UI_LOBBY_CAPTAIN, false)
            UIManager:CloseWnd(UIDef.UI_LOBBY_CAPTAIN)
            tbFeature:Activate(self, tbParam == nil and {} or tbParam)
        else
            NoFunc()
        end
        self.nCurFeatureType = nType
        BlackScreenHelper:CloseBlackScreen()
    end
    BlackScreenHelper:ShowBlackScreen(false, FullDisplayCallback, nil)
end

local function OnCallDeactivateFeature(self, nType)
    local FullDisplayCallback = function ()
        local tbFeature = GetFeatureScript(self, nType)
        if tbFeature then
            tbFeature:Deactivate()
        else
            NoFunc()
        end
        self.nCurFeatureType = nil
        ActivateOverview(self)
        BlackScreenHelper:CloseBlackScreen()
    end
    BlackScreenHelper:ShowBlackScreen(false, FullDisplayCallback, nil)
end


local function RegisterEventOnActivate(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_CAPTAIN_CALL_TO_ACIVATE_FEATURE, self, OnCallActivateFeature)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_CAPTAIN_CALL_TO_DEACIVATE_FEATURE, self,  OnCallDeactivateFeature)
end

local function UnregisterEventOnDeactivate(self)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_LOBBY_CAPTAIN_CALL_TO_ACIVATE_FEATURE)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_LOBBY_CAPTAIN_CALL_TO_DEACIVATE_FEATURE)
end

-- 对参数进行二次加工解析
local function ProcessParam(tbOutParam)
    if tbOutParam.nItemTemplateId then
        local tbItemTemplate = ItemDataTable:GetTemplate(tbOutParam.nItemTemplateId)
        local nCategory = tbItemTemplate.nCategory
        if nCategory == ItemCategoryDef.FASHION 
            or nCategory == ItemCategoryDef.HUMAN_WEAPON_FASHION 
            or nCategory == ItemCategoryDef.SUIT then
            tbOutParam.nFeatureType = FeatureType.Visual
        elseif nCategory == ItemCategoryDef.DECORATION then
            tbOutParam.nFeatureType = FeatureType.Decoration
        end
    end
end

-- 从tbContext中恢复数据，传入tbParam
local function OnRestart(self, tbContext, tbOutParam)
    local nFeatureType = tbContext.nFeatureType
    if nFeatureType then
        local tbFeature = GetFeatureScript(self, nFeatureType)
        tbOutParam.nFeatureType = nFeatureType
        tbFeature:ParseContext(tbContext, tbOutParam)
    end
end


-- 根据tbParam正常的激活流程
local function OnStart(self, tbParam)
    LobbyCaptain.super.Activate(self)
    RegisterEventOnActivate(self)
    ProcessParam(tbParam)
    local nFeatureType = tbParam.nFeatureType
    if nFeatureType then
        OnCallActivateFeature(self, nFeatureType, tbParam)
    else
        ActivateOverview(self)
    end
    self.bActive = true
end


function LobbyCaptain:GetRestoreContext()
    local tbOutContext = {}
    if self.nCurFeatureType then
        local tbFeature = GetFeatureScript(self, self.nCurFeatureType)
        tbOutContext.nFeatureType = self.nCurFeatureType
        tbFeature:MakeContext(tbOutContext)
    end
    return tbOutContext
end

function LobbyCaptain:Init(Owner, nSubType)
    LobbyCaptain.super.Init(self, Owner, nSubType)
    RegisterFeatures(self)
    InitFeatures(self)

    return true
end

function LobbyCaptain:Uninit()
    if self.bActive then
        self:Deactivate()
    end
    UninitFeatures(self)
    self.tbFeatures = nil
    LobbyCaptain.super.Uninit(self)
end

function LobbyCaptain:Activate(tbParam)
    tbParam = tbParam == nil and {} or tbParam
    local tbContext = self.tbRestoreContext
    if tbContext then
        OnRestart(self, tbContext, tbParam)
    end
    OnStart(self, tbParam)
end

function LobbyCaptain:Deactivate()
    if self.nCurFeatureType then
        local tbFeature = GetFeatureScript(self, self.nCurFeatureType)
        if tbFeature then
            tbFeature:Deactivate()
        end
    end
    CloseOverViewUI(self)
    LobbyCaptain.super.Deactivate(self)
    UnregisterEventOnDeactivate(self)
    self.bActive = false
end


return LobbyCaptain