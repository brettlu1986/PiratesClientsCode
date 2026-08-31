-----------------------------------------------------
--File Name    : UPRadarMapOperationRegister.lua
--Author       : Ran Jie
--Create Time  : 2017-8-9
--Description  : UPRadarMapOperationRegister
-----------------------------------------------------

local UPRadarMapOperationRegister = {}

--import
local GlobalVariableSystem = require("GlobalVariableSystem_C")
-- local EventManager = require("EventManager")
-- local ClientEventDef = require("ClientEventDef")

UPRadarMapOperationRegister.Owner = nil
UPRadarMapOperationRegister.tbOperationIns = nil
---------------------------------------------------
local function RegisterOperation(self,szOperationName)
    assert(self.tbOperationIns[szOperationName] == nil)
    local ContentClass = require(szOperationName)
    local OperationInstance = self.tbOperationIns[szOperationName]
    if(OperationInstance == nil)then
        OperationInstance = ContentClass()
    end
    OperationInstance:Init(self.Owner)
    OperationInstance:BindEvent()
    self.tbOperationIns[szOperationName] = OperationInstance
    return OperationInstance
end

-- local function OnFFAControlModeActive(self)
--     if not self.tbOperationIns then
--         return
--     end
--     for k, v in pairs(self.tbOperationIns) do
--         v:Reinit()
--     end
-- end

function UPRadarMapOperationRegister:RegisterOperations(Owner)
    self.Owner = Owner
    if not self.tbOperationIns then
        self.tbOperationIns = {}
    end
    local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
    if(bIsInDungeon)then
        RegisterOperation(self, "MapOpMapMove")
        --RegisterOperation(self, "MapOpNpcForDungeon")
        --RegisterOperation(self, "MapOpShipShotRange")
        RegisterOperation(self, "MapOpViewFov")
        --RegisterOperation(self, "MapOpOrientation")
        --RegisterOperation(self, "MapOpCoordinate")
        --RegisterOperation(self, "MapOpFFACoreArea")
        --RegisterOperation(self, "MapOpForSpecialGO")
        RegisterOperation(self, "MapOpFFAPoisonCircle")
        RegisterOperation(self, "MapOpFFAFlagLine")
        RegisterOperation(self, "MapOpFFASound")
        RegisterOperation(self, "MapOpFFAStaticPoint")
        RegisterOperation(self, "MapOpFFASafeCirclePath")
        RegisterOperation(self, "MapOpFFATeamMember")
        RegisterOperation(self, "MapOpForAirDrop")
        RegisterOperation(self, "MapOpForDiamond")
        --RegisterOperation(self, "MapOpForSelfBornPoint")
        RegisterOperation(self, "MapOpQuest")
        
    else
        RegisterOperation(self, "MapOpMapMove")
        RegisterOperation(self, "MapOpViewFov")
        RegisterOperation(self, "MapOpStaticPoint")
        -- RegisterOperation(self, "MapOpPlayerForHub")
        -- RegisterOperation(self, "MapOpNpcForServerDynamic")
        -- RegisterOperation(self, "MapOpStatic")
        -- RegisterOperation(self, "MapOpStaticTransferPoint")
        -- RegisterOperation(self, "MapOpNav")
        -- RegisterOperation(self, "MapOpCoordinate")
    end
    --EventManager:BindEventMethod(ClientEventDef.EV_FFA_CONTROL_MODE_ACTIVATE, self, OnFFAControlModeActive)
end

function UPRadarMapOperationRegister:UnregisterOperation(szOperationName)
    local ContentInstance = self.tbOperationIns[szOperationName]
    if(ContentInstance)then
        if ContentInstance.MapOpObj then
            self.Owner.pWidgetRef:UnregisterOperation(ContentInstance.MapOpObj)
        end
        ContentInstance:Uninit()
    end
    self.tbOperationIns[szOperationName] = nil
end

function UPRadarMapOperationRegister:UnregisterOperations()
    if(self.tbOperationIns ~= nil)then
        for k, v in pairs(self.tbOperationIns) do
            v:Uninit()
        end
        self.tbOperationIns = {}
        if self.Owner then
            self.Owner.pWidgetRef:UnregisterAllOperation()
            self.Owner = nil
        end
    end
    --EventManager:UnBindEventMethod(ClientEventDef.EV_FFA_CONTROL_MODE_ACTIVATE, self, OnFFAControlModeActive)
end

function UPRadarMapOperationRegister:ReregisterOperations(Owner)
    if(self.tbOperationIns ~= nil)then
        local tbRegister = {}
        for k, v in pairs(self.tbOperationIns) do
            table.insert(tbRegister, k)
            self:UnregisterOperation(k)
        end
        self.tbOperationIns = {}
        if self.Owner then
            self.Owner.pWidgetRef:UnregisterAllOperation()
            self.Owner = nil
        end

        self.Owner = Owner
        for i, v in pairs(tbRegister) do
            RegisterOperation(self, v)
        end
    end
end

function UPRadarMapOperationRegister:RegisterOperation(Owner, szOperationName)
    self.Owner = Owner
    if not self.tbOperationIns then
        self.tbOperationIns = {}
    end
    return RegisterOperation(self,szOperationName)
end

function UPRadarMapOperationRegister:GetOperation(szOperationName)
    if not self.tbOperationIns then
        self.tbOperationIns = {}
    end
    return self.tbOperationIns[szOperationName]
end

function UPRadarMapOperationRegister:Reinit()
    local tbOperationIns = self.tbOperationIns
    if(tbOperationIns ~= nil)then
        for k, v in pairs(tbOperationIns) do
            v:Reinit()
        end
    end
end

function UPRadarMapOperationRegister:Refresh()
    local tbOperationIns = self.tbOperationIns
    if(tbOperationIns ~= nil)then
        for k, v in pairs(tbOperationIns) do
            v:Refresh()
        end
    end
end

return UPRadarMapOperationRegister
