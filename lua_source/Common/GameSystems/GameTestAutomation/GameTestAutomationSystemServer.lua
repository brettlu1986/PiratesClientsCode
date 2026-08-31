-----------------------------------------------------
--File Name    : GameTestAutomationSystemServer.lua
--Author       : WuJizhou
--Create Time  : 7/23/2019, 2:45:34 PM
--Description  : GameTestAutomationSystemServer
-----------------------------------------------------

local GameTestAutomationSystemServer = {}

local tbAllSubSystems = {}

local BATTLE_TEST_AUTOMATION = "BattleTestAutomationSystemServer"

local bActivate = false

local function DoRegisterSubSystem(szSystemName)
    local SubSystem = require(szSystemName)
    tbAllSubSystems[szSystemName] = SubSystem
end

local function RegisterSubSystems()
    DoRegisterSubSystem(BATTLE_TEST_AUTOMATION)
end

local function UnregisterSubSystems()
    tbAllSubSystems = {}
end

local function ActivateSubSystems()
    for _, v in pairs(tbAllSubSystems) do
        v:Activate()
    end
end

local function DeactivateSubSystems()
    for _, v in pairs(tbAllSubSystems) do
        v:Deactivate()
    end
end


local function TryToActivate()
    if not bActivate then
        RegisterSubSystems()
        ActivateSubSystems()
        bActivate = true
    end
end

local function TryToDeactivate()
    if bActivate then
        DeactivateSubSystems()
        UnregisterSubSystems()
        bActivate = false
    end
end


--------------------public api------------------------
function GameTestAutomationSystemServer:StartBattleAutoTest(nPlayerInstanceId, tbParams)
    TryToActivate()
    local tbSystem = tbAllSubSystems[BATTLE_TEST_AUTOMATION]
    if tbSystem then
        tbSystem:StartAutotest(nPlayerInstanceId, tbParams)
    end
end

function GameTestAutomationSystemServer:StopBattleAutoTest(nPlayerInstanceId)
    local tbSystem = tbAllSubSystems[BATTLE_TEST_AUTOMATION]
    if tbSystem then
        tbSystem:StopAutotest(nPlayerInstanceId)
    end
end

------------------------------------------------------

function GameTestAutomationSystemServer:Init()
    bActivate = false
end

function GameTestAutomationSystemServer:Uninit()
    TryToDeactivate()
    bActivate = false
end

return GameTestAutomationSystemServer