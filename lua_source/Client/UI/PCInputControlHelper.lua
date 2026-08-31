-----------------------------------------------------
--File Name    : PCInputControlHelper.lua
--Author       : chenyixin
--Description  : PC按键输入控制UI
-----------------------------------------------------
local PCInputControlHelper = {}
local SelfEventHelper = require("SelfEventHelper")
local InputHandle = require("InputHandle")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local ChannelSDKSystem = require("ChannelSDKSystem")
local ClientEventDef = require("ClientEventDef")
local BattleHumanWeaponSystemNew = dynamic_require("BattleHumanWeaponSystemNew")
local FFAHumanUIHelper = require("FFAHumanUIHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

local HandleTypeDef = {
    Common = 0,
    Human = 1,
    Ship = 2
}

PCInputControlHelper.EventHelper = nil
PCInputControlHelper.tbHandles = {}
PCInputControlHelper.tbHumanHandles = {}
PCInputControlHelper.tbShipHandles = {}
PCInputControlHelper.uiFFAMain = nil
PCInputControlHelper.bUsePCControlMode = false
PCInputControlHelper.szCurrentOpenWnd = nil

local function RegisterPressHandle(self, pInputKey, fnCallback, nHandleType)
    local tbHandle = InputHandle:BindKeyPressed(pInputKey, fnCallback, self)
    if nHandleType == HandleTypeDef.Human then
        table.insert(self.tbHumanHandles, tbHandle)
    elseif nHandleType == HandleTypeDef.Ship then
        table.insert(self.tbShipHandles, tbHandle)
    else
        table.insert(self.tbHandles, tbHandle)
    end
    self.EventHelper:RegisterHandle(tbHandle)
end

local function RegisterReleaseHandle(self, pInputKey, fnCallback, nHandleType)
    local tbHandle = InputHandle:BindKeyReleased(pInputKey, fnCallback, self)
    if nHandleType == HandleTypeDef.Human then
        table.insert(self.tbHumanHandles, tbHandle)
    else
        table.insert(self.tbHandles, tbHandle)
    end
    self.EventHelper:RegisterHandle(tbHandle)
end

local function UnregisterAllHandle(self)
    self.EventHelper:UnregisterAll()
    self.tbHandles = {}
    self.tbHumanHandles = {}
    self.tbShipHandles = {}
end

local function GetUIFFAMain(self)
    return self.uiFFAMain
end

local function GetPBFFAHuman(self)
    local wnd = GetUIFFAMain(self)
    if not wnd or not wnd.pWidgetRef then
        return nil
    end
    return wnd.pWidgetRef.pbFFAHuman
end

local function GetPBFFAShip(self)
    local wnd = GetUIFFAMain(self)
    if not wnd or not wnd.pWidgetRef then
        return nil
    end
    return wnd.pWidgetRef.pbFFAShip
end

local function PlayerIsHuman()
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if not PlayerSelf or PlayerSelf:IsDead() then
        return false
    end
    return PlayerSelf:IsHuman()
end

local function PlayerIsInVehicle()
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if not PlayerSelf or PlayerSelf:IsDead() then
        return false
    end
    if not PlayerSelf:IsHuman() then
        return false
    end
    if not PlayerSelf.GameVehicleComponent then
        return false
    end
    return PlayerSelf.GameVehicleComponent:IsInVehicle()
end

local function PlayerIsShip()
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if not PlayerSelf or PlayerSelf:IsDead() then
        return false
    end
    return PlayerSelf:IsShip()
end

local function ShowCursor(self)
    local pPlayerController = GameplayStatics.GetPlayerController(GWorld, 0)
    pPlayerController.bShowMouseCursor = true
    ExtendBlueprintFunctions.SetUseMouseForTouch(true)
end

local function HideCursor(self)
    if not self.bUsePCControlMode then
        return 
    end
    local pPlayerController = GameplayStatics.GetPlayerController(GWorld, 0)
    pPlayerController.bShowMouseCursor = false
    ExtendBlueprintFunctions.SetUseMouseForTouch(false)
    WidgetBlueprintLibrary.SetFocusToGameViewport()
end

local function ShowCursorIfWndIsNotOpen(self, szWndName)
    if not UIManager:IsWndOpen(szWndName) then
        self.szCurrentOpenWnd = szWndName
        ShowCursor(self)
        return true
    end
    return false
end

local function SwitchToPCControlMode(self, bPC)
    local pPlayerController = GameplayStatics.GetPlayerController(GWorld, 0)
    if pPlayerController then
        pPlayerController.bShowMouseCursor = not bPC
        pPlayerController.bEnableTouchEvents = not bPC
        pPlayerController.bEnableTouchOverEvents = not bPC
    end
    ExtendBlueprintFunctions.SetUseMouseForTouch(not bPC)
    local uiFFAMain = GetUIFFAMain(self)
    if uiFFAMain and uiFFAMain.pWidgetRef then
        uiFFAMain.pWidgetRef.bdrForTouch:SetVisibility(ESlateVisibility.HitTestInvisible)
    end

    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf and PlayerSelf.pUEActor then
        local PlayerInputComponent = PlayerSelf.pUEActor.PlayerInputComponent
        if PlayerInputComponent then
            PlayerInputComponent:SetCameraControlEnable(not bPC)
            PlayerInputComponent.UseGesture = not bPC
        end
    end

    self.EventHelper:FireEvent(ClientEventDef.EV_UI_SWITCH_TO_PC, bPC)

end

-------------------------------------------------------------------------------

local function OnCloseUI(self, szWndName)
    if szWndName == UIDef.UI_FFA_SELECT_BORNPOINT then
        SwitchToPCControlMode(self, true)
    end
    if szWndName ~= self.szCurrentOpenWnd then return end
    HideCursor(self)
end

local function ChangeDisplay(self)
    if not self.bUsePCControlMode then
        return
    end
    local wnd = GetUIFFAMain(self)
    if not wnd or not wnd.pWidgetRef then
        return
    end
    wnd.pWidgetRef.btnChangeDisplay:SimulateOnClick()
end

local function VehicleInteraction(self)
    if not self.bUsePCControlMode then
        return 
    end
    if not PlayerIsHuman() then
        return 
    end
    local pbFFAHuman = GetPBFFAHuman(self)
    if not pbFFAHuman then
        return
    end
    pbFFAHuman.btnHorseUp:SimulateOnClick()
    pbFFAHuman.btnHorseDown:SimulateOnClick()
end

local function ToggleSet(self)
    if not self.bUsePCControlMode then
        return 
    end

    local wnd = GetUIFFAMain(self)
    if not wnd or not wnd.pWidgetRef then
        return 
    end

    if ShowCursorIfWndIsNotOpen(self, UIDef.UI_SETTING) then
        wnd.pWidgetRef.btnSet:SimulateOnClick()
    else
        UIManager:CloseWnd(UIDef.UI_SETTING)
    end
end

local function OpenBuild(self)
    if not self.bUsePCControlMode then
        return 
    end
    local wnd = GetUIFFAMain(self)
    if not wnd or not wnd.pWidgetRef then
        return
    end
    ShowCursorIfWndIsNotOpen(self, UIDef.UI_BUILD_ITEM)
    wnd.pWidgetRef.btnBuild:SimulateOnClick()
end

local function OpenPickup(self)
    if not self.bUsePCControlMode then
        return 
    end

    local wnd = GetUIFFAMain(self)
    if not wnd or not wnd.pWidgetRef then
        return
    end 

    if UIManager:IsWndOpen(UIDef.UI_PICKUP_ITEM) then
        UIManager:CloseWnd(UIDef.UI_PICKUP_ITEM)
    else
        wnd.pWidgetRef.btnPickItem:SimulateOnClick()
    end
    
    if UIManager:IsWndOpen(UIDef.UI_PICKUP_BOX) then
        UIManager:CloseWnd(UIDef.UI_PICKUP_BOX)
    else
        wnd.pWidgetRef.btnPickBox:SimulateOnClick()
    end
end

local function ToggleBackpack(self)
    if not self.bUsePCControlMode then
        return 
    end
    local wnd = GetUIFFAMain(self)
    if not wnd or not wnd.pWidgetRef then
        return
    end
    ShowCursorIfWndIsNotOpen(self, UIDef.UI_FFABACKPACK)
    wnd.pWidgetRef.btnPack:SimulateOnClick()
end

local function ToggleMap(self)
    if not self.bUsePCControlMode then
        return 
    end
    local wnd = GetUIFFAMain(self)
    if not wnd or not wnd.pWidgetRef or not wnd.pWidgetRef.pbRadarMap then
        return 
    end
    if ShowCursorIfWndIsNotOpen(self, UIDef.UI_WORLD_MAP) then
        wnd.pWidgetRef.pbRadarMap.btnBigMap:SimulateOnClick()
    else
        UIManager:CloseWnd(UIDef.UI_WORLD_MAP)
    end
end

local function Cancel(self)
    if not self.bUsePCControlMode then
        return 
    end

    if PlayerIsHuman() and not PlayerIsInVehicle() then
        local pbFFAHuman = GetPBFFAHuman(self)
        if pbFFAHuman then
            pbFFAHuman.btnBoomCancel:SimulateOnClick()
        end
    end

    if PlayerIsShip() then
        local pbFFAShip = GetPBFFAShip(self)
        if pbFFAShip then
            pbFFAShip.btnCancelFire:SimulateOnClick()
        end
    end

    local uiProgressBar = UIManager:GetWnd(UIDef.UI_PROGRESS_BAR)
    if uiProgressBar and uiProgressBar:IsVisible() then
        uiProgressBar.pWidgetRef.pbProgressBar.btnCancel:SimulateOnClick()
    end
end

local function Crouch(self)
    if not self.bUsePCControlMode then
        return 
    end
    if not PlayerIsHuman() or PlayerIsInVehicle() then
        return
    end
    local pbFFAHuman = GetPBFFAHuman(self)
    if not pbFFAHuman then return end
    pbFFAHuman.btnSquat:SimulateOnClick()
end

local function Prone(self)
    if not self.bUsePCControlMode then
        return 
    end
    if not PlayerIsHuman() or PlayerIsInVehicle() then
        return
    end
    local pbFFAHuman = GetPBFFAHuman(self)
    if not pbFFAHuman then return end
    pbFFAHuman.btnGrovel:SimulateOnClick()
end

local function Reload(self)
    if not self.bUsePCControlMode then
        return 
    end
    if PlayerIsHuman() and not PlayerIsInVehicle() then
        local pbFFAHuman = GetPBFFAHuman(self)
        if not pbFFAHuman then return end
        pbFFAHuman.btnReload:SimulateOnClick()
    end

    if PlayerIsShip() then
        local pbFFAShip = GetPBFFAShip(self)
        if not pbFFAShip then return end
        pbFFAShip.btnLoad:SimulateOnClick()
    end
end

local function UnholdWeapon(self)
    if not self.bUsePCControlMode then
        return 
    end
    if PlayerIsHuman() and not PlayerIsInVehicle() then
        local HumanWeaponComponent = FFAHumanUIHelper.GetSelfWeaponComponent()
        if HumanWeaponComponent then
            local nCurrentWeaponId = HumanWeaponComponent:GetCurrentWeaponInstanceId()
            if nCurrentWeaponId ~= 0 then
                BattleHumanWeaponSystemNew:RequestSetCurrentWeapon(0)
            end
        end
    end

    if PlayerIsShip() then
        BattleShipWeaponSystem:RequestActivateWeaponItem()
    end
end

local function Aim(self)
    if not self.bUsePCControlMode then
        return 
    end
    if PlayerIsHuman() and not PlayerIsInVehicle() then
        local pbFFAHuman = GetPBFFAHuman(self)
        if not pbFFAHuman then return end
        pbFFAHuman.btnAim:SimulateOnClick()
    end

    if PlayerIsShip() then
        self.EventHelper:FireEvent(ClientEventDef.EV_UI_SHIP_TOGGLE_AIM_PC)
    end
end

local function ChangeWeaponOne(self)
    if not self.bUsePCControlMode then
        return
    end

    if not PlayerIsHuman() then
        return 
    end
    if PlayerIsInVehicle() then
        return
    end

    local pbFFAHuman = GetPBFFAHuman(self)
    if not pbFFAHuman or not pbFFAHuman.pbFFAHumanSub1 then
        return
    end
    pbFFAHuman.pbFFAHumanSub1.btnBlueprintItem:SimulateOnClick()
end

local function ChangeWeaponTwo(self)
    if not self.bUsePCControlMode then
        return
    end

    if not PlayerIsHuman() then
        return 
    end
    if PlayerIsInVehicle() then
        return
    end

    local pbFFAHuman = GetPBFFAHuman(self)
    if not pbFFAHuman or not pbFFAHuman.pbFFAHumanSub2 then
        return
    end
    pbFFAHuman.pbFFAHumanSub2.btnBlueprintItem:SimulateOnClick()
end

local function StartSprint(self)
    if not self.bUsePCControlMode then
        return
    end
    if not PlayerIsHuman() then
        return
    end
    if PlayerIsInVehicle() then
        return
    end
    local pPlayerInputComponent = GamePlayerSelfHelper:Get().pUEActor.PlayerInputComponent
    if not pPlayerInputComponent then return end
    if pPlayerInputComponent.MoveDelta.Y < 0 then
        self.EventHelper:FireEvent(ClientEventDef.EV_UI_JOYSTICK_SPRINT_PC, true)
    end
end

local function StopSprint(self)
    if not self.bUsePCControlMode then
        return
    end

    if not PlayerIsHuman() then
        return
    end

    if PlayerIsInVehicle() then
        return
    end
    self.EventHelper:FireEvent(ClientEventDef.EV_UI_JOYSTICK_SPRINT_PC, false)
end

local function OnPostureHalfSailStateChanged(self)
    if not PlayerIsShip() then return end
    local pbFFAShip = GetPBFFAShip(self)
    if not pbFFAShip then return end
    local bChecked = pbFFAShip.chkPostureHalfSail:IsChecked()
    self.EventHelper:FireEvent(ClientEventDef.EV_UI_SHIP_HALF_SAIL_PC, not bChecked)
end

local function OnPostureReefStateChanged(self)
    if not PlayerIsShip() then return end
    local pbFFAShip = GetPBFFAShip(self)
    if not pbFFAShip then return end
    local bChecked = pbFFAShip.chkPostureReef:IsChecked()
    self.EventHelper:FireEvent(ClientEventDef.EV_UI_SHIP_REEF_PC, not bChecked)
end

local function EnterFreeView(self)
    if not PlayerIsHuman() or PlayerIsInVehicle() then return end
    self.EventHelper:FireEvent(ClientEventDef.EV_UI_FREE_VIEW_PC, true)
end

local function LeaveFreeView(self)
    if not PlayerIsHuman() or PlayerIsInVehicle() then return end
    self.EventHelper:FireEvent(ClientEventDef.EV_UI_FREE_VIEW_PC, false)
end

local function OnOpenUI(self, szWndName)
    if szWndName == UIDef.UI_FFA_SELECT_BORNPOINT then
        SwitchToPCControlMode(self, false)
    end
end

-------------------------------------------------------------------------------

function PCInputControlHelper:Init(wnd)
    local szChannel = ChannelSDKSystem:GetChannelID()
    log("[PCInputControlHelper] Init, channel is", szChannel)
    if szChannel ~= "INTERNAL_WINDOWS" then
        self.bUsePCControlMode = false
        return 
    end

    if self.bUsePCControlMode then
        return
    end

    if not self.EventHelper then
        self.EventHelper = SelfEventHelper()
    end
    self.EventHelper:RegisterEvent(ClientEventDef.EV_PRE_CLOSE_UI, self, OnCloseUI)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_OPEN_UI, self, OnOpenUI)

    RegisterPressHandle(self, EInputKey.T, ChangeDisplay)
    
    RegisterPressHandle(self, EInputKey.Equals, ToggleSet)
    RegisterPressHandle(self, EInputKey.Y, OpenBuild)
    RegisterPressHandle(self, EInputKey.X, OpenPickup)
    RegisterPressHandle(self, EInputKey.B, ToggleBackpack)
    RegisterPressHandle(self, EInputKey.M, ToggleMap)
    RegisterPressHandle(self, EInputKey.H, Cancel)
    
    RegisterPressHandle(self, EInputKey.R, Reload)
    RegisterPressHandle(self, EInputKey.G, UnholdWeapon)
    RegisterPressHandle(self, EInputKey.RightMouseButton, Aim)

    RegisterPressHandle(self, EInputKey.LeftAlt, ShowCursor)
    RegisterReleaseHandle(self, EInputKey.LeftAlt, HideCursor)

    if PlayerIsHuman() then
        self:RegisterHumanHandle()
    end

    if PlayerIsShip() then
        self:RegisterShipHandle()
    end


    self.bUsePCControlMode = true
    self.uiFFAMain = wnd
    SwitchToPCControlMode(self, true)
end

function PCInputControlHelper:Uninit()
    if not self.EventHelper then
        self.EventHelper = SelfEventHelper()
    end
    UnregisterAllHandle(self)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_PRE_CLOSE_UI)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_OPEN_UI)

    self.bUsePCControlMode = false
    SwitchToPCControlMode(self, false)
end

function PCInputControlHelper:RegisterPCPressHandle(pInputKey, fnCallback)
    RegisterPressHandle(self, pInputKey, fnCallback)
end

function PCInputControlHelper:RegisterPCReleaseHandle(pInputKey, fnCallback)
    RegisterReleaseHandle(self, pInputKey, fnCallback)
end

function PCInputControlHelper:RegisterHumanHandle()
    RegisterPressHandle(self, EInputKey.One, ChangeWeaponOne, HandleTypeDef.Human)
    RegisterPressHandle(self, EInputKey.Two, ChangeWeaponTwo, HandleTypeDef.Human)
    RegisterPressHandle(self, EInputKey.LeftShift, StartSprint, HandleTypeDef.Human)
    RegisterReleaseHandle(self, EInputKey.LeftShift, StopSprint, HandleTypeDef.Human)
    RegisterPressHandle(self, EInputKey.F, VehicleInteraction, HandleTypeDef.Human)
    RegisterPressHandle(self, EInputKey.C, Crouch, HandleTypeDef.Human)
    RegisterPressHandle(self, EInputKey.Z, Prone, HandleTypeDef.Human)
    RegisterPressHandle(self, EInputKey.LeftControl, EnterFreeView, HandleTypeDef.Human)
    RegisterReleaseHandle(self, EInputKey.LeftControl, LeaveFreeView, HandleTypeDef.Human)
end

function PCInputControlHelper:UnregisterHumanHandle()
    for _, tbHandle in pairs(self.tbHumanHandles) do
        self.EventHelper:UnRegisterHandle(tbHandle)
    end
    self.tbHumanHandles = {}
end

function PCInputControlHelper:RegisterShipHandle()
    RegisterPressHandle(self, EInputKey.Q, OnPostureHalfSailStateChanged, HandleTypeDef.Ship)
    RegisterPressHandle(self, EInputKey.E, OnPostureReefStateChanged, HandleTypeDef.Ship)
end

function PCInputControlHelper:UnregisterShipHandle()
    for _, tbHandle in pairs(self.tbShipHandles) do
        self.EventHelper:UnRegisterHandle(tbHandle)
    end
    self.tbShipHandles = {}
end

return PCInputControlHelper