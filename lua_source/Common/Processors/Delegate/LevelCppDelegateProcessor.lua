local luaclass = require("luaclass")
local CppDelegateProcessorBaseClass = require("CPPDelegateProcessorBase")
local LevelCppDelegateProcessor = luaclass("LevelCppDelegateProcessor", CppDelegateProcessorBaseClass)

local GameWorldSystem = require("GameWorldSystem")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")

-- 现在底下这些没有实质性的作用，等有需求在补上

local function OnWorldCreation(pWorld, nWorldUniqueId, pLevelActor, nLevelUniqueId, szScriptType)
    log("OnWorldCreation", nWorldUniqueId)
    -- local tbBattleWorld = BattleWorldManager:CreateWorld(pWorld, nWorldUniqueId)
    -- if szScriptType ~= nil and szScriptType ~= "" then
    --     local tbLevelActor = tbBattleWorld:AddLevelActor(szScriptType, nLevelUniqueId, pLevelActor, true)
    --     log("OnWorldCreation:", tbBattleWorld, nWorldUniqueId, " PersistentLevel:", tbLevelActor, nLevelUniqueId, szScriptType)
    -- end

    GameWorldSystem:CreateWorld({bDungeon = true})
end

-- local function OnWorldRestart(pWorld, nWorldUniqueId, pLevelActor, nLevelUniqueId, szScriptType)
--     log("OnWorldRestart", nWorldUniqueId)
--     -- local tbBattleWorld = BattleWorldManager:CreateWorld(pWorld, nWorldUniqueId)
--     -- -- Create World
--     -- log("OnWorldRestart:", tbBattleWorld, nWorldUniqueId)
--     -- if szScriptType ~= nil and szScriptType ~= "" then
--     --     local tbLevelActor = tbBattleWorld:AddLevelActor(szScriptType, nLevelUniqueId, pLevelActor, true)
--     --     log("AddLevelActor:", tbLevelActor, nLevelUniqueId, szScriptType)
--     -- end
--     -- -- Change World
--     -- log("OnCurrentWorldChanged", nWorldUniqueId)
--     -- BattleWorldManager:SwitchCurrentWorld(nWorldUniqueId)
-- end

local function OnWorldCleanup(nUniqueId)
    log("OnWorldCleanup", nUniqueId)
    GameWorldSystem:DestroyWorld()
end

-- local OnCurrentWorldChanged = function(nUniqueId)
--     log("OnCurrentWorldChanged", nUniqueId)
--     --BattleWorldManager:SwitchCurrentWorld(nUniqueId)    
-- end

local function OnLevelAddedToWorld(pLevelActor, szLevelName, nIsPersistent)
--[[
    if szScriptType ~= nil and szScriptType ~= "" then
        local tbBattleWorld = GetCurrentBattleWorld()
        if tbBattleWorld ~= nil and tbBattleWorld:GetUniqueId() == nWorldUniqueId then
            local tbLevelActor = tbBattleWorld:AddLevelActor(szScriptType, nLevelUniqueId, pActor, nIsPersistent)
            log("OnLevelAddedToWorld Level:", tbLevelActor, nLevelUniqueId, szScriptType, " World:", tbBattleWorld, nWorldUniqueId)
        end
    end
]]
    EventManager:OnFireEvent(CommonEventDef.EV_LEVEL_ADDED_TO_WORLD, pLevelActor, szLevelName, nIsPersistent)
end

-- local function OnLevelRemovedFromWorld(nLevelUniqueId, nWorldUniqueId)
--     local tbBattleWorld = GetCurrentBattleWorld()
--     if tbBattleWorld ~= nil and tbBattleWorld:GetUniqueId() == nWorldUniqueId then
--         local tbLevelActor = tbBattleWorld:RemoveLevelActor(nLevelUniqueId)
--         log("OnLevelRemovedFromWorld Level:", tbLevelActor, nLevelUniqueId, " World:", tbBattleWorld, nWorldUniqueId)
--     end
-- end

function LevelCppDelegateProcessor:Init()
    LevelCppDelegateProcessor.super.Init(self)
    -- Register Gameplay Delegate
    local DelegateMgr = CommonShell.GetCommon(GWorld):GetGameDelegateManager()
    local Level = DelegateMgr.Level
    self:Register(Level.OnWorldCreation, OnWorldCreation)
    --self:Register(Level.OnWorldRestart, OnWorldRestart)
    self:Register(Level.OnWorldCleanup, OnWorldCleanup)
    --self:Register(DelegateMgr.OnCurrentWorldChanged, OnCurrentWorldChanged)
    self:Register(Level.OnLevelAddedToWorld, OnLevelAddedToWorld)
    -- self:Register(DelegateMgr.Level.OnLevelRemovedFromWorld, OnLevelRemovedFromWorld)

    return true
end

return LevelCppDelegateProcessor
