-- NPC角色

local luaclass = require("luaclass")
local GamePlayerClass = dynamic_require("GamePlayer")
local GamePlayerOther = luaclass("GamePlayerOther", GamePlayerClass)
local GameCharacter = dynamic_require("GameCharacter")

function GamePlayerOther.StaticCollectResources(tbCreateData, tbCustomData)
    local nTemplateId = tbCreateData.nTemplateId  
    return GameCharacter.StaticGetActorClass(tbCreateData.nTemplateType, nTemplateId)
end

return GamePlayerOther
