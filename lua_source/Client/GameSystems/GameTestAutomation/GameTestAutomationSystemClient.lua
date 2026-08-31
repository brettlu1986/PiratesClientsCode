-----------------------------------------------------
--File Name    : GameTestAutomationSystemClient.lua
--Author       : WuJizhou
--Create Time  : 7/23/2019, 2:40:26 PM
--Description  : GameTestAutomationSystemClient
-----------------------------------------------------
local GameTestAutomationSystemClient = {}

local Timer                         = require("Timer")
local UIDef                         = require("UIDef")
local UIManager                     = require("UIManager")
local StringUtil                    = require("StringUtil")
local ClientEventDef                = require("ClientEventDef")
local ItemCategoryDef               = require("ItemCategoryDef")
local SelfEventHelper               = require("SelfEventHelper")
local GameTestAutomationVariables   = require("GameTestAutomationVariables")
local GameTestAutomationBattleDataHelper = require("GameTestAutomationBattleDataHelper")

local GameTestAutomationLogHelper  = dynamic_require("GameTestAutomationLogHelper")

local BATTLE_TEST_AUTOMATION = "BattleTestAutomationSystemClient"

local START_NEXT_BATTLE_TIMER = "START_NEXT_BATTLE_TIMER"
local DELAY_REQUEST_BATTLE_TIMER = "DELAY_REQUEST_BATTLE_TIMER"

-- 参数序号含义
local PARAM_INDEX_CONFIG =
{
    EnableAutoTest  = 2,
    ServerIndex     = 3,
    EnableGPerf     = 4,
    EnablePSO       = 5
}

local bInit = false
local EventHelper = nil

local bFirstTest = true

-- local bEnable = false
local nServerIdx = -1

local tbAllSubSystems = {}


local function GetSubSystem(szSystemName)
    return tbAllSubSystems[szSystemName]
end

local function ParseCommandLineParams()
    local szCmdLineStr = KismetSystemLibrary.GetCommandLine()
    log("GameTestAutomationSystemClient, ParseCommandLineParams, szCmdLineStr : ", szCmdLineStr)
    if not szCmdLineStr then
        return
    end
    szCmdLineStr = StringUtil.Trim(szCmdLineStr)
    if szCmdLineStr == "" then
        log("GameTestAutomationSystemClient, ParseCommandLineParams, szCmdLineStr is empty ")
        return
    end

    local tbComandParams = StringUtil.Split(szCmdLineStr, "-")
    for _, v in ipairs(tbComandParams) do
        if string.find(v, "testautomation") then
            local tbTestAutomationParams = StringUtil.Split(v, " ")
            if tonumber(tbTestAutomationParams[PARAM_INDEX_CONFIG.EnableAutoTest]) == 1 then
                log("GameTestAutomationSystemClient", "ParseCommandLineParams enable")
                GameTestAutomationVariables.bAutoTestEnable = true
                GameTestAutomationVariables.bBattleTestEnable = true
                GameTestAutomationLogHelper.EnableLog(true)
            else
                log("GameTestAutomationSystemClient", "ParseCommandLineParams disable",tbTestAutomationParams[2], tonumber(tbTestAutomationParams[2]))
                GameTestAutomationVariables.bAutoTestEnable = false
                GameTestAutomationVariables.bBattleTestEnable = false
            end
            nServerIdx = tonumber(tbTestAutomationParams[PARAM_INDEX_CONFIG.ServerIndex])

            if tonumber(tbTestAutomationParams[PARAM_INDEX_CONFIG.EnableGPerf]) == 1 then
                log("GameTestAutomationSystemClient", "ParseCommandLineParams use gperf true")
                GameTestAutomationVariables.bUseGPerf = true
            else
                log("GameTestAutomationSystemClient", "ParseCommandLineParams use gperf false")
                GameTestAutomationVariables.bUseGPerf = false
            end

            if tonumber(tbTestAutomationParams[PARAM_INDEX_CONFIG.EnablePSO]) == 1 then
                log("GameTestAutomationSystemClient", "ParseCommandLineParams use gperf true")
                GameTestAutomationVariables.bUsePSO = true
            else
                log("GameTestAutomationSystemClient", "ParseCommandLineParams use gperf false")
                GameTestAutomationVariables.bUsePSO = false
            end

            log("GameTestAutomationSystemClient", "ParseCommandLineParams ", tbTestAutomationParams[1], tbTestAutomationParams[2], tbTestAutomationParams[3])
            break
        end
    end
end

local function IsEnable()
    return GameTestAutomationVariables.bAutoTestEnable
end

local function OnShowLogin(self)
    log("GameTestAutomationSystemClient", "OnShowLogin")
    if IsEnable(self) then
        log("GameTestAutomationSystemClient", "OnShowLogin enable")
        local loginWnd = UIManager:GetWnd(UIDef.UI_LOGIN)
        if loginWnd ~= nil then
            local localServerData = loginWnd.tbListHelper.tbDataList[nServerIdx]
            if localServerData and localServerData.OnCheckedDelegate then
                localServerData.OnCheckedDelegate:Fire(localServerData)
            end
            loginWnd:OnClickedButtonDeviceLogin(false, false)
        else
            log("GameTestAutomationSystemClient", "loginWnd is nil")
        end
    end
end

local function OnShowCreateRole(self)
    log("GameTestAutomationSystemClient", "OnShowCreateRole")
    if IsEnable(self) then
        log("GameTestAutomationSystemClient", "OnShowCreateRole enable")
        local createRoleWnd = UIManager:GetWnd(UIDef.UI_CREATE_ROLE)
        if createRoleWnd then
            local pSkipGuide = createRoleWnd.pWidgetRef.checkBox_SkipGuide
            pSkipGuide:SetIsChecked(true);
            createRoleWnd:OnBtnCreateAvatarClicked()
        end
    end
end

local function InitAllBattleItem()
    local tbItemCategories = {}
    table.insert(tbItemCategories, ItemCategoryDef.SHIP)
    table.insert(tbItemCategories, ItemCategoryDef.SHIP_WEAPON)
    table.insert(tbItemCategories, ItemCategoryDef.SHIP_PART)
    GameTestAutomationBattleDataHelper:InitCandidateData(tbItemCategories)
end

local function RequestToAddAllItems()
    GameTestAutomationBattleDataHelper:RequestToAddAllShips()
    GameTestAutomationBattleDataHelper:RequestToAddAllShipWeapons()
    GameTestAutomationBattleDataHelper:RequestToAddAllShipParts()
end

local function PrepareAllBattleItem()
    InitAllBattleItem()
    RequestToAddAllItems()
end


local function PrepareNextBattleItem(self)
    local nTemplateId = GameTestAutomationBattleDataHelper:PickUpItemForBattle(ItemCategoryDef.SHIP)
    GameTestAutomationBattleDataHelper:RequestToEquipShip(nTemplateId, 1)
    nTemplateId = GameTestAutomationBattleDataHelper:PickUpItemForBattle(ItemCategoryDef.SHIP_WEAPON)
    GameTestAutomationBattleDataHelper:RequestToEquipShipWeapon(nTemplateId)
    nTemplateId = GameTestAutomationBattleDataHelper:PickUpItemForBattle(ItemCategoryDef.SHIP_PART)
    GameTestAutomationBattleDataHelper:RequestToEquipShipPart(nTemplateId)
end

local function RequestToStartBattle(self)
    local BattleTestSystem = GetSubSystem(BATTLE_TEST_AUTOMATION)
    BattleTestSystem:RequestToStartBattle()
end

local function StartBattle(self)
    PrepareNextBattleItem(self)
    Timer.StartOwnerTimer(self, DELAY_REQUEST_BATTLE_TIMER, function()
        RequestToStartBattle(self)
    end, 10 , false)
end

local function OnEnterLobby(self)
    log("GameTestAutomationSystemClient", "OnEnterLobby")
    if IsEnable(self) then
        log("GameTestAutomationSystemClient", "OnEnterLobby enable")
        if bFirstTest then
            KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "closeguide", nil)
            PrepareAllBattleItem()
            Timer.StartOwnerTimer(self, START_NEXT_BATTLE_TIMER, function()
                bFirstTest = false
                StartBattle(self)
            end, 30 , false)
        else
            Timer.StartOwnerTimer(self, START_NEXT_BATTLE_TIMER, function()
                GameTestAutomationVariables.bBattleTestEnable = true
                StartBattle(self)
            end, 30 , false)
        end
    end
end

local function DoRegisterSubSystem(szSystemName)
    local SubSystem = require(szSystemName)
    tbAllSubSystems[szSystemName] = SubSystem
end

local function RegisterSubSystems()
    DoRegisterSubSystem(BATTLE_TEST_AUTOMATION)
end

local function UnregisterSubSystems()
    tbAllSubSystems = {}
end

local function InitSubSystems()
    for _, v in pairs(tbAllSubSystems) do
        v:Init()
    end
end

local function UninitSubSystems()
    for _, v in pairs(tbAllSubSystems) do
        v:Uninit()
    end
end

function GameTestAutomationSystemClient:StartBattleAutoTest()
    local BattleTestSystem = GetSubSystem(BATTLE_TEST_AUTOMATION)
    BattleTestSystem:StartBattleAutoTest()
end

function GameTestAutomationSystemClient:StopBattleAutoTest()
    local BattleTestSystem = GetSubSystem(BATTLE_TEST_AUTOMATION)
    BattleTestSystem:StopBattleAutoTest()
end

function GameTestAutomationSystemClient:Init()
    if not bInit then
        ParseCommandLineParams()
        RegisterSubSystems()
        InitSubSystems()
        EventHelper = SelfEventHelper()

        self.tbCompositeEventHandle = EventHelper:BeginCompositeAndEvent(self, OnShowLogin, nil)
        EventHelper:RegisterEvent(ClientEventDef.EV_LOGIN_SERVER_INFO_COMPLETED, self, nil)
        EventHelper:RegisterEvent(ClientEventDef.EV_SHOW_LOGIN, self, nil)
        EventHelper:EndCompositeEvent()
        EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_READY, self, OnEnterLobby)
        EventHelper:RegisterEvent(ClientEventDef.EV_SHOW_CREATE_ROLE, self, OnShowCreateRole)
        bInit = true
    end
end

function GameTestAutomationSystemClient:Uninit()
    if bInit then
        if self.tbCompositeEventHandle then
            EventHelper:UnRegisterComposite(self.tbCompositeEventHandle)
            self.tbCompositeEventHandle = nil
        end
        UninitSubSystems()
        UnregisterSubSystems()
        Timer.StopOwnerTimer(self, START_NEXT_BATTLE_TIMER)
        EventHelper:UnregisterAll()
        EventHelper = nil
        bInit = false
    end
end

return GameTestAutomationSystemClient