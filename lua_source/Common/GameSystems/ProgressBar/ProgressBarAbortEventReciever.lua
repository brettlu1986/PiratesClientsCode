local luaclass = require("luaclass")
local AbortEventReciever = dynamic_require("AbortEventReciever")
local ProgressBarAbortEventReciever = luaclass("ProgressBarAbortEventReciever", AbortEventReciever)
local AbortConditionTable = require("ProgressBarAbortTable")
local AbortType = require("AbortTypeDefine")
local HumanMovementStateType = require("HumanMovementStateType")

local tbHumanAbortKeyToType = {
    ["bHumanDisplacement"] = AbortType.HUMAN_DISPLACEMENT,
    ["bHumanInjured"] = AbortType.HUMAN_INJURED,
    ["bHumanMove"] = AbortType.HUMAN_MOVE,
    ["bHumanWeaponStateChange"] = AbortType.HUMAN_WEAPON_STATE_CHANGE,
    ["bHumanWeaponSlotChange"] = AbortType.HUMAN_WEAPON_SLOT_CHANGE,
    ["bHumanFire"] = AbortType.HUMAN_FIRE,
    ["bHumanPickUp"] = AbortType.HUMAN_PICK_UP,
    ["bHumanJump"] = AbortType.HUMAN_JUMP,
    ["bHumanCrouch"] = AbortType.HUMAN_CROUCH,
    ["bHumanCrawl"] = AbortType.HUMAN_CRAWL,
    ["bHumanSwim"] = AbortType.HUMAN_SWIM,
    ["bSeriousInjury"] = AbortType.SERIOUS_INJURY,
    ["bHumanDead"] = AbortType.PLAYER_DEAD,
    ["bHumanBurn"] = AbortType.PLAYER_BURN,
    ["bHumanDying"] = AbortType.PLAYER_DYING,
    ["bHumanSwitchDoor"] = AbortType.DOOR_SWITCHED
}

local tbShipAbortKeyToType = {
    ["bShipInjured"] = AbortType.SHIP_INJURED,
    ["bShipMove"] = AbortType.SHIP_MOVE,
    ["bShipPostureChange"] = AbortType.SHIP_POSTURE_CHANGE,
    ["bShipRotate"] = AbortType.SHIP_ROTATE,
    ["bShipWeaponSwitch"] = AbortType.SHIP_WEAPON_SWITCH,
    ["bShipFire"] = AbortType.SHIP_FIRE,
    ["bShipPickUp"] = AbortType.SHIP_PICK_UP,
    ["bShipAim"] = AbortType.SHIP_AIM,
    ["bShipBulletLoad"] = AbortType.SHIP_BULLET_LOAD,
    ["bShipDead"] = AbortType.PLAYER_DEAD,
    ["bShipBurn"] = AbortType.PLAYER_BURN,
    ["bShipDying"] = AbortType.PLAYER_DYING,
}


local tbIgnoreMovementStateType = {
    [HumanMovementStateType.UpRight_State] = 1,
    [HumanMovementStateType.Crouch_State] = 10,
    [HumanMovementStateType.Crawl_State] = 100,
    [HumanMovementStateType.Swimming] = 1000
}

function ProgressBarAbortEventReciever:Init(Object, tbProgressBarTable, bHumanCrawlToCrouch, bIngoreMove)
    self.bHumanCrawlToCrouch = bHumanCrawlToCrouch
    local nAbortId
    local tbAbortTypes = {}
    local tbAbortKeyToType = {}
    if Object.Owner:IsShip() then
        nAbortId = tbProgressBarTable.nShipAbortId
        tbAbortKeyToType = tbShipAbortKeyToType

        if bIngoreMove then  
            tbAbortKeyToType.bShipMove = nil 
            tbAbortKeyToType.bShipRotate = nil 
        else
            tbAbortKeyToType.bShipMove = AbortType.SHIP_MOVE 
            tbAbortKeyToType.bShipRotate = AbortType.SHIP_ROTATE 
        end 
    else
        nAbortId = tbProgressBarTable.nHumanAbortId
        tbAbortKeyToType = tbHumanAbortKeyToType
        if bIngoreMove then  
            tbAbortKeyToType.bHumanMove = nil 
            tbAbortKeyToType.bHumanDisplacement = nil 
        else 
            tbAbortKeyToType.bHumanMove = AbortType.HUMAN_MOVE 
            tbAbortKeyToType.bHumanDisplacement = AbortType.HUMAN_DISPLACEMENT 
            self.nAbortByMovementType = tbProgressBarTable.nAbortByMovementType
        end 
    end

    local tbAbortCondition = AbortConditionTable:GetTemplate(nAbortId)
    if tbAbortCondition then
        for szKey, nAbortType in pairs(tbAbortKeyToType) do
            if tbAbortCondition[szKey] then
                table.insert(tbAbortTypes, nAbortType)
            end
        end
    else
        logerror("AbortConditionTable:GetTemplate Error. nAbortId:", nAbortId)
    end

    if tbAbortCondition.bHumanSwim ~= nil then
        self.bHumanSwim = tbAbortCondition.bHumanSwim
    else
        self.bHumanSwim = true
    end

    local OnAbort = function()
        if Object.Abort then
            Object:Abort()
        end
    end

    ProgressBarAbortEventReciever.super.Init(self, Object, tbAbortTypes, OnAbort)
end

function ProgressBarAbortEventReciever:CheckNeedAbortByMove(nAbortByMovementType, nMovementState)
    if nAbortByMovementType == 0 then
        return false
    end
    if nMovementState == HumanMovementStateType.Vehicle then
        nMovementState = HumanMovementStateType.UpRight_State
    end
    local nIgnoreMod = tbIgnoreMovementStateType[nMovementState]
    if not nIgnoreMod then
        return false
    end
    nAbortByMovementType = nAbortByMovementType % (nIgnoreMod * 10) / nIgnoreMod
    return nAbortByMovementType >= 1
end

return ProgressBarAbortEventReciever