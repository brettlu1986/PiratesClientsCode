-- Player角色

local luaclass = require("luaclass")
local GamePlayer = require("GamePlayer")
local GamePlayer_C = luaclass("GamePlayer_C", GamePlayer)
local GameObjectTypeDef = require("GameObjectTypeDef")

GamePlayer_C.nDungeonHumanId = 1
GamePlayer_C.bPolyMorph = false

function GamePlayer_C:ParseCreateData(tbCreateData)
    if(not GamePlayer_C.super.ParseCreateData(self, tbCreateData)) then
        return false
    end
    self.nDungeonHumanId = tbCreateData.nHumanId
    return true
end

function GamePlayer_C:OnActorCreated(pUEActor)
    GamePlayer_C.super.OnActorCreated(self, pUEActor)

    -- register to significance
    if(self:IsHuman() and self.ObjectType ~= GameObjectTypeDef.PlayerSelf )then
        if(pUEActor)then
            pUEActor:RegisterToSignificance()
            -- logerror("pActor:RegisterToSignificance******")
        end
    end

end

function GamePlayer_C:UnbindUEActor()
    -- Unregister from significance
    if(self:IsHuman())then
        if(self.pUEActor) then
            self.pUEActor:UnRegisterFromSignificance()
            -- logerror("pActor:UnRegisterFromSignificance******")
        end
    end
    
    GamePlayer_C.super.UnbindUEActor(self)
end


-- todo临时测试用
-- local UIUtils = require("UIUtils")
-- local SelfEventHelper = require("SelfEventHelper")
-- local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
-- GamePlayer_C.EventHelper = nil

-- function GamePlayer_C:DamageEvent(nDamage, pUEActor)
--     if pUEActor == GamePlayerSelfHelper:Get().pUEActor then
--         UIUtils.ShowToast("受到伤害" .. nDamage)
--     else
--         UIUtils.ShowToast("造成伤害" .. nDamage)
--     end
-- end


-- function GamePlayer_C:OnActorCreated(pUEActor)

--     if pUEActor.DamageEvent then
--         self.EventHelper = SelfEventHelper()

--         self.EventHelper:RegisterCppDelegate(pUEActor.DamageEvent, self, self.DamageEvent)
--     end
--     GamePlayer_C.super.OnActorCreated(self, pUEActor)
-- end

-- function GamePlayer_C:UnbindUEActor()
--     if self.EventHelper then
--         self.EventHelper:UnregisterAll()
--     end
--     GamePlayer_C.super.UnbindUEActor(self)
-- end
-- end todo

return GamePlayer_C
