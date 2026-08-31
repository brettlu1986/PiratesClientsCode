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

ULMapOp.tbOperationIns = nil
ULMapOp.nGroupId = nil
---------------------------------------------------
local function RegisterOperation(self, szOperationName)
    log("RegisterOperation,szOperationName",szOperationName)
    --assert(self.tbOperationIns[szOperationName] == nil)
    if not self.tbOperationIns then
        self.tbOperationIns = {}
    end
    local OperationInstance = self.tbOperationIns[szOperationName]
    if OperationInstance then
        if OperationInstance.bOpen then
            OperationInstance:Reinit()
        else
            OperationInstance:Open()
        end
    else
        local ContentClass = require(szOperationName)
        OperationInstance = ContentClass()
        OperationInstance:Init(self.Owner)
        OperationInstance:BindEvent()
        self.tbOperationIns[szOperationName] = OperationInstance
    end
    return OperationInstance
end

function ULMapOp:RegisterGroupOperations(nGroupId)
    -- if not self.tbOperationIns then
    --     self.tbOperationIns = {}
    -- end
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
    if not self.tbOperationIns then
        return
    end
    local ContentInstance = self.tbOperationIns[szOperationName]
    if(ContentInstance)then
        if ContentInstance.MapOpObj then
            self.Owner.pWidgetRef:UnregisterOperation(ContentInstance.MapOpObj)
        end
        ContentInstance:Uninit()
    end
    self.tbOperationIns[szOperationName] = nil
end

function ULMapOp:GetOperation(szOperationName)
    if self.tbOperationIns then
        return self.tbOperationIns[szOperationName]
    end
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
