local DelayTimer = require("DelayTimer")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local ResourceManager = require("ResourceManager")
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local LoadingSystem = {}

LoadingSystem.bInLoading = false
LoadingSystem.tbStepList = {}
LoadingSystem.nStepCount = 0
LoadingSystem.tbLoadingWnd = nil
LoadingSystem.szLoadingWnd = nil
LoadingSystem.tbTimerObject = nil
LoadingSystem.tbLoadingInfo = nil
LoadingSystem.bShowUI = true
LoadingSystem.nPlayerLevel = nil

local function UseLoadingScreen()
    if not GWithEditor and GlobalVariableSystem_C.bUseLoadingScreen then
        return true
    end
    return false
end

local function GetPlayerLevel()
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf and PlayerSelf.LobbyPropertyComponent then
        return PlayerSelf.LobbyPropertyComponent:GetPlayerLevel()
    else
        return 0
    end
end

function LoadingSystem:Init()
    -- Regist PreLoadMap and PostLoadMap Event
end

function LoadingSystem:Uninit()
    self:ClearSteps()
    self:ClearTimer()
end

function LoadingSystem:AddStepMethod(tbSelf, fnStep)
    if(fnStep == nil) then
        error("LoadingSystem:AddStepMethod failed, nil step")
        return
    end

    table.insert(self.tbStepList, function()
        fnStep(tbSelf)
    end)
end

function LoadingSystem:AddStepFunction(fnStep)
    if(fnStep == nil) then
        error("LoadingSystem:AddStepFunction failed, nil step")
        return
    end
    table.insert(self.tbStepList, fnStep)
end

function LoadingSystem:GetInLoading()
    return self.bInLoading
end



function LoadingSystem:ClearSteps()
    log("LoadingSystem:Clear")
    self.tbStepList = {}
    self.tbLoadingInfo = nil
    if UseLoadingScreen() then
        ClientShell.GetClient(GWorld):ResetLoading()
    else
        local LoadingWnd = UIManager:GetWnd(UIDef.UI_LOADING)
        if LoadingWnd then
            LoadingWnd.nTargetPercent = 0
        end
    end

end

local function ShowUI(self, tbParam, szLoadingUI)
    if UseLoadingScreen() then
        tbParam.bAddToView = false
        self.szLoadingWnd = szLoadingUI or UIDef.UI_LOADING_NEW
        self.tbLoadingWnd = UIManager:OpenWnd(self.szLoadingWnd, tbParam)
    else
        self.szLoadingWnd = szLoadingUI or UIDef.UI_LOADING
        local LoadingWnd = UIManager:GetWnd(self.szLoadingWnd)
        if not LoadingWnd then
            self.tbLoadingWnd = UIManager:OpenWnd(self.szLoadingWnd,tbParam)
        else
            self.tbLoadingWnd = LoadingWnd
            self.tbLoadingWnd:Reload(tbParam)
        end
    end
end

function LoadingSystem:Start(tbParam, bImmediate, bShowUI, szLoadingUI)
    self.bInLoading = true
    self.bShowUI = bShowUI
    EventManager:OnFireEvent(ClientEventDef.EV_ENTER_LOADING)
    self:ClearTimer()
    self.nStepCount = #self.tbStepList

    local nPlayerLevel = GetPlayerLevel()
    if nPlayerLevel > 0 or (not self.nPlayerLevel) then
        self.nPlayerLevel = nPlayerLevel
    end
    tbParam.nPlayerLevel = self.nPlayerLevel

    if(bShowUI == nil or bShowUI == true) then
        ShowUI(self, tbParam, szLoadingUI)
    end
    self:StepNext(bImmediate == true)

    -- forscene
    local Shell = ClientShell.GetClient(GWorld)
    --Shell:ToggleSceneRendering(false)
    LowEntryExtendedStandardLibrary.SetWorldRenderingEnabled(false)
    Shell:FlushAsyncLoading()
end

function LoadingSystem:StepNext(bImmediate)
    if #self.tbStepList > 0 then
        log("LoadingSystem StepNext", self.nStepCount - #self.tbStepList + 1, bImmediate)
        -- Add progress on UI with 1/self.nStepCount
        if not UseLoadingScreen() and self.tbLoadingWnd then
            self.tbLoadingWnd:AddPercent(1 / self.nStepCount)
        end
        local tbCurrentStep = self.tbStepList[1]
        local fnStep = function()
            self.tbTimerObject = nil
            tbCurrentStep()
        end
        table.remove(self.tbStepList, 1)
        if(bImmediate) then
            fnStep()
        else
            self.tbTimerObject = DelayTimer:RunNextTick(fnStep)
        end
    else
        log("LoadingSystem pre Close UI")
        if UseLoadingScreen() then
            UIManager:CloseWnd(self.szLoadingUI)
            ClientShell.GetClient(GWorld):EndLoading()
        elseif self.tbLoadingWnd then
            self.tbLoadingWnd:TryCloseWnd()
        end

        self.tbLoadingWnd = nil
        self.szLoadingUI  = nil
        self.tbTimerObject = nil
        log("LoadingSystem Close UI")

        local Shell = ClientShell.GetClient(GWorld)
        --Shell:ToggleSceneRendering(true)
        LowEntryExtendedStandardLibrary.SetWorldRenderingEnabled(true)
        Shell:InitiallyLoadLevelStreaming()
        self.bInLoading = false

        EventManager:OnFireEvent(ClientEventDef.EV_EXIT_LOADING)

        ResourceManager:GC()
    end
end

function LoadingSystem:ClearTimer()
    if(self.tbTimerObject) then
        DelayTimer:ClearTimer(self.tbTimerObject)
        self.tbTimerObject = nil
    end
end

function LoadingSystem:Cancel()
    log("LoadingSystem:Cancel")
    if UseLoadingScreen() then
        UIManager:CloseWnd(self.szLoadingUI)
    else
        local tbLoadingWnd = UIManager:GetWnd(self.szLoadingUI)
        if tbLoadingWnd ~= nil then
            self.bInLoading = false
            UIManager:CloseWnd(self.szLoadingUI)
            --ClientShell.GetClient(GWorld):ToggleSceneRendering(true)
            LowEntryExtendedStandardLibrary.SetWorldRenderingEnabled(true)
            self.tbLoadingWnd = nil
            self.szLoadingUI = nil
            self:ClearSteps()
            self:ClearTimer()
        else
            log("LoadingSystem:Cancel failed. tbLoadingWnd nil")
        end
    end
end

function LoadingSystem:ShowDialogMessage(tbParam)
    if self.tbLoadingWnd ~= nil then
        self.tbLoadingWnd:ShowDialogMessage(tbParam)
    end
end

return LoadingSystem
