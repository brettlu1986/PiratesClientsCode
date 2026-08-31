-----------------------------------------------------
--File Name    : UPDebugGMInstancePanel.lua
--Author       : Song Fuhao
--Create Time  : 2018-04-19
--Description  : DebugGM实例面板
-----------------------------------------------------
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPDebugGMInstancePanel = luaclass("UPDebugGMInstancePanel", PrefabBase)

local GMIDiomDataTable = require("GMIDiomDataTable")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local tbGMMode = { All = 0, Hub= 1, Dungeon = 2}

local function GetGMIdiom(bInstance)
    local tbNewGMData = {}
    local bBattle = GlobalVariableSystem:IsInDungeon()
    local tbGMData = GMIDiomDataTable:GetContainer()
    for _, v in ipairs(tbGMData) do
        if ((bInstance and v.nInstanceType ~= 0) or not bInstance) and (v.nMode == tbGMMode.All or (bBattle and v.nMode == tbGMMode.Dungeon) or ( not bBattle and v.nMode == tbGMMode.Lobby)) then
            table.insert(tbNewGMData, v)
        end
    end
    return tbNewGMData
end

function UPDebugGMInstancePanel:OnLoad()
    self.tbListHelper = SelfVerticalListHelper()
    self.tbListHelper:Init(self, self.pWidgetRef.klistGMInstance, GetGMIdiom(true))
    self.tbListHelper.tbExtraDatas.bGMInstance = true
end

function UPDebugGMInstancePanel:OnUnload()
    self.tbListHelper:Uninit()
end

return UPDebugGMInstancePanel
