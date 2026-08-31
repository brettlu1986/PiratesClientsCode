local luaclass = require("luaclass")
local GameDummyClass = require("GameDummy")
local GameDummy_C = luaclass("GameDummy_C", GameDummyClass)

function GameDummy_C:OnDelayDestroy()
    if self.pUEActor ~= nil then
	    self.pUEActor:SetActorHiddenInGame(true)
    end
end 

function GameDummy_C:OnRestoreObject(tbParam)
    if self.pUEActor ~= nil then
    	self.pUEActor:SetActorHiddenInGame(false)
    end
end 

return GameDummy_C
