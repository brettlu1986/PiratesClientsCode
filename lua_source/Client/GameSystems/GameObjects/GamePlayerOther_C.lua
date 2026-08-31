-- NPC角色

local luaclass = require("luaclass")
local GamePlayerOtherClass = require("GamePlayerOther")
local GamePlayerOther_C = luaclass("GamePlayerOther_C", GamePlayerOtherClass)
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")

function GamePlayerOther_C:OnActorCreated(pUEActor)
    GamePlayerOther_C.super.OnActorCreated(self, pUEActor)

    if not GlobalVariableSystem_C.bShowPlayer or not GlobalVariableSystem_C.bShowCharacter then 
        pUEActor:SetActorHiddenInGame(true)
        if self.HeadInfoComponent then 
            self.HeadInfoComponent:SetVisibility(false)
        end         
    end 
end 

return GamePlayerOther_C
