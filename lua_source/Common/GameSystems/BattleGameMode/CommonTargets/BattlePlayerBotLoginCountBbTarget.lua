-- 玩家血量

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattlePlayerBotLoginCountBbTarget = luaclass("BattlePlayerBotLoginCountBbTarget", BattleTargetBaseClass)

local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local BattleBlackboard = require("BattleBlackboard")

BattlePlayerBotLoginCountBbTarget.szSetCountKey = nil
BattlePlayerBotLoginCountBbTarget.szSetBotCountKey = nil

function BattlePlayerBotLoginCountBbTarget:Init()
    BattlePlayerBotLoginCountBbTarget.super.Init(self)
    self.szName = "BattlePlayerBotLoginCountBbTarget"
end

function BattlePlayerBotLoginCountBbTarget:Parse(tbJsonData)
    self.szSetBotCountKey = tbJsonData.SetBotCountKey
    self.szSetCountKey = tbJsonData.SetCountKey
    return true
end

local function IsStopCheck(self)
    local bRet = false

    local szKey = "INTER_GM_StopSelectPointCondition"
    if BattleBlackboard:IsDefined(szKey) then
        bRet = BattleBlackboard:GetBool(szKey)
    end

    return bRet
end

local function CheckPlayerLoginCount(self)
    local nPlayerLoginCount = 0
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for Object, _ in pairs(tbObjects) do
        nPlayerLoginCount = nPlayerLoginCount + 1
    end

    local nSetCount = 1
    if self.szSetCountKey and string.len(self.szSetCountKey) > 0 then
        nSetCount = BattleBlackboard:GetNumber(self.szSetCountKey)
    end
    if nPlayerLoginCount >= nSetCount then
        return true
    end
    return false
end

local function OnPlayerLogin(self)
    local nBotCount = 0
    if self.szSetBotCountKey and string.len(self.szSetBotCountKey) > 0 then
        nBotCount = BattleBlackboard:GetNumber(self.szSetBotCountKey)
    end

    if nBotCount <= 0 then
        return
    end
    
    if not IsStopCheck(self) and CheckPlayerLoginCount(self) then
        self:Complete()
    end
end

-- local function OnPlayerLogout(self)
--     if CheckPlayerLoginCount(self) then
--         self:Complete()
--     end
-- end

function BattlePlayerBotLoginCountBbTarget:RegisterEvent()
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, OnPlayerLogin)
    -- EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGOUT, self, OnPlayerLogout)

end

function BattlePlayerBotLoginCountBbTarget:UnregisterEvent()

    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, OnPlayerLogin)
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGOUT, self, self.OnPlayerLogout)

end

function BattlePlayerBotLoginCountBbTarget:Start()
    BattlePlayerBotLoginCountBbTarget.super.Start(self)

    if CheckPlayerLoginCount(self) then
        self:Complete()
    end
end

return BattlePlayerBotLoginCountBbTarget