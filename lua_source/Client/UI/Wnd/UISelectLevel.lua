-----------------------------------------------------
--File Name    : UISelectLevel.lua
--Author       : Edward J
--Create Time  : 2019-04-24
--Description  : UISelectLevel
-----------------------------------------------------
local luaclass                          = require("luaclass")
local WndBase                           = require("WndBase")
local UISelectLevel                     = luaclass("UISelectLevel", WndBase)

local GuideSystem                   = require("GuideSystem")
local SaveGameDef                   = require("SaveGameDef")
local pSaveGameMgr                  = ClientShell.GetClient(GWorld):GetSaveGameManager()
local ProcedureTool                 = require("ProcedureTool")

local Proto = require("ClientProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
-----------------------------------------------------
UISelectLevel.bCheckNewState    = nil
UISelectLevel.bCheckOldState    = nil
-----------------------------------------------------
local function SaveSelectStatus(bNewPlayer)
    pSaveGameMgr:AddBoolData(SaveGameDef.GUIDE_SINGLE_BE_NEW_PLAYER, bNewPlayer)
    pSaveGameMgr:Save()
end

--选择埋点
local function LogEventForSelect(self, bIsNew)
    if bIsNew then
        NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_TutorialStep, {step = 1, spent_seconds = 0})
    else
        NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_TutorialStep, {step = 1, spent_seconds = 1})
    end
end

local function OnStartClicked(self)
    local bIsNew = self.pWidgetRef.check_new:IsChecked()
    GuideSystem:SetStripGroups(300, bIsNew and 2 or 1)
    LogEventForSelect(self, bIsNew)
    self:CloseSelf()
    ProcedureTool:EnterTutorialDungeon()
end

local function OnCheckNewStateChanged(self, bState)
    local pCheck_old = self.pWidgetRef.check_old
    local pCheck_new = self.pWidgetRef.check_new
    if bState then
        pCheck_old:SetCheckedState(ECheckBoxState.Unchecked)
        SaveSelectStatus(true)
    else
        if not pCheck_old:IsChecked() then
            pCheck_new:SetCheckedState(ECheckBoxState.Checked)
        end
    end
end

local function OnCheckOldStateChanged(self, bState)
    local pCheck_old = self.pWidgetRef.check_old
    local pCheck_new = self.pWidgetRef.check_new
    if bState then
        pCheck_new:SetCheckedState(ECheckBoxState.Unchecked)
        SaveSelectStatus(false)
    else
        if not pCheck_new:IsChecked() then
            pCheck_old:SetCheckedState(ECheckBoxState.Checked)
        end
    end
end

function UISelectLevel:OnLoad()
    
end

function UISelectLevel:OnShow()
    local bNewPlayer = pSaveGameMgr:GetBoolDataWithDefault(SaveGameDef.GUIDE_SINGLE_BE_NEW_PLAYER, true)
    local pCheck_new = self.pWidgetRef.check_new
    local pCheck_old = self.pWidgetRef.check_old
    if bNewPlayer then
        pCheck_new:SetCheckedState(ECheckBoxState.Checked)
    else
        pCheck_old:SetCheckedState(ECheckBoxState.Checked)
    end
end

function UISelectLevel:OnUnload()
end

function UISelectLevel:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnStart.OnClicked, self, OnStartClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.check_new.OnCheckStateChanged, self, OnCheckNewStateChanged)
    EventHelper:RegisterCppDelegate(pWidgetRef.check_old.OnCheckStateChanged, self, OnCheckOldStateChanged)
end

return UISelectLevel