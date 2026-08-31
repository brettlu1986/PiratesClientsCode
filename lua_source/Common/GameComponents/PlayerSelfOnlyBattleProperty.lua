local luaclass = require("luaclass")
local PropertyComponentBaseClass = require("PropertyComponentBase")
local PlayerSelfOnlyBattleProperty = luaclass("PlayerSelfOnlyBattleProperty", PropertyComponentBaseClass)

-- local ReplicationBinder = require("ReplicationBinder")
-- local ReplicateHelper = require("ReplicateHelper")
-- -- local EventManager = require("EventManager")
-- -- local CommonEventDef = require("CommonEventDef")

-- PlayerSelfOnlyBattleProperty.ReplicateHelper = nil
-- PlayerSelfOnlyBattleProperty.tbBindInfo = nil

-- function PlayerSelfOnlyBattleProperty:DefineProperties(fnDefine, tbParams)
--     PlayerSelfOnlyBattleProperty.super.DefineProperties(self, fnDefine, tbParams)

--     --fnDefine(self, PropName.nCommonRecoverLimit,                nCommonRecoverLimit                                         )   -- 一般药物恢复上限制
-- end

-- function PlayerSelfOnlyBattleProperty:OnActorCreated(pUEActor)
--     -- 什么都不做
-- end

-- -- @protected
-- function PlayerSelfOnlyBattleProperty:OnActorDestroyed(pUEActor)
--     -- 什么都不做
-- end

-- function PlayerSelfOnlyBattleProperty:BindRepCallback(nPropId, varCurrentValue, fnRepCallback)
--     self.ReplicateHelper:Bind(nPropId, varCurrentValue, nil, fnRepCallback, false)
-- end

-- function PlayerSelfOnlyBattleProperty:OnCreate(Owner, tbParams)
--     PlayerSelfOnlyBattleProperty.super.OnCreate(self, Owner, tbParams)

--     local pUEController = Owner.pUEController
--     if(pUEController == nil) then
--         -- Bot
--         return
--     end

--     self.ReplicateHelper = ReplicateHelper()
--     self.tbBindInfo = ReplicationBinder.Bind(self.ReplicateHelper, pUEController, self, ReplicationBinder.TYPE_CONTROLLER)
--     self:BindAllRepProperties()
-- end

-- function PlayerSelfOnlyBattleProperty:OnDestroy()
--     if(self.ReplicateHelper) then
--         self:UnbindAllRepProperties()

--         ReplicationBinder.Unbind(self.tbBindInfo, self.Owner.pUEController)
--     end

--     PlayerSelfOnlyBattleProperty.super.OnDestroy(self)
-- end


return PlayerSelfOnlyBattleProperty
