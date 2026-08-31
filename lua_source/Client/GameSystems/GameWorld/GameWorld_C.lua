local luaclass = require("luaclass")
local GameWorldClass = require("GameWorld")
local GameWorld_C = luaclass("GameWorld_C", GameWorldClass)

local UEMapLoader = require("UEMapLoader")
local CppDelegate = require("CppDelegate")
local SceneDataTable = require("SceneDataTable")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local SceneResDataTable = require("SceneResDataTable")
local GameWorldDef = require("GameWorldDefine")
--local PlayerSelfHelper = require("GamePlayerSelfHelper")

GameWorld_C.bIsOcean = false
GameWorld_C.bIsBigPort = false
GameWorld_C.nSceneId = nil
GameWorld_C.PostLoadMapHandler = nil
GameWorld_C.WorldRestartHandler = nil

local function UnbindDelegates(self)
    if(self.PostLoadMapHandler) then
        self.PostLoadMapHandler:Unbind()
        self.PostLoadMapHandler = nil
    end
    if (self.WorldRestartHandler) then
        self.WorldRestartHandler:Unbind()
        self.WorldRestartHandler = nil
    end
end

local function LoadUEMap(self, szNewMapName, szNewMapPath, bAsync)
    -- 构造回调函数
    local OnPostLoadMap = function()
        log("Load map end: "..szNewMapPath)
        UnbindDelegates(self)
        EventManager:OnFireEvent(ClientEventDef.EV_POST_LOAD_MAP)
    end

    local DelegateMgr = ClientShell.GetClient(GWorld):GetGameDelegateManager()
    self.PostLoadMapHandler = CppDelegate:Bind(DelegateMgr.Level.OnPostLoadMap, OnPostLoadMap)
    self.WorldRestartHandler = CppDelegate:Bind(DelegateMgr.Level.OnWorldRestart, OnPostLoadMap)

    -- 开始加载
    EventManager:OnFireEvent(ClientEventDef.EV_PRE_LOAD_MAP)
    local szCurrentMapName = EngineExtShell.Get(GWorld):GetCurrentMapName()
    if(szCurrentMapName == szNewMapName) then
        -- 地图名一样不加载
        log("Load map start: New map is same as the old one: "..szNewMapName)
        if(OnPostLoadMap) then
            OnPostLoadMap()
        end
    else
        log("Load map start: "..szNewMapPath, bAsync)
        if(bAsync) then
            UEMapLoader:LoadMapAsync(szNewMapPath)
        else
            UEMapLoader:LoadMap(szNewMapPath, true, "")
        end
    end
    return true
end

local function LoadMapBySceneData(self, tbCreateData, bLoadAsync)
    local nSceneId = tbCreateData.nSceneId

    -- 获取各种信息
    local tbSceneData = SceneDataTable:GetTemplate(nSceneId)
    if(tbSceneData == nil) then
        logerror("GameWorld_C:LoadNewMap failed, cannot find scene: ", nSceneId)
        return false
    end

    self.bIsOcean = (tbSceneData.nType == GameWorldDef.Type.OCEAN)
    self.bIsBigPort = (tbSceneData.nType == GameWorldDef.Type.BIG_PORT)
    self.nSceneId = nSceneId
    local nResId = tbSceneData.nResID

    local tbResInfo = SceneResDataTable:GetTemplate(nResId)
    if(nil == tbResInfo) then
        logerror("GameWorld_C:LoadNewMap failed, res is nil" .. nSceneId)
        return false
    end

    return LoadUEMap(self, tbResInfo.szMapName, tbResInfo.szPath, bLoadAsync)
end

function GameWorld_C:Create(tbCreateData)
    if(tbCreateData ~= nil) then
        if(tbCreateData.bLoadNewMap) then
            local bLoadAsync = tbCreateData.bLoadAsync == nil or tbCreateData.bLoadAsync == true
            local szMapName = tbCreateData.szMapName
            if(szMapName) then
                LoadUEMap(self, szMapName, szMapName, bLoadAsync)
            else
                return LoadMapBySceneData(self, tbCreateData, bLoadAsync)
            end
        elseif(tbCreateData.bDungeon) then
            -- 副本的直接发事件
            self.bIsOcean = true
            self.bIsBigPort = false
            self.nSceneId = nil
            EventManager:OnFireEvent(ClientEventDef.EV_PRE_LOAD_MAP)
            EventManager:OnFireEvent(ClientEventDef.EV_POST_LOAD_MAP)
        end
    else
        logerror("game world create failed not create data")
    end

    return GameWorld_C.super.Create(self, tbCreateData)
end

function GameWorld_C:Destroy()
    log("game world destroy ", self.nSceneId)
    UnbindDelegates(self)
    GameWorld_C.super.Destroy(self)
end

function GameWorld_C:IsOcean()
    return self.bIsOcean
end

function GameWorld_C:IsBigPort()
    return self.bIsBigPort
end

return GameWorld_C
