-----------------------------------------------------
--File Name    : UICinematicState.lua
--Author       : Ran Jie
--Create Time  : 2017-03-07
--Description  : 影院模式状态，除状态默认打开的UI，其它UI都不显示，比如半身像对话、播matinee时的状态
--               可以从影院模式状态继承
-----------------------------------------------------

local luaclass = require("luaclass")
local StateBase = require("StateBase")
local UICinematicState = luaclass("UICinematicState", StateBase)

local UIManager = require("UIManager")
local UIDef = require("UIDef")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local UIStateDef = require("UIStateDef")


               
UICinematicState.bCinematicMode = nil
UICinematicState.tbHubHeadInfo = nil
UICinematicState.bOnlyHideWnd = false
UICinematicState.bForbitIgnoreCinematicMode = false

local function SetWndVisible(self, Wnd, pSlateVisibility, bCinematicMode)
    local tbWndTemplate = Wnd.tbTemplate
    local szWndName = tbWndTemplate.szWndName
    local tbCinematicWnd = self.tbActiveWnd

    if self.bOnlyHideWnd or self.bForbitIgnoreCinematicMode or tbCinematicWnd[szWndName] ~= nil then
        if Wnd.pWidgetRef then
            Wnd.pWidgetRef:SetVisibility(pSlateVisibility)
        end
    elseif bCinematicMode and not tbWndTemplate.bIgnoreCinematicMode and not self.tbPermanentWnd[szWndName] then
        UIManager:CloseWnd( szWndName )
        if(not tbWndTemplate.bCache)then
            UIManager:DestroyWnd(szWndName)
        end
    elseif not bCinematicMode and not self.tbPermanentWnd[szWndName]then
        UIManager:CloseWnd( szWndName )
        if(not tbWndTemplate.bCache)then
            UIManager:DestroyWnd(szWndName)
        end
    end
    
end

local function GetCurrentWndStack()
    local tbWndStack = {}
    local tbOriginalWndStack = UIManager:GetWndStack()
    for k, v in pairs(tbOriginalWndStack) do
        tbWndStack[k] = v
    end
    return tbWndStack
end

local function GetCurrentWndList()
    --logwarning("[UI]call back="..debug.traceback())
    local tbWndList = {}
    local tbOriginalWndList = UIManager:GetWndList()
    for k, v in pairs(tbOriginalWndList)do
        tbWndList[k] = v
    end
    return tbWndList
end

local function SetCinematicMode(self, bCinematicMode)
    local pSlateVisibility = bCinematicMode and ESlateVisibility.Collapsed or ESlateVisibility.SelfHitTestInvisible
    
    local tbWndStack = GetCurrentWndStack()
    local nStackCount = #tbWndStack
    --logdebug("SetCinematicMode:bCinematicMode,nStackCount=",bCinematicMode, nStackCount)
    for i = nStackCount, 1, -1 do
        local Wnd = UIManager:GetWnd(tbWndStack[i])
        --logdebug("[UI]SetCinematicMode stack:i, wnd name=",i, tbWndStack[i])
        if Wnd then
            SetWndVisible(self, Wnd, pSlateVisibility, bCinematicMode)
        end
    end
    local tbWndList = GetCurrentWndList()
    for k, v in pairs(tbWndList) do
        --logdebug("[UI]SetCinematicMode WndList:wnd name=",k)
        SetWndVisible(self, v, pSlateVisibility, bCinematicMode)
    end
    
    --血条
    local tbActors = GameplayStatics.GetAllActorsOfClass(GWorld, Pawn)
    for i,v in ipairs(tbActors) do
        if isvalidhandle(v) then
            if v.HubHeadInfo and isvalidhandle(v.HubHeadInfo) and v.HubHeadInfo:GetUserWidgetObject() then
                local HeadInfoUserWidget = v.HubHeadInfo:GetUserWidgetObject()
                local nUniqueId = ExtendBlueprintFunctions.GetObjectUniqueID(v)
                if bCinematicMode then
                    self.tbHubHeadInfo[nUniqueId] = HeadInfoUserWidget:GetVisibility()
                else
                    pSlateVisibility = self.tbHubHeadInfo[nUniqueId] == nil and ESlateVisibility.SelfHitTestInvisible or self.tbHubHeadInfo[nUniqueId]
                end
                HeadInfoUserWidget:SetVisibility(pSlateVisibility)
            end
        end
    end
    if not bCinematicMode then
        self.tbHubHeadInfo = {}
    end
    EventManager:OnFireEvent(bCinematicMode and ClientEventDef.EV_ENTER_CINEMATIC_MODE or ClientEventDef.EV_EXIT_CINEMATIC_MODE)
end

function UICinematicState:Init(szUIStateName)
    UICinematicState.super.Init(self, szUIStateName) 
    --
    self:AddPermanentWnd(UIDef.UI_LOADING)
    self:AddPermanentWnd(UIDef.UI_ERROR_DIALOG)
    self:AddPermanentWnd(UIDef.UI_RETRY_CONNECT_DIALOG)
    self:AddPermanentWnd(UIDef.UI_WAIT_CONNECT_DIALOG)
    --
    self:AddActiveWnd(UIDef.UI_TOAST_BOARD)
    self:AddActiveWnd(UIDef.UI_SPECIAL_TOAST_BOARD)
    self:AddActiveWnd(UIDef.UI_GUIDE)
    --self:AddActiveWnd(UIDef.UI_FFA_SELECT_BORNPOINT)
    --self:AddActiveWnd(UIDef.UI_COUNT_DOWN2)
    self:AddActiveWnd(UIDef.UI_BLACKSCREEN)

    self.nStateType = UIStateDef.StateType.CINEMATIC
    self.tbHubHeadInfo = {}
end

function UICinematicState:Enter(tbParam)
    local tbStateParam = tbParam == nil and {} or tbParam
    SetCinematicMode(self, true)
    --打开UI
    local nCount = #self.tbOpenWnd
    for i=1, nCount do
        local szWndName = self.tbOpenWnd[i]
        UIManager:OpenWnd(szWndName, tbStateParam[szWndName])
    end
end

function UICinematicState:Exit()
    SetCinematicMode(self, false)
    local nCount = #self.tbOpenWnd
    for i=1, nCount do
        local szWndName = self.tbOpenWnd[i]
        UIManager:CloseWnd(szWndName)
    end
end

function UICinematicState:VerifyWndVisibility(Wnd)
    --logdebug("[UI]Wnd.tbTemplate.bIgnoreCinematicMode="..tostring(Wnd.tbTemplate.bIgnoreCinematicMode))
    if(not Wnd.tbTemplate.bIgnoreCinematicMode)then
        return false
    else
        return true
    end
end


return UICinematicState
