local SettingKeyDef       = require("SettingKeyDef")
local SettingValueDef     = require("SettingValueDef")
local SettingClassType    = require("SettingClassType")
local NetworkManager      = dynamic_require("NetworkManager")
local Proto               = require("ClientProtoNames")
local SelfEventHelperClass= require("SelfEventHelper")
local ClientEventDef      = require("ClientEventDef")

-- local tbLocal  = SettingKeyDef.tbLocal
-- local tbRemote = SettingKeyDef.tbRemote
local DefaultValues = SettingValueDef.DefaultValues

local SETTING_TAG = "SETTING_"

local SettingSystemNew = {}
SettingSystemNew.tbInstances = nil
SettingSystemNew.tbRemoteData = nil
SettingSystemNew.tbDatas     = nil

local function ConvertIntKeyToStr(nKey)
    return string.format("%s%d", SETTING_TAG, nKey)
end

local function Register(self, nType, szFileName)
    local Class = require(szFileName)
    local Instance = Class()
    Instance:Init(self)
    self.tbInstances[nType] = Instance
end

local function Unregister(self, nType)
    local Instance = self.tbInstances[nType]
    if Instance ~= nil then
        Instance:Uninit()
        self.tbInstances[nType] = nil
    end
end

local function RegisterAll(self)
    local T = SettingClassType
    Register(self, T.Setting_Frame, "SettingFrame")
	Register(self, T.Setting_Sound, "SettingSound")
	Register(self, T.Setting_Layout,"SettingLayout")
    Register(self, T.Setting_Chat,  "SettingChat")
    Register(self, T.Setting_Basic, "SettingBasic")
    Register(self, T.Setting_PickUp,"SettingPickUp")
    Register(self, T.Setting_Camera,"SettingCamera")
    Register(self, T.Setting_OperationMode, "SettingOperationMode")
end

local function UnregisterAll(self)
    for k, v in pairs(self.tbInstances) do
        Unregister(self, k)
    end
end

local function LoadLocalSetting(self)
    for k, v in pairs(self.tbInstances) do
        v:LoadLocalSetting()
    end
end

local function OnPlayerDataSync(self, tbPacket)
    self.tbRemoteData = {}


    local tbSettings = tbPacket.data.settings
    if tbSettings then
        for i, v in ipairs(tbSettings) do
            self.tbRemoteData[v.key] = v.value
        end
    end

    for k, v in pairs(self.tbInstances) do
        v:LoadRemoteSetting()
    end
end

local function OnNewPlayer(self)
    for k, v in pairs(self.tbInstances) do
        v:ClearSaveData()
    end
end

local function IsRemoteKey(nKey)
    return nKey >= SettingKeyDef.RemoveKeyStart and nKey <= SettingKeyDef.RemoveKeyEnd
end

local function IsLocalKey(nKey)
    return nKey >= SettingKeyDef.LocalKeyStart and nKey <= SettingKeyDef.LocalKeyEnd
end

function SettingSystemNew:Init()
    self.tbDatas = {}
    self.tbInstances = {}
    RegisterAll(self)

    self.EventHelper = SelfEventHelperClass()
    self.EventHelper:RegisterEvent(ClientEventDef.EV_NEW_PLAYER, self, OnNewPlayer)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERDATA_SYNC, self, OnPlayerDataSync)

    LoadLocalSetting(self)
    return true
end

function SettingSystemNew:Uninit()
    if self.EventHelper ~= nil then
        self.EventHelper:UnregisterAll()
        self.EventHelper = nil
    end

    UnregisterAll(self)
    self.tbInstances = nil
    self.tbDatas = nil
end

function SettingSystemNew:UnRegister(nType)
end

function SettingSystemNew:GetInstance(nType)
    return self.tbInstances and self.tbInstances[nType]
end

function SettingSystemNew:SetUseDefaultSaveId(bValue)
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    pSaveGameMgr:SetUseDefaultUserId(bValue)
end

function SettingSystemNew:Get(nKey, nDefaultValue)
    if IsRemoteKey(nKey) then
        return self.tbRemoteData and self.tbRemoteData[nKey] or -1
    elseif IsLocalKey(nKey) then
        local nSaveValue = self.tbDatas[nKey]
        if not nSaveValue then
            nDefaultValue = nDefaultValue or DefaultValues[nKey]
            nDefaultValue = nDefaultValue or -1
            local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()

            local bOld = pSaveGameMgr.IsUseDefaultUserId
            if not bOld then 
                self:SetUseDefaultSaveId(true)
            end
            local nValue = pSaveGameMgr:GetIntDataWithDefault(ConvertIntKeyToStr(nKey), nDefaultValue)
            if not bOld then
                self:SetUseDefaultSaveId(false)
            end
            self.tbDatas[nKey] = nValue
            return nValue
        else
            return nSaveValue
        end
    else
        logerror("SettingSystemNew:Get key is invalid ", nKey)
    end
end

function SettingSystemNew:Set(nKey, nValue)
    if IsRemoteKey(nKey) then
        if self.tbRemoteData then
            self.tbRemoteData[nKey] = nValue
        end
        return nValue
    elseif IsLocalKey(nKey) then
        local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()

        local bOld = pSaveGameMgr.IsUseDefaultUserId
        if not bOld then
            self:SetUseDefaultSaveId(true)
        end
        -- pSaveGameMgr:AddIntData(ConvertIntKeyToStr(nKey), nValue)
        self.tbDatas[nKey] = nValue
        if not bOld then
            self:SetUseDefaultSaveId(false)
        end

        return nValue
    else
        logerror("SettingSystemNew:Set key is invalid ", nKey)
    end
end

function SettingSystemNew:SetDefaultValue(nKey)
    if IsRemoteKey(nKey) then
        local nDefaultValue = DefaultValues[nKey]
        if self.tbRemoteData then
            self.tbRemoteData[nKey] = nDefaultValue
        end
        return nDefaultValue
    elseif IsLocalKey(nKey) then
        local nDefaultValue = DefaultValues[nKey]
        if nDefaultValue then
            local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
            local bOld = pSaveGameMgr.IsUseDefaultUserId
            if not bOld then
                self:SetUseDefaultSaveId(true)
            end
            pSaveGameMgr:AddIntData(ConvertIntKeyToStr(nKey), nDefaultValue)
            if not bOld then
                self:SetUseDefaultSaveId(false)
            end

            return nDefaultValue
        end
    else
        logerror("SettingSystemNew:SetDefaultValue key is invalid ", nKey)
    end
end

function SettingSystemNew:SaveLocalData()
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    local bOld = pSaveGameMgr.IsUseDefaultUserId
    if not bOld then
        self:SetUseDefaultSaveId(true)
    end
    if self.tbDatas ~= nil then
        for k, v in pairs(self.tbDatas) do
            pSaveGameMgr:AddIntData(ConvertIntKeyToStr(k), v)
        end
    end
    pSaveGameMgr:Save()
    if not bOld then
        self:SetUseDefaultSaveId(false)
    end
end

function SettingSystemNew:SaveRemoveData()
    -- send to lobby
    if self.tbRemoteData == nil then
        return
    end
    local c2s_SavePlayerSettings = {settings = {} }
    for k, v in pairs(self.tbRemoteData) do
        table.insert(c2s_SavePlayerSettings.settings, {key = k, value = v})
    end

    local Socket = NetworkManager:GetHubServerProxy()
    Socket:SendPacket(Proto.c2s_SavePlayerSettings, c2s_SavePlayerSettings)
end

function SettingSystemNew:Save()
    self:SaveLocalData()
    self:SaveRemoveData()
end

return SettingSystemNew