-----------------------------------------------------
--File Name    : LobbySystem.lua
--Author       : Ran Jie
--Create Time  : 2019-07-02
--Description  : 大厅
-----------------------------------------------------
local LobbySubTypeDef = require("LobbySubTypeDef")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local LobbySystem = {}

local BlackScreenHelper = require("BlackScreenHelper")
local UIUtils = require("UIUtils")
local UIManager = require("UIManager")
local LobbyFOVLockHelper = require("LobbyFOVLockHelper")

LobbySystem.tbSub = nil
LobbySystem.EventHelper = nil
LobbySystem.nCurrentType = LobbySubTypeDef.NONE
LobbySystem.tbRestorableSubList = nil


local function RegisterSubSystem(self, nSubSystemType, szSubSystemClass)
    local tbScriptClass = require(szSubSystemClass) 
    local tbInstance = tbScriptClass()
    tbInstance:Init(self, nSubSystemType)
    self.tbSub[nSubSystemType] = tbInstance
end

local function RegisterAll(self)
    RegisterSubSystem(self, LobbySubTypeDef.NONE, "LobbySubBase")
    RegisterSubSystem(self, LobbySubTypeDef.MAIN, "LobbyMain")
    RegisterSubSystem(self, LobbySubTypeDef.SAILOR, "LobbySailor")
    RegisterSubSystem(self, LobbySubTypeDef.SEASON, "LobbySeason")
    RegisterSubSystem(self, LobbySubTypeDef.SHIP, "LobbyShip")
    RegisterSubSystem(self, LobbySubTypeDef.CAPTAIN, "LobbyCaptain")
    RegisterSubSystem(self, LobbySubTypeDef.BACKPACK, "LobbyBackpack")
    RegisterSubSystem(self, LobbySubTypeDef.AWARD, "LobbyAward")
    RegisterSubSystem(self, LobbySubTypeDef.SHOW, "LobbyShow")
    RegisterSubSystem(self, LobbySubTypeDef.SCHEDULE, "LobbySchedule")
end


function LobbySystem:Init()
    self.tbSub = {}
    self.tbRestorableSubList = {}
    RegisterAll(self)
    LobbyFOVLockHelper:Init()
    return true
end

function LobbySystem:Uninit()
    for k, v in pairs(self.tbSub) do
        v:Uninit()
    end
    self.tbSub = nil
    self.tbCurrentActiveSub = nil
    LobbyFOVLockHelper:Uninit()
end

--激活一个subsystem，停用上一个subsystem，同时清空记录subsystem的列表
function LobbySystem:Activate(nType, tbParam)
    if #self.tbRestorableSubList > 0 then
        self.tbRestorableSubList = {}
    end
    UIManager:ResetCurrentState()
    local function FullDisplayCallback()
        self:Deactivate()
        log("LobbySystem:Activate", nType)
        local tbNewActivateSub = self.tbSub[nType]
        self.nCurrentType = nType
        self.tbCurrentActiveSub = tbNewActivateSub
        if tbNewActivateSub then
            tbNewActivateSub:SetRestoreContext(nil)
            tbNewActivateSub:Activate(tbParam)
            EventManager:OnFireEvent(ClientEventDef.EV_LOBBY_SUB_SYSTEM_ACTIVATE, nType)        
        end
        BlackScreenHelper:CloseBlackScreen()
    end
    log("LobbySystem:Activate, ShowBlackScreen")
    BlackScreenHelper:ShowBlackScreen(false, FullDisplayCallback, nil)
    
end

--停用当前的subsytem
function LobbySystem:Deactivate()
    local tbCurrentActiveSub = self.tbCurrentActiveSub
    if tbCurrentActiveSub then   
        log("LobbySystem:Deactivate", tbCurrentActiveSub.nSubType)
        tbCurrentActiveSub:Deactivate()
        self.tbCurrentActiveSub = nil
    end
end

--激活下一个substem，停用上一个subsystem，并记录上一个待恢复的subsytem
function LobbySystem:ActivateNextSub(nType, tbParam)
    local function FullDisplayCallback()
        local tbCurrentActiveSub = self.tbCurrentActiveSub
        if tbCurrentActiveSub then
            log("LobbySystem:Deactivate", tbCurrentActiveSub.nSubType)
            local tbRestoreSub = {}
            tbRestoreSub.tbSub = tbCurrentActiveSub
            tbRestoreSub.tbContext = tbCurrentActiveSub:GetRestoreContext()
            table.insert(self.tbRestorableSubList, tbRestoreSub)
            tbCurrentActiveSub:Deactivate()
        end
        log("LobbySystem:ActivateNextSub", nType)
        local tbNewActivateSub = self.tbSub[nType]
        self.nCurrentType = nType
        self.tbCurrentActiveSub = tbNewActivateSub
        if tbNewActivateSub then
            tbNewActivateSub:Activate(tbParam)
            EventManager:OnFireEvent(ClientEventDef.EV_LOBBY_SUB_SYSTEM_ACTIVATE, nType)        
        end
        BlackScreenHelper:CloseBlackScreen()
    end
    log("LobbySystem:ActivateNextSub, ShowBlackScreen")
    BlackScreenHelper:ShowBlackScreen(false, FullDisplayCallback, nil)
end

--停用当前的subsytem，并返回到上一个subsystem，和ActivateNextSub成对使用
function LobbySystem:ReturnToPrevSub()
    
    local function FullDisplayCallback()
        if #self.tbRestorableSubList == 0 then
            log("LobbySystem:ReturnToPrevSub, tbRestorableSubList is empty, return to lobby main")
            local tbSub = self:GetActiveSub()
            if tbSub then
                self:Deactivate()
                UIUtils.BottomMenuSelect(LobbySubTypeDef.MAIN, true)
            end
        else
            local tbRestoreSub = table.remove(self.tbRestorableSubList)
            local tbSub = tbRestoreSub.tbSub
            local tbContext = tbRestoreSub.tbContext
            UIUtils.BottomMenuSelect(tbSub.nSubType)
            self:Deactivate()
            log("LobbySystem:ReturnToPrevSub",tbSub.nSubType)
            self.tbCurrentActiveSub = tbSub
            tbSub:SetRestoreContext(tbContext)
            tbSub:Activate()
        end
        
    end
    log("LobbySystem:ReturnToPrevSub, ShowBlackScreen")
    BlackScreenHelper:ShowBlackScreen(false, FullDisplayCallback, nil)
end

---------------------------------------------------------------------
function LobbySystem:LoadAllSubLevelAsync()
    for k, v in pairs(self.tbSub) do
        if v ~= self.tbCurrentActiveSub then
            v:PreloadResoucesAsync()
        end
    end
end

function LobbySystem:GetSub(nSubType)
    if not self.tbSub then
        return
    end
    return self.tbSub[nSubType]
end

function LobbySystem:GetActiveSub()
    return self.tbCurrentActiveSub
end

return LobbySystem