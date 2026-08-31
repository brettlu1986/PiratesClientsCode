
local luaclass = require("luaclass")
local SAISystemBase = require("SAISystemBase")
local SAIActionSystem = luaclass("SAIActionSystem", SAISystemBase)

SAIActionSystem.pAIController = nil
SAIActionSystem.tbAction = nil

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAIActionSystem:", ...)
end
-- luacheck: pop


function SAIActionSystem:OnInit(Owner)

end


function SAIActionSystem:OnStart()
    self.pAIController = self.tbOwner.SAIComponent:GetAIController()
    if self.tbOwner:IsShip() then
        self.tbAction = require("SAIActionShip")()
        self.tbAction:Start(self.tbOwner, self.pAIController)
    elseif self.tbOwner:IsHuman() then
        self.tbAction = require("SAIActionHuman")()
        self.tbAction:Start(self.tbOwner, self.pAIController)
    end
end


function SAIActionSystem:OnStop()
    if self.tbAction then
        self.tbAction:Stop()
        self.tbAction = nil
    end
end

function SAIActionSystem:OnUninit()
    self.pAIController = nil
end



return SAIActionSystem
