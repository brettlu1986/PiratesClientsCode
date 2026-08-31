-- 玩家血量

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattlePlayerLoginCountBbTarget = luaclass("BattlePlayerLoginCountBbTarget", BattleTargetBaseClass)

local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local BattleBlackboard = require("BattleBlackboard")
local BotAISystem = dynamic_require("BotAISystem")

BattlePlayerLoginCountBbTarget.szSetCountKey = nil

function BattlePlayerLoginCountBbTarget:Init()
    BattlePlayerLoginCountBbTarget.super.Init(self)
    self.szName = "BattlePlayerLoginCountBbTarget"
end

function BattlePlayerLoginCountBbTarget:Parse(tbJsonData)
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
        if not BotAISystem:IsBot(Object) then
            nPlayerLoginCount = nPlayerLoginCount + 1
        end
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
    if not IsStopCheck(self) and CheckPlayerLoginCount(self) then
        self:Complete()
    end
end

-- local function OnPlayerLogout(self)
--     if CheckPlayerLoginCount(self) then
--         self:Complete()
--     end
-- end

function BattlePlayerLoginCountBbTarget:RegisterEvent()
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, OnPlayerLogin)
    -- EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGOUT, self, OnPlayerLogout)

end

function BattlePlayerLoginCountBbTarget:UnregisterEvent()

    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, OnPlayerLogin)
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGOUT, self, self.OnPlayerLogout)

end

function BattlePlayerLoginCountBbTarget:Start()
    BattlePlayerLoginCountBbTarget.super.Start(self)

    if CheckPlayerLoginCount(self) then
        self:Complete()
    end
end

return BattlePlayerLoginCountBbTarget