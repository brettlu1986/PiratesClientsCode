-----------------------------------------------------
--File Name    : UPDebugShipMovePanel.lua
--Author       : WuJizhou
--Create Time  : 2018-6-28 11:51:30
--Description  : UPDebugShipMovePanel
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")

local UPDebugShipMovePanel = luaclass("UPDebugShipMovePanel", PrefabBase)

local UIDef = require("UIDef")
local PlayerSelfHelper = require("GamePlayerSelfHelper")
local SelfVerticalListHelper = require("SelfVerticalListHelper")

UPDebugShipMovePanel.tbShipMoveControllers = nil
UPDebugShipMovePanel.ListHelper = nil



local ShipMoveControllerType =
{
    MaxLinearSpeed = {nTypeId = 1, szName = "最大线速度", fnCallback = function(self, nValue) self.pWidgetRef.txtMaxLinearSpeed:SetText(string.format("%.1f kt", nValue)) end},
    LinearAcceleration = {nTypeId = 2, szName = "线加速度"},
    LinearDeceleration = {nTypeId = 3, szName = "线减速度"},
    MaxAngularSpeed = {nTypeId = 4, szName = "最大角速度"},
    AngularAcceleration = {nTypeId = 5, szName = "角加速度"},
    AngularDeceleration = {nTypeId = 6, szName = "角减速度"},
}

-- 当前使用InputController的类型
local tbInputControllerTypes = 
{
    ShipMoveControllerType.MaxLinearSpeed,
}


local function CMToKT(nCMValue)
    local nKTValue = (nCMValue / 100) * 1.600000
    return nKTValue
end


local function DisplayCurMaxLinearSpeed(self)
    local pSelfActor = PlayerSelfHelper:GetUEActor()
    local pShipMovementComponent = pSelfActor.ShipMovementComponent
    if pShipMovementComponent then
        local nSpeed = pShipMovementComponent:GetCurrentMaxLinearSpeed()
        nSpeed = CMToKT(nSpeed)
        self.pWidgetRef.txtMaxLinearSpeed:SetText(string.format("%.1f kt", nSpeed))
    else
        self.pWidgetRef.txtMaxLinearSpeed:SetText("0")
    end
end

local function GetShipMoveControllerValue(tbShipMoveControllers, nShipMoveControllerType)
    return tbShipMoveControllers[nShipMoveControllerType]:GetShipMoveControllerScaleValue()
end


-- 不真正生效
local function SetShipMoveGearBuffOnClient(nMaxLinearSpeed, nLinearAcceleration, nLinearDeceleration, nMaxAngularSpeed, nAngularAcceleration, nAngularDeceleration)
    log(nMaxLinearSpeed, nLinearAcceleration, nLinearDeceleration, nMaxAngularSpeed, nAngularAcceleration, nAngularDeceleration)
    local pSelfActor = PlayerSelfHelper:GetUEActor()
    local pShipMovementComponent = pSelfActor.ShipMovementComponent
    if pShipMovementComponent then
        pShipMovementComponent:SetShipMoveGearBuff(true, nMaxLinearSpeed, nLinearAcceleration, nLinearDeceleration, nMaxAngularSpeed, nAngularAcceleration, nAngularDeceleration);
    end
end

local function SetShipMoveGearBuffToServer(nMaxLinearSpeed, nLinearAcceleration, nLinearDeceleration, nMaxAngularSpeed, nAngularAcceleration, nAngularDeceleration)
    local szCommand = string.format("dm setshipmovegearbuff %d %d %d %d %d %d ", nMaxLinearSpeed, nLinearAcceleration, nLinearDeceleration, nMaxAngularSpeed, nAngularAcceleration, nAngularDeceleration)
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, szCommand, GameplayStatics.GetPlayerController(GWorld, 0))
end

function UPDebugShipMovePanel:OnShipMovementChangedConfirmed()
    local tbShipMoveControllers = self.tbShipMoveControllers
    local nMaxLinearSpeed = GetShipMoveControllerValue(tbShipMoveControllers, ShipMoveControllerType.MaxLinearSpeed.nTypeId)
    local nLinearAcceleration = GetShipMoveControllerValue(tbShipMoveControllers, ShipMoveControllerType.LinearAcceleration.nTypeId)
    local nLinearDeceleration = GetShipMoveControllerValue(tbShipMoveControllers, ShipMoveControllerType.LinearDeceleration.nTypeId)
    local nMaxAngularSpeed = GetShipMoveControllerValue(tbShipMoveControllers, ShipMoveControllerType.MaxAngularSpeed.nTypeId)
    local nAngularAcceleration = GetShipMoveControllerValue(tbShipMoveControllers, ShipMoveControllerType.AngularAcceleration.nTypeId)
    local nAngularDeceleration = GetShipMoveControllerValue(tbShipMoveControllers, ShipMoveControllerType.AngularDeceleration.nTypeId)
    
    -- 由于缺少速度改变后的同步事件，故只能用此方法hack，即先客户端本地set，更新速度
    SetShipMoveGearBuffOnClient(nMaxLinearSpeed, nLinearAcceleration, nLinearDeceleration, nMaxAngularSpeed, nAngularAcceleration, nAngularDeceleration)
    DisplayCurMaxLinearSpeed(self)
    SetShipMoveGearBuffToServer(nMaxLinearSpeed, nLinearAcceleration, nLinearDeceleration, nMaxAngularSpeed, nAngularAcceleration, nAngularDeceleration)

end

function UPDebugShipMovePanel:OnResetBtnClicked()
    for k, v in pairs(self.tbShipMoveControllers) do
        v:ResetShipMoveControllerScaleValue()
    end

    local nMaxLinearSpeed = 0
    local nLinearAcceleration = 0
    local nLinearDeceleration = 0
    local nMaxAngularSpeed = 0
    local nAngularAcceleration = 0
    local nAngularDeceleration = 0
    -- 由于缺少速度改变后的同步事件，故只能用此方法hack，即先客户端本地set，更新速度
    SetShipMoveGearBuffOnClient(nMaxLinearSpeed, nLinearAcceleration, nLinearDeceleration, nMaxAngularSpeed, nAngularAcceleration, nAngularDeceleration)
    DisplayCurMaxLinearSpeed(self)
    SetShipMoveGearBuffToServer(nMaxLinearSpeed, nLinearAcceleration, nLinearDeceleration, nMaxAngularSpeed, nAngularAcceleration, nAngularDeceleration)
end

function UPDebugShipMovePanel:OnCreate()
    self.ListHelper = SelfVerticalListHelper() 
end

function UPDebugShipMovePanel:OnLoad()
    self.tbShipMoveControllers = {}
    local pWidgetRef = self.pWidgetRef

    for k, v in pairs(ShipMoveControllerType) do
        local nTypeId = v.nTypeId
        local szWidgetName = "pbShipMoveController_"..nTypeId
        local pShipMoveController =  self.PrefabHelper:BindPrefab(pWidgetRef[szWidgetName], UIDef.UP_DEBUG_SHIP_MOVE_SLIDER_CONTROLLER)
        -- pShipMoveController:SetShipMoveChangedCallback(self.OnShipMovementChanged, self)
        pShipMoveController:SetShipMoveControllerType(k)
        self.tbShipMoveControllers[nTypeId] =pShipMoveController
    end
    local tbDataList = {}
    for _, t in ipairs(tbInputControllerTypes) do
        local tbData = {}
        tbData.nType = t.nTypeId
        tbData.szName = t.szName
        tbData.fnCallback = t.fnCallback
        tbData.tbParams = self
        table.insert(tbDataList, tbData)
    end
    self.ListHelper:Init(self, pWidgetRef.listInputControllers, tbDataList, UIDef.UP_DEBUG_SHIP_MOVE_INPUT_CONTROLLER)

end

function UPDebugShipMovePanel:OnUnload()
    self.tbShipMoveControllers = nil
    self.ListHelper:Uninit()
end


function UPDebugShipMovePanel:OnShow()
    DisplayCurMaxLinearSpeed(self)
end

function UPDebugShipMovePanel:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnConfirm.OnClicked, self, self.OnShipMovementChangedConfirmed)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnReset.OnClicked, self, self.OnResetBtnClicked)
end


return UPDebugShipMovePanel