local LobbyPopOpenLevelDataTable = require("LobbyPopOpenLevelDataTable")
local SelfEventHelper= require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")

local LobbyPopWndHelper = {}

LobbyPopWndHelper.tbPacketSuccessResponse = nil
LobbyPopWndHelper.tbPacketFailedResponse = nil
LobbyPopWndHelper.tbResponses = nil
LobbyPopWndHelper.tbSkipResponse = nil

LobbyPopWndHelper.nCurLevel = nil
LobbyPopWndHelper.szCurUI = nil
LobbyPopWndHelper.bProcessProtoOver = nil
LobbyPopWndHelper.bProcessUIOver = nil

LobbyPopWndHelper.PacketBinder = nil
LobbyPopWndHelper.bPause = nil

local function ProcessNextUI(self)
    if self.bPause then
        log("LobbyPopWndHelper process but pause ", self.nCurLevel)
        return
    end
    self.nCurLevel = self.nCurLevel + 1
    log("LobbyPopWndHelper process ui level ", self.nCurLevel)
    local tbTemp = LobbyPopOpenLevelDataTable:GetTemplate(self.nCurLevel)
    if tbTemp == nil then
        log("LobbyPopWndHelper process ui over")
        self.bProcessUIOver = true
        self.EventHelper:FireEvent(ClientEventDef.EV_ON_OVER_POP)
        return
    end
    
    local szFileName = tbTemp.szProcess
    if szFileName == nil or tbTemp.szUI == nil then
        ProcessNextUI(self)
        return
    end
    if self.tbSkipResponse[self.nCurLevel] ~= nil then
        log("LobbyPopWndHelper process ui skip ", self.nCurLevel)

        ProcessNextUI(self)
        return
    end

    log("LobbyPopWndHelper process ui level exec ", self.nCurLevel)
    self.szCurUI = tbTemp.szUI 
    local Class = require(szFileName)
    Class:ProcessUIPop(tbTemp.szUI)
end

local function GetResponse(self, nLevel)
    local tbResponses = self.tbResponses
    for k, v in pairs(tbResponses) do
        if nLevel == v.nLevel then
            return k, v
        end
    end
end

local function ProcessProto(self, szName, tbPacket)
    local tbProcess = self.tbPacketSuccessResponse[szName] or self.tbPacketFailedResponse[szName]
    if tbProcess == nil then
        logerror("LobbyPopWndHelper ProcessProto Failed: ", szName)
        return
    end

    log("popwnd process ", szName)
    tbProcess.fnCallback(tbProcess.tbHandle, tbPacket)
end

local function ProcessNextProto(self)
    if self.bProcessProtoOver then
        return
    end

    local szName, tbResponse = GetResponse(self, self.nCurLevel + 1)
    if szName == nil then
        if self.tbSkipResponse[self.nCurLevel + 1] == nil then
            log("LobbyPopWndHelper process over")
            self.bProcessProtoOver = true
            self.nCurLevel = 0
            ProcessNextUI(self)
            return
        else
            self.nCurLevel = self.nCurLevel + 1
            ProcessNextProto(self)
            return
        end
    end

    self.nCurLevel = tbResponse.nLevel
    ProcessProto(self, szName, tbResponse.tbPacket)
end

local function VerifySkip(self, tbPopTemp)
    if tbPopTemp.szProcess == nil or tbPopTemp.szSkipParam == nil then
        return true
    end
    local Class = require(tbPopTemp.szProcess)
    local bSkip = Class:CanSkip(tbPopTemp.szSkipParam)

    if bSkip then
        self.tbSkipResponse[tbPopTemp.nLevel] = true
    end

    return bSkip    
end

local function CacheProto(self, szName, tbPacket)
    if self.bProcessProtoOver then
        ProcessProto(self, szName, tbPacket)
        return
    end

    local tbResponses = self.tbResponses

    local bOver = true

    tbResponses[szName] = {tbPacket = tbPacket}
    local tbContainer = LobbyPopOpenLevelDataTable:GetContainer()
    for k, v in pairs(tbContainer) do
        if tbResponses[v.szSuccessProto] == nil and tbResponses[v.szFailedProto] == nil then
            if v.bCanSkip then
                if not VerifySkip(self, v) then
                    bOver = false
                end
            else
                bOver = false
            end
        end
        if v.szSuccessProto == szName or v.szFailedProto == szName then
            tbResponses[szName].nLevel = v.nLevel
            tbResponses[szName].szUI = v.szUI
        end
    end

    if bOver then
        self.nCurLevel = 0
        ProcessNextProto(self)
    end
end

local function OnPreDestroyUI(self, szWndName)
    if szWndName == self.szCurUI then
        ProcessNextUI(self)
    end
end

local function OnPausePop(self)
    self.bPause = true
end

local function OnResumePop(self)
    self.bPause = false
end

local function BindMethod(self, szName)
    self.PacketBinder:BindMethod(szName, self, function(_, tbPacket) CacheProto(self, szName, tbPacket) end)
end

function LobbyPopWndHelper:Init(Binder)
    self.tbPacketSuccessResponse = {}
    self.tbPacketFailedResponse = {}
    self.tbResponses = {}
    self.tbSkipResponse = {}
    self:SetBinder(Binder)
    self.bPause = false

    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper
    -- 通过上一个界面关闭（没有界面时触发EV_ON_NEXT_POP事件），来处理下一个包
    EventHelper:RegisterEvent(ClientEventDef.EV_PRE_DESTROY_UI, self, OnPreDestroyUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_NEXT_POP, self, ProcessNextProto)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_NEXT_UI_POP, self, ProcessNextUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_PAUSE_POP, self, OnPausePop)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RESUME_POP, self, OnResumePop)
end

function LobbyPopWndHelper:Uninit()
    if self.EventHelper ~= nil then
        self.EventHelper:UnregisterAll()
        self.EventHelper = nil
    end

    local Binder = self.PacketBinder
    if Binder ~= nil then
        for k, v in pairs(self.tbPacketSuccessResponse) do
            Binder:UnbindMethod(k, nil, nil)
        end
        for k, v in pairs(self.tbPacketFailedResponse) do
            Binder:UnbindMethod(k, nil, nil)
        end
        self.PacketBinder = nil
    end

    self.tbPacketSuccessResponse = nil
    self.tbPacketFailedResponse = nil
    self.tbResponses = nil
    self.bProcessProtoOver = nil
    self.tbSkipResponse = nil
end

function LobbyPopWndHelper:SetBinder(Binder)
    self.PacketBinder = Binder
end

function LobbyPopWndHelper:RegisterResponse(szNameSuccess, szNameFailed, tbHandle, fnSuccessCallback, fnFailedCallback)
    if self.tbPacketSuccessResponse[szNameSuccess] ~= nil then
        logerror("LobbyPopWndHelper:RegisterResponse already register", szNameSuccess)
        return
    end

    self.tbPacketSuccessResponse[szNameSuccess] = {tbHandle = tbHandle, fnCallback = fnSuccessCallback}
    self.tbPacketFailedResponse[szNameFailed] = {tbHandle = tbHandle, fnCallback = fnFailedCallback}

    BindMethod(self, szNameSuccess)
    BindMethod(self, szNameFailed)
end

function LobbyPopWndHelper:RegisterSameResponse(szName, tbHandle, fnCallback)
    if self.tbPacketSuccessResponse[szName] ~= nil then
        logerror("LobbyPopWndHelper:RegisterSameResponse already register", szName)
        return
    end

    self.tbPacketSuccessResponse[szName] = {tbHandle = tbHandle, fnCallback = fnCallback}
    BindMethod(self, szName)
end

function LobbyPopWndHelper:Test(szName, tbPacket)
    CacheProto(self, szName, tbPacket)
end

return LobbyPopWndHelper