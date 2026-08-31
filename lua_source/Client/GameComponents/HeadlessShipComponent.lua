local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase") 
local HeadlessShipComponent = luaclass("HeadlessShipComponent", GameComponentBaseClass)
local StringUtil = require("StringUtil")

function HeadlessShipComponent:OnCreate(...)
    HeadlessShipComponent.super.OnCreate(self, ...)
    local szCmdLineStr = KismetSystemLibrary.GetCommandLine()
    local tbCmdArgs = StringUtil.Split(szCmdLineStr, ' ')
    for i=1,#tbCmdArgs do
        if tbCmdArgs[i] == "-simulatemoving" then
            log("Client simulates moving...")
            local tbGamePlayerSelf = self:GetOwner()
            local pUEActor = tbGamePlayerSelf.pUEActor
            if pUEActor == nil then
                logwarning("Client simulates moving failed. pUEActor nil.")
                break
            end
            local pClientSimulatorComponent = pUEActor.ClientSimulatorComponent
            if pClientSimulatorComponent == nil then
                logwarning("Client simulates moving failed. pUEActor.ClientSimulatorComponent nil.")
                break
            end
            if pClientSimulatorComponent.EnableSimulating == nil then
                logwarning("Client simulates moving failed. pUEActor.ClientSimulatorComponent.EnableSimulating nil.")
                break
            end
            pClientSimulatorComponent:EnableSimulating(true)
            break
        end
    end
end

return HeadlessShipComponent
