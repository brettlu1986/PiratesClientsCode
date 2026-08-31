local SAISystemRegister = {}

local SAISystemDef = require("SAISystemDef")

local function Define(AIComponent, nID, szSystem)
    AIComponent:AddSubSystem(nID, szSystem)
end


function SAISystemRegister:RegisterSystem(AIComponent)
    Define(AIComponent, SAISystemDef.Perception ,"SAIPerceptionSystem")
    Define(AIComponent, SAISystemDef.Threat ,"SAIThreatSystem")
    Define(AIComponent, SAISystemDef.Goal ,"SAIGoalSystem")
    Define(AIComponent, SAISystemDef.Action ,"SAIActionSystem")
    Define(AIComponent, SAISystemDef.Weapon ,"SAIWeaponSystem")
    Define(AIComponent, SAISystemDef.Escape ,"SAIEscapePoisonSystem")
    Define(AIComponent, SAISystemDef.Build ,"SAIBuildItemSystem")
    Define(AIComponent, SAISystemDef.SeekTarget ,"SAISeekTargetSystem")
    Define(AIComponent, SAISystemDef.Parachute ,"SAIParachuteSystem")
    Define(AIComponent, SAISystemDef.Patrol ,"SAIPatrolSystem")
    Define(AIComponent, SAISystemDef.DoorDetect ,"SAIDoorDetectSystem")
end


return SAISystemRegister