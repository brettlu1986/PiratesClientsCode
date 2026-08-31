local luaclass = require("luaclass")
local ActorCppDelegateProcessor = require("ActorCppDelegateProcessor")
local ActorCppDelegateProcessor_S = luaclass("ActorCppDelegateProcessor_S", ActorCppDelegateProcessor)

-- local GameObjectSystem = dynamic_require("GameObjectSystem")

-- local function OnSerializeNewActor(pActor, nUniqueId)
--     local GameObject = GameObjectSystem:FindByUniqueId(nUniqueId)
--     if(GameObject) then
--         local RepComponent = GameObject.BattlePropertyRepComponent
--         if(RepComponent) then
--             RepComponent:OnSnapshot()
--         end
--     end
-- end


-- function ActorCppDelegateProcessor_S:Init()
--     ActorCppDelegateProcessor_S.super.Init(self)

--     local DelegateMgr = CommonShell.GetCommon(GWorld):GetGameDelegateManager().GameMisc
--     self:Register(DelegateMgr.OnSerializeNewActor, OnSerializeNewActor)
--     return true
-- end

return ActorCppDelegateProcessor_S