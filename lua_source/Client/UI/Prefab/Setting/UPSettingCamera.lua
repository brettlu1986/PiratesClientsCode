local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSettingCamera = luaclass("UPSettingCamera", PrefabBase)
local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")
local SettingKeyDef = require("SettingKeyDef")
local LocalKeys = SettingKeyDef.LocalKeys
local UISetUtils = require("UISetUtils")

local GetL10NTextByKey = UISetUtils.GetL10NTextByKey
local MAX_GLOBAL_CAMERA_COUNT = 4

local CAMERAS = {
    {
        nKey = LocalKeys.CAMERA_PARACHUTING_SENSITIVITY,
        szName = GetL10NTextByKey("UI_SETTING_CAMERA_PARACHUTING"),
    },
    {
        nKey = LocalKeys.CAMERA_HUMAN_CLOSE_SENSITIVITY,
        szName = GetL10NTextByKey("UI_SETTING_CAMERA_HUMANCLOSE"),
    },
    {
        nKey = LocalKeys.CAMERA_HUMAN_OPEN_SENSITIVITY,
        szName = GetL10NTextByKey("UI_SETTING_CAMERA_HUMANOPEN"),
    },
    {
        nKey = LocalKeys.CAMERA_SHIP_CLOSE_SENSITIVITY,
        szName = GetL10NTextByKey("UI_SETTING_CAMERA_SHIPCLOSE"),
    },
    {
        nKey = LocalKeys.CAMERA_SHIP_OPEN2_SENSITIVITY,
        szName = GetL10NTextByKey("UI_SETTING_CAMERA_SHIPOPEN2"),
    },
    {
        nKey = LocalKeys.CAMERA_SHIP_OPEN4_SENSITIVITY,
        szName = GetL10NTextByKey("UI_SETTING_CAMERA_SHIPOPEN4"),
    },
    {
        nKey = LocalKeys.CAMERA_SHIP_OPEN8_SENSITIVITY,
        szName = GetL10NTextByKey("UI_SETTING_CAMERA_SHIPOPEN8"),
    },
}

local GYROS = {
    {
        nKey = LocalKeys.GYRO_PARACHUTING_SENSITIVITY,
        szName = GetL10NTextByKey("UI_SETTING_CAMERA_PARACHUTING"),
    },
    {
        nKey = LocalKeys.GYRO_HUMAN_CLOSE_SENSITIVITY,
        szName = GetL10NTextByKey("UI_SETTING_CAMERA_HUMANCLOSE"),
    },
    {
        nKey = LocalKeys.GYRO_HUMAN_OPEN_SENSITIVITY,
        szName = GetL10NTextByKey("UI_SETTING_CAMERA_HUMANOPEN"),
    },
    {
        nKey = LocalKeys.GYRO_SHIP_CLOSE_SENSITIVITY,
        szName = GetL10NTextByKey("UI_SETTING_CAMERA_SHIPCLOSE"),
    },
    {
        nKey = LocalKeys.GYRO_SHIP_OPEN2_SENSITIVITY,
        szName = GetL10NTextByKey("UI_SETTING_CAMERA_SHIPOPEN2"),
    },
    {
        nKey = LocalKeys.GYRO_SHIP_OPEN4_SENSITIVITY,
        szName = GetL10NTextByKey("UI_SETTING_CAMERA_SHIPOPEN4"),
    },
    {
        nKey = LocalKeys.GYRO_SHIP_OPEN8_SENSITIVITY,
        szName = GetL10NTextByKey("UI_SETTING_CAMERA_SHIPOPEN8"),
    },
}

local CHECKED, UNCHECKED = ECheckBoxState.Checked, ECheckBoxState.Unchecked

UPSettingCamera.pbCameraSubs = nil
UPSettingCamera.pbGyroSubs = nil

local function RefreshGlobalUI(self)
    local pWidgetRef = self.pWidgetRef
    local nValue = self.tbInstance:Get(LocalKeys.CAMERA_GLOBAL_SENSITIVITY)
    for i = 1, MAX_GLOBAL_CAMERA_COUNT do
        pWidgetRef["cbCamera"..i]:SetCheckedState(nValue == i and CHECKED or UNCHECKED)
    end
end

local function RefreshCameraSubUI(self, nIndex)
    local nKey = CAMERAS[nIndex].nKey
    local nValue = self.tbInstance:GetSubValue(nKey)
    
    self.pbCameraSubs[nIndex]:OnRefresh(nValue)    
end

local function RefreshGyroSubUI(self, nIndex)
    local nKey = GYROS[nIndex].nKey
    local nValue = self.tbInstance:GetSubValue(nKey)
    
    self.pbGyroSubs[nIndex]:OnRefresh(nValue)    
end

local function RefreshUI(self)
    RefreshGlobalUI(self)
    for i, v in ipairs(CAMERAS) do
        RefreshCameraSubUI(self, i)
    end
    for i, v in ipairs(GYROS) do
        RefreshGyroSubUI(self, i)
    end 
end

local function InitSubUIs(self)
    for i, v in ipairs(CAMERAS) do
        RefreshCameraSubUI(self, i)
    end    

    for i, v in ipairs(GYROS) do
        RefreshGyroSubUI(self, i)
    end    
end

local function OnClickedGlobalCamera(self, nIndex, bActivate)
    local nCurValue = self.tbInstance:Get(LocalKeys.CAMERA_GLOBAL_SENSITIVITY)
    if nCurValue == nIndex then
        if not bActivate then
            self.pWidgetRef["cbCamera"..nIndex]:SetCheckedState(CHECKED)
        end
    else
        self.tbInstance:SetGlobalValue(nIndex)
        RefreshUI(self)
    end
end

function UPSettingCamera:OnLoad()
    local pWidgetRef = self.pWidgetRef
    local tbCameras = {}
    for i, v in ipairs(CAMERAS) do
        local pbSound = self.PrefabHelper:BindPrefab(pWidgetRef["pCameraSub"..i])
        pbSound:InitUI(self, v.nKey, v.szName)
        table.insert(tbCameras, pbSound)
    end 
    self.pbCameraSubs = tbCameras   

    local tbGyros = {}
    for i, v in ipairs(GYROS) do 
        local pbGyro = self.PrefabHelper:BindPrefab(pWidgetRef["pGyroSub"..i])
        pbGyro:InitUI(self, v.nKey, v.szName)
        table.insert(tbGyros, pbGyro)
    end
    self.pbGyroSubs = tbGyros
end

function UPSettingCamera:OnShow()
    InitSubUIs(self)
    RefreshUI(self)
end

function UPSettingCamera:OnCreate()
    self.tbInstance = SettingSystemNew:GetInstance(SettingClassType.Setting_Camera)
end

function UPSettingCamera:OnDestroy()
    self.tbInstance = nil
end

function UPSettingCamera:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    for i = 1, MAX_GLOBAL_CAMERA_COUNT do
        EventHelper:RegisterCppDelegate(pWidgetRef["cbCamera"..i].OnCheckStateChanged,  self, function(_, bActivate)
            OnClickedGlobalCamera(self, i, bActivate)
        end)
    end    
end

function UPSettingCamera:Activate()

end

function UPSettingCamera:SetSubValue(tbSub, nKey, nValue)
    self.tbInstance:SetSubValue(nKey, nValue)
    SettingSystemNew:SaveLocalData()
    tbSub:OnRefresh(self.tbInstance:GetSubValue(nKey))

    RefreshGlobalUI(self)
end

return UPSettingCamera