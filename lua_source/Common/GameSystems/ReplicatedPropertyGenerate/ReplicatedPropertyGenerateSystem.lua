local ReplicatedPropertyGenerateSystem = {}

local PropName = require("PropName")
local NetworkManager = dynamic_require("NetworkManager")

local PropertyType  = PropName.PropertyType
local PTYPE_TO_DTYPE = {
    [PropertyType.Bool]     = ECustomReplicatedPropertyType.Bool,
    [PropertyType.Int]      = ECustomReplicatedPropertyType.Int,
    [PropertyType.Float]    = ECustomReplicatedPropertyType.Float,
    --[PropertyType.String]   = ECustomReplicatedPropertyType.String,
    [PropertyType.Proto]    = ECustomReplicatedPropertyType.Proto,
}

local function GetDefineInfo(tbRepId)
    local tbAllDefine = {}
    local tbName, tbType, tbRepType = PropName.GetAllIdInfo()
    local pDefine, szName, nType, nRepType, nDType

    for _, nId in ipairs(tbRepId) do
        szName = tbName[nId]
        nType = tbType[nId]
        nRepType = tbRepType[nId]
        --bArray = tbArray[nId]

        if(szName and nType and nRepType) then
            nDType = PTYPE_TO_DTYPE[nType]
            assert(nDType)

            pDefine = CustomReplicationPropertyDefine()
            pDefine.PropertyName = szName
            pDefine.PropertyType = nDType
            pDefine.RepType = nRepType
            pDefine.PropertyId = nId
            --pDefine.IsArray = bArray or false
            table.insert(tbAllDefine, pDefine)
        end
    end
    return tbAllDefine
end

function ReplicatedPropertyGenerateSystem:Init()
    local pNetworkManager = NetworkManager:GetRPCNetworkProxy().pNetworkManager
    pNetworkManager:ClearCustomReplicationDefineInfo()

    local tbRepPropFiles = PropName.GetAllRepPropFiles()
    for _, szFileName in ipairs(tbRepPropFiles) do
        pNetworkManager:AddCustomReplicationDefineInfo(szFileName,
            GetDefineInfo(require(szFileName).GetRepIds()))
    end
end

function ReplicatedPropertyGenerateSystem:Uninit()
    NetworkManager:GetRPCNetworkProxy().pNetworkManager:ClearCustomReplicationDefineInfo()
end

local function GetCRCs()
    local tbRet = {}
    local pNetworkManager = NetworkManager:GetRPCNetworkProxy().pNetworkManager
    local tbRepPropFiles = PropName.GetAllRepPropFiles()
    for _, szFileName in ipairs(tbRepPropFiles) do
        table.insert(tbRet, pNetworkManager:GetCustomReplicationDefineInfoCRC(szFileName))
    end
    return tbRet
end

function ReplicatedPropertyGenerateSystem:SetReplicationCRC(pController)
    if(pController.SetRepPropertyCRCs ~= nil) then
        pController:SetRepPropertyCRCs(GetCRCs())
    end
end

function ReplicatedPropertyGenerateSystem:CheckReplicationCRC(tbRemoteCRCs)
    local tbLocalCRCs = GetCRCs()
    if(#tbLocalCRCs ~= #tbRemoteCRCs) then
        return false
    end

    for i=1, #tbLocalCRCs do
        if(tbLocalCRCs[i] ~= tbRemoteCRCs[i]) then
            return false
        end
    end

    return true
end

return ReplicatedPropertyGenerateSystem