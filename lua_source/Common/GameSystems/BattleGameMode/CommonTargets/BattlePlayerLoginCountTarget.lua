-- 玩家血量

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattlePlayerLoginCountTarget = luaclass("BattlePlayerLoginCountTarget", BattleTargetBaseClass)

local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

BattlePlayerLoginCountTarget.nCount = 1

function BattlePlayerLoginCountTarget:Init()
    BattlePlayerLoginCountTarget.super.Init(self)
    self.szName = "BattlePlayerLoginCountTarget"
end

function BattlePlayerLoginCountTarget:Parse(tbJsonData)
    self.nCount = tbJsonData.Count
    return true
end

local function CheckPlayerLoginCount(self)
    local nPlayerLoginCount = 0
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for Object, _ in pairs(tbObjects) do
        nPlayerLoginCount = nPlayerLoginCount + 1
    end
    if nPlayerLoginCount >= self.nCount then
        return true
    end
    return false
end

local function OnPlayerLogin(self)
    if CheckPlayerLoginCount(self) then
        self:Complete()
    end
end

-- local function OnPlayerLogout(self)
--     if CheckPlayerLoginCount(self) then
--         self:Complete()
--     end
-- end

function BattlePlayerLoginCountTarget:RegisterEvent()
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, OnPlayerLogin)
    -- EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGOUT, self, OnPlayerLogout)

end

function BattlePlayerLoginCountTarget:UnregisterEvent()

    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, OnPlayerLogin)
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGOUT, self, self.OnPlayerLogout)

end

function BattlePlayerLoginCountTarget:Start()
    BattlePlayerLoginCountTarget.super.Start(self)

    if CheckPlayerLoginCount(self) then
        self:Complete()
    end
end

return BattlePlayerLoginCountTarget