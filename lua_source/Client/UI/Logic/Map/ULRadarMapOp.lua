-----------------------------------------------------
--File Name    : ULMapOp.lua
--Author       : Ran Jie
--Create Time  : 2019-9-9
--Description  : ULMapOp
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULMapOp = luaclass("ULMapOp", UILogicBase)
--import
local UIMapOperationGroupDataTable = require("UIMapOperationGroupDataTable")
local ClientEventDef = require("ClientEventDef")

ULMapOp.tbOperationIns = nil
ULMapOp.nGroupId = nil
---------------------------------------------------
local function RegisterOperation(self, szOperationName)
    log("RegisterOperation,szOperationName",szOperationName,self.Owner)
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

local function OnControlModeActivate(self, nActivateMode)
    if self.nGroupId then
        self:UnregisterAllOperations()
        self:RegisterGroupOperations(self.nGroupId)
    end
end

local function OnMapScopeChange(self, nFFAMode, nScope)
    if math.abs(self.Owner.nCurrentScope - nScope) >= 1 then
        self.Owner:RefreshMap(nScope)
    end
end

function ULMapOp:RegisterGroupOperations(nGroupId)
    if not self.tbOperationIns then
        self.tbOperationIns = {}
    end
    local tbTemplate = UIMapOperationGroupDataTable:GetTemplate(nGroupId)
    if tbTemplate and tbTemplate.tbOpScript then
        for k, v in ipairs(tbTemplate.tbOpScript) do
            RegisterOperation(self, v)
        end
    else
        error("ULMapOp:RegisterOperations,tbTemplate or tbOpScript is nil, nGroupId=",nGroupId)
    end
end

function ULMapOp:RegisterOperation(szOperationName)
    local OpInstance = self:GetOperation(szOperationName)
    if OpInstance then
        logwarning("operatiion is registered, szOperationName=", szOperationName)
        return OpInstance
    end
    return RegisterOperation(self,szOperationName)
end

function ULMapOp:UnregisterAllOperations()
    if(self.tbOperationIns ~= nil)then
        for k, v in pairs(self.tbOperationIns) do
            v:Uninit()
        end
        self.tbOperationIns = {}
        if self.Owner then
            self.Owner.pWidgetRef:UnregisterAllOperation()
        end
    end
end

function ULMapOp:UnregisterOperation(szOperationName)
    local ContentInstance = self.tbOperationIns[szOperationName]
    if(ContentInstance)then
        ContentInstance:Uninit()
    end
    self.tbOperationIns[szOperationName] = nil
end

function ULMapOp:GetOperation(szOperationName)
    if not self.tbOperationIns then
        self.tbOperationIns = {}
    end
    return self.tbOperationIns[szOperationName]
end

function ULMapOp:Reinit()
    if not self.tbOperationIns then
        return
    end
    for k, v in pairs(self.tbOperationIns) do
        v:Reinit()
    end
end

function ULMapOp:Refresh()
    if not self.tbOperationIns then
        return
    end
    for k, v in pairs(self.tbOperationIn) do
        v:Refresh()
    end
end

function ULMapOp:CloseRegisterOperations()
    if not self.tbOperationIns then
        return
    end
    for k, v in pairs(self.tbOperationIns) do
        v:Close()
    end
end

function ULMapOp:OpenRegisterOperations()
    if not self.tbOperationIns then
        return
    end
    for k, v in pairs(self.tbOperationIns) do
        v:Open()
    end
end

--------------------------------------------------------------
--override
function ULMapOp:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_CONTROL_MODE_ACTIVATE, self, OnControlModeActivate)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_MAP_SCOPE_CHANGE, self, OnMapScopeChange)
end

function ULMapOp:OnRegisterOperations(nGroupId, szOperationName)
    log("ULMapOp:OnRegisterOperations,nGroupId, szOperationName=",nGroupId, szOperationName)
    self.nGroupId = nGroupId
    self:UnregisterAllOperations()
    if nGroupId and nGroupId ~= -1 then
        self:RegisterGroupOperations(nGroupId)
    end
    if szOperationName and szOperationName ~= "" then
        self:RegisterOperation(szOperationName)
    end
end

function ULMapOp:OnClickMapWorldPos(nWorldPosX, nWorldPosY)
end


return ULMapOp
