-----------------------------------------------------
--File Name    : UPFFACompass.lua
--Description  : UPFFACompass
-----------------------------------------------------
local luaclass = require ("luaclass")
local UPFFABase = require("UPFFABase")
local UPFFACompass = luaclass("UPFFACompass", UPFFABase)


local MapOpFFACompass = require("MapOpFFACompass")
local UIMapResDataTable = require("UIMapResDataTable")
local DungeonDataTable = require("DungeonDataTable")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local ClientEventDef = require("ClientEventDef")

local START_ANGLE = -360--270
local END_ANGLE = 180--270
local DIRECTION_GAP = 45

UPFFACompass.ViewerObj = nil

local function InitUserWidgetParam(self)
    local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
    if bIsInDungeon then
        local nDungeonId = BattleGameModeSystem.nDungeonId
        --logdebug("nObservedSceneID=",nObservedSceneID)
        local tbDungeonTemplate = DungeonDataTable:GetTemplate(nDungeonId)
        local tbMapResData = UIMapResDataTable:GetTemplate(tbDungeonTemplate.nUIMapId)
        local MapSize = Vector2D{
            X = tbMapResData.nMapSizeX, 
            Y = tbMapResData.nMapSizeY}
        local UIMapValidSize = Vector2D{
            X = 1080, 
            Y = 1080}
        local UIMapValidOffset = Vector2D{
            X = 0, 
            Y = 0}
        local MapOrigin = Vector2D{X = -tbMapResData.nMapSizeX / 2, Y = - tbMapResData.nMapSizeY / 2}
        local UIMapOrigin = Vector2D{X = 0, Y = 0}
        self.pWidgetRef:InitMapParam(MapSize, UIMapValidSize, UIMapValidOffset, MapOrigin, UIMapOrigin)
    end
end

local function OnClearAllFlagPoint(self)
    --if self.tbMapOpFFACompass then
        --self.tbMapOpFFACompass:Uninit()
        --self.tbMapOpFFACompass = nil
    --end
end
--[[
    public function
]]

UPFFACompass.tbMapOpFFACompass = nil

function UPFFACompass:OnLoad()
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    
    local nWidgetIndex = 1
    for i = START_ANGLE, END_ANGLE, DIRECTION_GAP do
        local nIndex = math.floor((i + 360) % 360 / DIRECTION_GAP)
        if nWidgetIndex <= 12 then
            local pbDirection = PrefabHelper:BindPrefab(pWidgetRef["pbCompassItem_"..nWidgetIndex])
            pbDirection:SetDirection(nIndex + 1)
        end
        nWidgetIndex = nWidgetIndex + 1
    end
    InitUserWidgetParam(self)
    self.tbMapOpFFACompass = MapOpFFACompass()
    self.tbMapOpFFACompass:Init(self)
    self.tbMapOpFFACompass:BindEvent()
end

function UPFFACompass:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_CLEAR_ALL_FLAG_POINT, self, OnClearAllFlagPoint) 
end

function UPFFACompass:OnHide()
    if self.tbMapOpFFACompass then
        self.tbMapOpFFACompass:Uninit()
        self.tbMapOpFFACompass = nil
    end
end

function UPFFACompass:Activate()
    InitUserWidgetParam(self)
    if self.tbMapOpFFACompass then
        self.tbMapOpFFACompass:Reinit()
    end
end

function UPFFACompass:Deactivate()
    
end

function UPFFACompass:OnResetViewObj()
    self.ViewerObj = self.Owner.tbCurrrentWatchObj
end


return UPFFACompass
