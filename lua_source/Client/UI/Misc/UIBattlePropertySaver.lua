-----------------------------------------------------
--File Name    : UIBattlePropertySaver.lua
--Author       : Ran Jie
--Create Time  : 2017-05-23
--Description  : 战斗属性变化记录
-----------------------------------------------------

local UIBattlePropertySaver = {}

-- import require
local ArenaSystem = require("ArenaSystem")
local PlayerPropertySystem = require("PlayerPropertySystem")
local SaveGameDef = require("SaveGameDef")

UIBattlePropertySaver.nPlayerExp = nil
UIBattlePropertySaver.nArenaPoint = nil


function UIBattlePropertySaver:RecordProperty()
    local ArenaComponent = ArenaSystem:GetComponent()
    if(ArenaComponent == nil)then
        return
    end
    --logdebug("ArenaComponent="..tostring(ArenaComponent))
    self.nPlayerExp = PlayerPropertySystem:GetPlayerExp()
    self.nArenaPoint = ArenaComponent:GetArenaPoint()
    self:SaveArenaPoint(self.nArenaPoint)
end

function UIBattlePropertySaver:IsArenaDivisionUP(nArenaPoint)
    local ArenaComponent = ArenaSystem:GetComponent()
    local nArenaPointBefore = self:LoadArenaPoint()
    --logdebug("IsArenaDivisionUP, nArenaPoint="..tostring(nArenaPoint).." now arena point="..ArenaSystem:GetComponent():GetArenaPoint())
    local nArenaPointNow = nArenaPoint
    if(nArenaPointNow == nil)then
        nArenaPointNow = ArenaComponent:GetArenaPoint()
    end
    
    local tbDivisionBefore = ArenaComponent:GetDivisionTemplate(nArenaPointBefore)
    local tbDivisionNow = ArenaComponent:GetDivisionTemplate(nArenaPointNow)
    return tbDivisionNow.nArenaPoint > tbDivisionBefore.nArenaPoint
end

function UIBattlePropertySaver:SaveArenaPoint(nArenaPoint)
    log("UIBattlePropertySaver:SaveArenaPoint,nArenaPoint="..nArenaPoint)
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    pSaveGameMgr:AddIntData(SaveGameDef.BATTLE_ARENA_POINT, nArenaPoint)
    pSaveGameMgr:Save()
end

function UIBattlePropertySaver:LoadArenaPoint()
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    local nArenaPoint = pSaveGameMgr:GetIntData(SaveGameDef.BATTLE_ARENA_POINT)
    log("UIBattlePropertySaver:LoadArenaPoint,nArenaPoint="..tostring(nArenaPoint))
    if(nArenaPoint == nil)then
        nArenaPoint = ArenaSystem:GetComponent():GetArenaPoint()
    end
    return nArenaPoint
end


return UIBattlePropertySaver
