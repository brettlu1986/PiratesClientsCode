-----------------------------------------------------
--File Name    : PlayerBasicInfoSystem.lua
--Author       : WuJizhou
--Create Time  : 3/21/2019, 2:59:30 PM
--Description  : PlayerBasicInfoSystem
-----------------------------------------------------
local PlayerBasicInfoSystem = {}

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")

PlayerBasicInfoSystem.OLD_LEVEL_INDEX = 1
PlayerBasicInfoSystem.NEW_LEVEL_INDEX = 2

-- 缓存未表现过的升级信息
-- 如果有多条升级协议，会将多条汇总整理
-- [1]: 升级前等级， [2]: 升级后等级
PlayerBasicInfoSystem.tbLevelUpInfo = {}
PlayerBasicInfoSystem.bLevelUpInfoExist = false

function PlayerBasicInfoSystem:OnExpSynced(nExp)
    local tbPlayer = GamePlayerSelfHelper:Get()
    local LobbyPropertyComponent = tbPlayer.LobbyPropertyComponent
    LobbyPropertyComponent:SetExp(nExp)
    EventManager:OnFireEvent(ClientEventDef.EV_PLAYER_EXP_SYNC_NEW)
end

function PlayerBasicInfoSystem:OnLevelUp(nNewLevel, nNewExp)
    local tbPlayer = GamePlayerSelfHelper:Get()
    local LobbyPropertyComponent = tbPlayer.LobbyPropertyComponent
    if self.bLevelUpInfoExist then
        local nNewLevelCache = self.tbLevelUpInfo[PlayerBasicInfoSystem.NEW_LEVEL_INDEX ]
        self.tbLevelUpInfo[PlayerBasicInfoSystem.NEW_LEVEL_INDEX ] = nNewLevelCache > nNewLevel and nNewLevelCache or nNewLevel
    else
        self.tbLevelUpInfo[PlayerBasicInfoSystem.OLD_LEVEL_INDEX] = LobbyPropertyComponent:GetPlayerLevel()
        self.tbLevelUpInfo[PlayerBasicInfoSystem.NEW_LEVEL_INDEX ] = nNewLevel
        self.bLevelUpInfoExist = true
    end
    LobbyPropertyComponent:SetLevel(nNewLevel)
    LobbyPropertyComponent:SetExp(nNewExp)
    EventManager:OnFireEvent(ClientEventDef.EV_PLAYER_LEVEL_UP_NEW)
end

function PlayerBasicInfoSystem:LevelUpInfoExist()
    return self.bLevelUpInfoExist
end

function PlayerBasicInfoSystem:GetAndResetLevelUpInfo()
    local tbRet = self.tbLevelUpInfo
    self.tbLevelUpInfo = {}
    self.bLevelUpInfoExist = false
    return tbRet
end

function PlayerBasicInfoSystem:OnNameChange(szNewName)
    local tbPlayer = GamePlayerSelfHelper:Get()
    local LobbyPropertyComponent = tbPlayer.LobbyPropertyComponent
    LobbyPropertyComponent:SetName(szNewName)
    EventManager:OnFireEvent(ClientEventDef.EV_PLAYER_NAME_CHANGED)
end

------------------------ Override Api ------------------------

function PlayerBasicInfoSystem:Init()
    self.bLevelUpInfoExist = false
    self.tbLevelUpInfo = {}
    return true
end

function PlayerBasicInfoSystem:Uninit()
    self.bLevelUpInfoExist = false
    self.tbLevelUpInfo = {}
end

return PlayerBasicInfoSystem