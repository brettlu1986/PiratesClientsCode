local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local DestructibleObjectAIComponent = luaclass("DestructibleObjectAIComponent", GameComponentBaseClass)

DestructibleObjectAIComponent.nTransformId = 0

-- luacheck: push ignore
local function LOG(...)
    log("CJ->DestructibleObjectAIComponent:", ...)
end
-- luacheck: pop

function DestructibleObjectAIComponent:OnCreate(Owner, tbParams)
    self.nTransformId = tbParams.nTransformId
    if self.nTransformId and self.nTransformId > 0 then
        local AIDestructibleObjectManager = CommonShell.GetCommon(GWorld):GetAIDestructibleObjectManager()
        AIDestructibleObjectManager:SetDoorInstanceId(self.nTransformId, Owner.nServerInstanceId)
        LOG("set door instanceid ", self.nTransformId, Owner.nServerInstanceId)
    else
        logerror("destructible object wthout transform id ", self.nTemplateId)
    end
    return self.super.OnCreate(self, Owner, tbParams)
end

function DestructibleObjectAIComponent:OnActorCreated(pUEActor)

    return self.super.OnActorCreated(self,pUEActor)
end

return DestructibleObjectAIComponent