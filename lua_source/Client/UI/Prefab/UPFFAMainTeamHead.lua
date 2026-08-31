-----------------------------------------------------
--File Name    : UPFFAMainTeamHead.lua
--Description  : UPFFAMainTeamHead
-----------------------------------------------------
local luaclass = require ("luaclass")
local UPFFABase = require("UPFFABase")
local UPFFAMainTeamHead = luaclass("UPFFAMainTeamHead", UPFFABase)


local MapOpFFATeamMemberHead = require("MapOpFFATeamMemberHead")
local UIMapResDataTable = require("UIMapResDataTable")
local DungeonDataTable = require("DungeonDataTable")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local TeamHeadNameSystem = require("TeamHeadNameSystem")

UPFFAMainTeamHead.tbMemberPrefabs = {}
UPFFAMainTeamHead.tbMapOpFFATeamMemberHead = nil
UPFFAMainTeamHead.ViewerObj = nil
UPFFAMainTeamHead.tbLastWatchObj = nil

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

--[[
    public function
]]
function UPFFAMainTeamHead:OnLoad()
    self.ViewerObj = self.Owner.tbCurrrentWatchObj
    InitUserWidgetParam(self)
    self.tbMapOpFFATeamMemberHead = MapOpFFATeamMemberHead()
    self.tbMapOpFFATeamMemberHead:Init(self)
    self.tbMapOpFFATeamMemberHead:BindEvent()
end

function UPFFAMainTeamHead:OnBindEvent(EventHelper)
    
    
end

function UPFFAMainTeamHead:OnHide()
    self.tbMapOpFFATeamMemberHead:Uninit()
end

function UPFFAMainTeamHead:Activate()
    InitUserWidgetParam(self)
    self.tbMapOpFFATeamMemberHead:Reinit()
end

function UPFFAMainTeamHead:Deactivate()
    
end

--观战时切换观战玩家视角
function UPFFAMainTeamHead:OnResetTarget()
    self.ViewerObj = self.Owner.tbCurrrentWatchObj
    self.tbLastWatchObj = self.Owner.tbLastWatchObj
    if self.tbLastWatchObj then
        TeamHeadNameSystem:HideDistance(false, self.tbLastWatchObj:GetServerInstanceId())
    end
    if self.ViewerObj then
        TeamHeadNameSystem:HideDistance(true, self.ViewerObj:GetServerInstanceId())
    end
    InitUserWidgetParam(self)
    self.tbMapOpFFATeamMemberHead:Reinit()
end


return UPFFAMainTeamHead
