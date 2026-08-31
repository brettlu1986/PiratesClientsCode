-- 这玩意只是为了server replicated 属性用的，客户端不用

local luaclass = require("luaclass")
local ReplicatedPropertyContainer = luaclass("ReplicatedPropertyContainer")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local ReplicationBinder = require("ReplicationBinder")
local ReplicateHelper = require("ReplicateHelper")

ReplicatedPropertyContainer.pActor = nil
ReplicatedPropertyContainer.tbProperties = nil
ReplicatedPropertyContainer.pActorShell = nil

ReplicatedPropertyContainer.Helper = nil
ReplicatedPropertyContainer.tbBindInfo = nil
ReplicatedPropertyContainer.Owner = nil
ReplicatedPropertyContainer.bEnableCustomReplicate = nil

function ReplicatedPropertyContainer:Init(pActor, bEnableCustomReplicate, tbOwner)
    self.pActor = pActor
    self.Owner  = tbOwner
    self.tbProperties = {}

    self.bEnableCustomReplicate = bEnableCustomReplicate

    if(GlobalVariableSystem:IsServerLogic()) then
        self.pActorShell = CommonShell.GetCommon(GWorld):GetCommonActorShell()
    end
    
    if bEnableCustomReplicate then
        self.Helper = ReplicateHelper()
        self.tbBindInfo = ReplicationBinder.Bind(self.Helper, pActor, self, ReplicationBinder.TYPE_GAMESTATE)
    end
end

function ReplicatedPropertyContainer:Uninit()
    if(self.pActorShell and self.pActor) then
        self.pActorShell:UndefineAllReplicatedProperties(self.pActor)
    end

    if self.pActor and self.bEnableCustomReplicate then
        ReplicationBinder.Unbind(self.tbBindInfo, self.pActor)
    end

    self.pActorShell = nil
    self.pActor = nil
    self.Owner  = nil
    self.tbProperties = nil
end

function ReplicatedPropertyContainer:DefineProtoProperty(szProtoName)
    local tbRet = nil
    if(self.tbProperties[szProtoName] == nil) then
        tbRet = {}
        tbRet.szProtoName = szProtoName

        if(GlobalVariableSystem:IsServerLogic()) then
            tbRet.Rep = function(bRepNow)
                self:MarkPropertyReplicate(tbRet)
                if(bRepNow) then
                    self:ReplicateNow()
                end
            end
            tbRet.RepNow = function()
                self:MarkPropertyReplicate(tbRet)
                self:ReplicateNow()
            end
            tbRet.RepNowToClient = function()
                self:ReplicateNow()
                self:MarkPropertyReplicate(tbRet)
                self:ReplicateNowByType(false)
            end
            tbRet.RepNowMulticast = function()
                self:ReplicateNow()
                self:MarkPropertyReplicate(tbRet)
                self:ReplicateNowByType(true)
            end
        end
        self.tbProperties[szProtoName] = tbRet
    else
        logerror("ReplicatedPropertyContainer:DefineProtoProperty failed, duplicated.", szProtoName)
        return nil
    end

    if(self.pActorShell) then
        self.pActorShell:DefineReplicatedProperty(self.pActor, szProtoName)
    end
    return tbRet
end

function ReplicatedPropertyContainer:UndefineProtoProperty(szProtoName)
    if(self.tbProperties[szProtoName]) then
        self.tbProperties[szProtoName] = nil

        if(self.pActorShell) then
            return self.pActorShell:UndefineReplicatedProperty(self.pActor, szProtoName)
        end
        return true
    end
    return false
end

function ReplicatedPropertyContainer:MarkPropertyReplicate(tbProperty)
    local szName = tbProperty.szProtoName
    if(szName == nil) then
        logerror("BattleGameStateBase:MarkPropertyReplicate failed, the input property is not proto")
        return false
    end
    if(self.tbProperties[szName] == nil) then
        logerror("BattleGameStateBase:MarkPropertyReplicate failed, the input property can not be found", szName)
        return false
    end
    if(self.pActorShell and self:CanRep(tbProperty)) then
        --log("ReplicatedPropertyContainer:MarkPropertyReplicate", szName)
        return self.pActorShell:SetReplicatedPropertyValue(self.pActor, szName, exposetable(tbProperty))
    end
    return true
end

function ReplicatedPropertyContainer:ReplicateNow()
    if(self.pActorShell) then
        self.pActorShell:ReplicateActorPropertyNow(self.pActor)
    end    
end

function ReplicatedPropertyContainer:ReplicateAll(bRepNow)
    self:ReplicateAllToActor(self.pActor, bRepNow)
end

function ReplicatedPropertyContainer:ReplicateNowByType(bMulticast)
    if(self.pActorShell) then
        self.pActorShell:ReplicateActorPropertyNowByType(self.pActor, bMulticast)
    end 
end

function ReplicatedPropertyContainer:CanRep(tbProperty)
    local nKeyCount = 0
    local nKeyMinCount = 3    -- 包括szProtoName, Rep, RepNow,除了这仨外有别的才算有效
    for _key, _value in pairs(tbProperty) do
        nKeyCount = nKeyCount + 1
        if(nKeyCount > nKeyMinCount) then
            return true
        end
    end
    return false
end

function ReplicatedPropertyContainer:ReplicateAllToActor(pActor, bRepNow)    
    local pActorShell = self.pActorShell
    if(pActorShell == nil or pActor == nil) then
        return        
    end
    
    log("ReplicatedPropertyContainer:ReplicateAllToActor")
    local tbProperties = self.tbProperties
    for szName, tbProperty in pairs(tbProperties) do        
        if(self:CanRep(tbProperty)) then
            pActorShell:SetReplicatedPropertyValue(pActor, szName, exposetable(tbProperty))
        end
    end
    if(bRepNow) then
        pActorShell:ReplicateActorPropertyNow(pActor)
    end
end

function ReplicatedPropertyContainer:BindMethod(nNameIndex, DefaultValue, tbObject, fnOnChanged, bNotifyOnServer)
    return self.Helper:Bind(nNameIndex, DefaultValue, tbObject, fnOnChanged, bNotifyOnServer)
end

return ReplicatedPropertyContainer
