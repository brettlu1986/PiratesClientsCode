-----------------------------------------------------
--File Name    : UPDebugGMPanel.lua
--Author       : Song Fuhao
--Create Time  : 2018-04-19
--Description  : DebugGM面板
-----------------------------------------------------
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPDebugGMPanel = luaclass("UPDebugGMPanel", PrefabBase)

local L10N = require("L10N")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local GMIDiomDataTable = require("GMIDiomDataTable")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local SelfVerticalListHelper = require("SelfVerticalListHelper")

local GMModeType = { All = 0, Lobby = 1, Dungeon = 2}
local L10N_OP_COMPLETE = UISetUtils.GetL10NTextByKey("UIDEBUGWIDGET_L10N_OP_COMPLETE")

-- @TODO: Filter by mode
local function GetGMIdiom(bInstance)
    local tbNewGMData = {}
    local bBattle = GlobalVariableSystem:IsInDungeon()
    local tbGMData = GMIDiomDataTable:GetContainer()
    for _, v in ipairs(tbGMData) do
        if ((bInstance and v.nInstanceType ~= 0) or not bInstance) and (v.nMode == GMModeType.All or (bBattle and v.nMode == GMModeType.Dungeon) or ( not bBattle and v.nMode == GMModeType.Lobby)) then
            table.insert(tbNewGMData, v)
        end
    end
    return tbNewGMData
end

local function GetGMDataByFilter(self, szFilterName)
    local nPos
    local tbNewData = {}
    local tbGMData = GetGMIdiom()
    for _, v in ipairs(tbGMData) do
        nPos = string.find(v.szUsage, szFilterName)
        if nPos and nPos > 0 then
            table.insert(tbNewData, v)
        end
    end
    return tbNewData
end

local function OnGMSearchTextChanged(self, l10nFilterText)
    local tbNewGMData = GetGMDataByFilter(self, L10N:ToString(l10nFilterText))
    self.tbListHelper:SetData(tbNewGMData)
end

local function ExecuteGM(self)
    local szGmContent = L10N:ToString(self.pWidgetRef.txtFinalGM:GetText())
    if string.len(szGmContent) > 0 then
        KismetSystemLibrary.ExecuteConsoleCommand(GWorld, szGmContent, GameplayStatics.GetPlayerController(GWorld, 0))
        UIUtils.ShowToast(L10N_OP_COMPLETE)
    end
end

local function OnClearGM(self)
    self.pWidgetRef.txtGMSearch:SetText("")
end

function UPDebugGMPanel:OnLoad()
    self.tbListHelper = SelfVerticalListHelper()
    self.tbListHelper:Init(self, self.pWidgetRef.klistGM, GetGMIdiom())
    self.tbListHelper.tbExtraDatas.bGM = true
end

function UPDebugGMPanel:OnUnload()
    self.tbListHelper:Uninit()
end

function UPDebugGMPanel:OnBindEvent(Helper)
    local pWidgetRef = self.pWidgetRef
    Helper:RegisterCppDelegate(pWidgetRef.btnEnterGM.OnClicked      , self, ExecuteGM)
    Helper:RegisterCppDelegate(pWidgetRef.txtGMSearch.OnTextChanged , self, OnGMSearchTextChanged)
    Helper:RegisterCppDelegate(pWidgetRef.btnGMClear.OnClicked      , self, OnClearGM)
end

function UPDebugGMPanel:SetGmContent(szContent)
    self.pWidgetRef.txtFinalGM:SetText(szContent)
end

return UPDebugGMPanel
