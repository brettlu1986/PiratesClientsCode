local luaclass = require("luaclass")
local SettingBase = require("SettingBase")
local SettingCamera = luaclass("SettingCamera", SettingBase)
local SettingKeyDef = require("SettingKeyDef")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local EventManager = require("EventManager")
local SettingGyroDataTable = require("SettingGyroDataTable")
local SettingCameraDataTable = require("SettingCameraDataTable")
local ClientEventDef = require("ClientEventDef")

local LocalKeys = SettingKeyDef.LocalKeys
local TargetType = GameCameraModeGroupDef.SettingTargetType
local nGyroKeyStart = LocalKeys.GYRO_PARACHUTING_SENSITIVITY
local SenseTargetDef = GameCameraModeGroupDef.SettingTargetType

local CAMERAS = {
    [LocalKeys.CAMERA_PARACHUTING_SENSITIVITY] = TargetType.Parachute,
    [LocalKeys.CAMERA_HUMAN_CLOSE_SENSITIVITY] = TargetType.HumanNotAim,
    [LocalKeys.CAMERA_HUMAN_OPEN_SENSITIVITY] = TargetType.HumanAim,
    [LocalKeys.CAMERA_SHIP_CLOSE_SENSITIVITY] = TargetType.ShipNotAim, 
    [LocalKeys.CAMERA_SHIP_OPEN2_SENSITIVITY] = TargetType.ShimAim2,
    [LocalKeys.CAMERA_SHIP_OPEN4_SENSITIVITY] = TargetType.ShipAim4,
    [LocalKeys.CAMERA_SHIP_OPEN8_SENSITIVITY] = TargetType.ShipAim8,
}

local GYROS = {
    [LocalKeys.GYRO_PARACHUTING_SENSITIVITY] = TargetType.Parachute,
    [LocalKeys.GYRO_HUMAN_CLOSE_SENSITIVITY] = TargetType.HumanNotAim,
    [LocalKeys.GYRO_HUMAN_OPEN_SENSITIVITY] = TargetType.HumanAim,
    [LocalKeys.GYRO_SHIP_CLOSE_SENSITIVITY] = TargetType.ShipNotAim, 
    [LocalKeys.GYRO_SHIP_OPEN2_SENSITIVITY] = TargetType.ShimAim2,
    [LocalKeys.GYRO_SHIP_OPEN4_SENSITIVITY] = TargetType.ShipAim4,
    [LocalKeys.GYRO_SHIP_OPEN8_SENSITIVITY] = TargetType.ShipAim8,
}

local function GetCameraSensePercent(nValueType, nTargetType)
    local tbValues =  SettingCameraDataTable:GetTemplate(nValueType)
    local nSenseValue = 100
    if nTargetType == SenseTargetDef.Parachute then  
        nSenseValue = tbValues.Parachute
    elseif nTargetType == SenseTargetDef.HumanNotAim then
        nSenseValue = tbValues.HumanNotAim
    elseif nTargetType == SenseTargetDef.HumanAim then
        nSenseValue = tbValues.HumanAim 
    elseif nTargetType == SenseTargetDef.ShipNotAim then
        nSenseValue = tbValues.ShipNotAim 
    elseif nTargetType == SenseTargetDef.ShimAim2 then
        nSenseValue = tbValues.ShipAim2 
    elseif nTargetType == SenseTargetDef.ShipAim4 then
        nSenseValue = tbValues.ShipAim4 
    elseif nTargetType == SenseTargetDef.ShipAim8 then
        nSenseValue = tbValues.ShipAim8 
    end
    return nSenseValue * 0.01
end

local function GetGyroSensePercent(nValueType, nTargetType)
    local tbValues =  SettingGyroDataTable:GetTemplate(nValueType)
    local nSenseValue = 100
    if nTargetType == SenseTargetDef.Parachute then  
        nSenseValue = tbValues.Parachute 
    elseif nTargetType == SenseTargetDef.HumanNotAim then
        nSenseValue = tbValues.HumanNotAim 
    elseif nTargetType == SenseTargetDef.HumanAim then
        nSenseValue = tbValues.HumanAim 
    elseif nTargetType == SenseTargetDef.ShipNotAim then
        nSenseValue = tbValues.ShipNotAim 
    elseif nTargetType == SenseTargetDef.ShimAim2 then
        nSenseValue = tbValues.ShipAim2 
    elseif nTargetType == SenseTargetDef.ShipAim4 then
        nSenseValue = tbValues.ShipAim4 
    elseif nTargetType == SenseTargetDef.ShipAim8 then
        nSenseValue = tbValues.ShipAim8 
    end
    return nSenseValue * 0.01
end

local function SetGlobalSenseValue(self, nGlobalValue)
    local nRate = 0
    for k, v in pairs(CAMERAS) do
        nRate = GetCameraSensePercent(nGlobalValue, v)
        self:Set(k, math.floor(nRate * 100))
    end

    for k, v in pairs(GYROS) do
        nRate = GetGyroSensePercent(nGlobalValue, v)
        self:Set(k, math.floor(nRate * 100))
    end
end

function SettingCamera:SetGlobalValue(nValue)
    local nValueType = GameCameraModeGroupDef.SettingValueType
    local nOldValue = self:Get(LocalKeys.CAMERA_GLOBAL_SENSITIVITY) + nValueType.Mini

    self:Set(LocalKeys.CAMERA_GLOBAL_SENSITIVITY, nValue)

    local nGlobalValue = nValue + nValueType.Mini
    EventManager:OnFireEvent(ClientEventDef.EV_CHANGE_SENSE_VALUE, nGlobalValue)
    
    if nGlobalValue ~= nValueType.Custom then
        SetGlobalSenseValue(self, nGlobalValue)
    elseif nOldValue ~= nValueType.Custom then
        SetGlobalSenseValue(self, nOldValue)
    end
end

function SettingCamera:GetSubValue(nKey)
    local bGyroKey = nKey >= nGyroKeyStart 
    local nTargetType = nil
    if bGyroKey then  
        nTargetType = GYROS[nKey]
    else   
        nTargetType = CAMERAS[nKey]
    end

    if not nTargetType then
        logwarning("SettingCamera:GetValue not find key", nKey)
        return 0
    end
    
    local nValueType = GameCameraModeGroupDef.SettingValueType
    local nGlobalValue = self:Get(LocalKeys.CAMERA_GLOBAL_SENSITIVITY) + nValueType.Mini
    if nGlobalValue ~= nValueType.Custom then 
        local nRate = 0
        if bGyroKey then
            nRate = GetGyroSensePercent(nGlobalValue, nTargetType)
        else 
            nRate = GetCameraSensePercent(nGlobalValue, nTargetType)
        end
        return math.floor(nRate * 100)
    else
        return self:Get(nKey)
    end
end

function SettingCamera:SetSubValue(nKey, nValue)
    local bGyroKey = nKey >= nGyroKeyStart 
    local nTargetType = nil
    if bGyroKey then  
        nTargetType = GYROS[nKey]
    else   
        nTargetType = CAMERAS[nKey]
    end

    if not nTargetType then
        logwarning("SettingCamera:SetSubValue not find key", nKey)
        return
    end

    local nValueType = GameCameraModeGroupDef.SettingValueType
    self:SetGlobalValue(nValueType.Custom - nValueType.Mini)
    
    local nPercent = nValue / 100
    if bGyroKey then 
        EventManager:OnFireEvent(ClientEventDef.EV_CHANGE_GYRO_SENSE_VALUE, nTargetType, nPercent)
    else 
        EventManager:OnFireEvent(ClientEventDef.EV_CHANGE_CAMERA_SENSE_VALUE, nTargetType, nPercent)
    end
    self:Set(nKey, nValue)
end

-- 
function SettingCamera:GetGlobalValue()
    return self:Get(LocalKeys.CAMERA_GLOBAL_SENSITIVITY) + GameCameraModeGroupDef.SettingValueType.Mini
end

function SettingCamera:GetCameraSubValues()
    local tbDatas = {}
    for k, v in pairs(CAMERAS) do
        local tbData = {nKey = v, nValue = self:Get(k)}
        table.insert(tbDatas, tbData)
    end
    return tbDatas
end

function SettingCamera:GetGyroSubValues()
    local tbDatas = {}
    for k, v in pairs(GYROS) do
        local tbData = {nKey = v, nValue = self:Get(k)}
        table.insert(tbDatas, tbData)
    end
    return tbDatas
end

return SettingCamera