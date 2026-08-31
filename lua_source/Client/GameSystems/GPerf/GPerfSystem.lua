-----------------------------------------------------
--File Name    : GPerfSystem.lua
--Author       : WuJizhou
--Create Time  : 11/15/2019, 3:15:09 PM
--Description  : GPerfSystem
-----------------------------------------------------

local GPerfSystem = {}

local CommonEventDef        = require("CommonEventDef")
local ClientEventDef        = require("ClientEventDef")
local SelfEventHelper       = require("SelfEventHelper")
-- local GameObjectTypeDef     = require("GameObjectTypeDef")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
local BattleGameModeSystem  = dynamic_require("BattleGameModeSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")


local LOG_UPLOADING_MODE_DEFAULT    = 0
local LOG_UPLOADING_MODE_MANUAL     = 1
local LOG_UPLOADING_MODE_AUTOMATIC  = 2

local szCurrentSessionId = nil

GPerfSystem.bEnterBattle = false
GPerfSystem.bRetraveling = false
GPerfSystem.bEnable = false
GPerfSystem.bStartWithAutoFinished = false
GPerfSystem.bOver = false
GPerfSystem.nGPerfStartTime = 0
GPerfSystem.nLastUploadLogTime = 0
GPerfSystem.nLogUploadingMode = LOG_UPLOADING_MODE_DEFAULT

local EventHelper = nil

local function InitMisc(self)
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, string.format("gperf app -version=%s", UpdateProcedure.GetAppVersion()), nil)
end


-- local function AutoFinishedWhenSelfDead(self, tbDeadActor)
--     if tbDeadActor and tbDeadActor.ObjectType == GameObjectTypeDef.PlayerSelf then
--         self:Stop()
--         self:Upload()
--         EventHelper:UnregisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD)
--         EventHelper:UnregisterEvent(ClientEventDef.EV_FFA_RESULT)
--         self.bStartWithAutoFinished = false
--     end
-- end

-- local function AutoFinishedWhenChickenChicken(self, tbPacket)
--     if tbPacket.bTeamDead and tbPacket.nTeamRank == 1 then
--         self:Stop()
--         self:Upload()
--         EventHelper:UnregisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD)
--         EventHelper:UnregisterEvent(ClientEventDef.EV_FFA_RESULT)
--         self.bStartWithAutoFinished = false
--     end
-- end

-- local function OnParachutionEnd(self)
--     if self:IsEnable() then
--         szCurrentSessionId = BattleGameModeSystem:GetDungeonSessionId()
--         GPerfShell.SetTag("dungeon_session_id", szCurrentSessionId)
--         self:Start(true)
--     end
-- end

local function OnGameOver(self)
    if GlobalVariableSystem:IsStandalone() then
        log("GPerfSystem", "OnGameOver, IsStandalone")
        return
    end

    if self:IsEnable() then
        self:Stop()
        self:Upload()
    end
    self.bOver = true
end

local function OnEnterBattle(self, bRetraveling, bStandalone)
    log("GPerfSystem", "OnEnterBattle, bRetraveling", bRetraveling, bStandalone)
    self.bRetraveling = bRetraveling
    self.bEnterBattle = true
end

local function OnLoadingComplete(self)
    log("GPerfSystem", "OnLoadingComplete")
    if GlobalVariableSystem:IsStandalone() then
        log("GPerfSystem", "OnLoadingComplete, IsStandalone")
        return
    end
    if not self.bEnterBattle then
        return
    end

    if self.bRetraveling then
        return
    end
    if self:IsEnable() then
        -- self:AutoUploadLog()
        szCurrentSessionId = BattleGameModeSystem:GetDungeonSessionId()
        GPerfShell.SetTag("dungeon_session_id", szCurrentSessionId)
        self:Start(true)
        self.bOver = false
    end
end

local function OnLeaveBattle(self, bRetraveling)
    log("GPerfSystem", "OnLeaveBattle, bRetraveling", bRetraveling)
    if GlobalVariableSystem:IsStandalone() then
        log("GPerfSystem", "OnLeaveBattle, IsStandalone")
        return
    end
    self.bEnterBattle = false
    if bRetraveling then
        return
    end
    if self.bOver then
        if self:IsAutomaticUploadingMode() then
            log("-------- GPerf Split --------")
        end
        return
    end
    if self:IsEnable() then
        self:Stop()
        self:Upload()
    end

end

-- local function OnPawnDead(self, tbDeadActor)
--     if self:IsEnable() and tbDeadActor and tbDeadActor.ObjectType == GameObjectTypeDef.PlayerSelf then
--         self:Stop()
--         self:Upload()
--     end
-- end

function GPerfSystem:IsEnable()
    return self.bEnable
end

function GPerfSystem:EnableByIntValue(nEnableValue)
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, string.format("gperf init -enable=%d", nEnableValue), nil)
    if nEnableValue == 1 then
        self.bEnable = true
        InitMisc(self)
    else
        self.bEnable = false
    end
end

function GPerfSystem:Enable(bEnable)
    log("GPerfSystem", "Enable", bEnable)
    local nValue = 0
    if bEnable then
        nValue = 1
    end
    self:EnableByIntValue(nValue)
end

function GPerfSystem:SetUrl(szPreUrl, szUrl)
    log("GPerfSystem", string.format("SetUrl %s %s", szPreUrl, szUrl))
    local szCmd = string.format("gperf init -preurl=%s -url=%s", szPreUrl, szUrl)
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, szCmd, nil)
end

-- function GPerfSystem:StartWithFinishedBySelfDead(bShow)
--     if self.bEnable then
--         if not self.bStartWithAutoFinished then
--             self:Start(bShow)
--             EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, AutoFinishedWhenSelfDead)
--             EventHelper:RegisterEvent(ClientEventDef.EV_FFA_RESULT, self, AutoFinishedWhenChickenChicken)
--             self.bStartWithAutoFinished = true
--         end
--     else
--         logerror("GPerfSystem Start", "GPerfSystem is not enable")
--     end
-- end

function GPerfSystem:Start(bShow)
    if self.bEnable then
        if bShow then
            KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "gperf start -show=1", nil)
        else
            KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "gperf start", nil)
        end

        local GamePlayer = GamePlayerSelfHelper:Get()
        KismetSystemLibrary.ExecuteConsoleCommand(GWorld, string.format("gperf tag -key=player_id -value=%d", GamePlayer.nPlayerId), nil)
        KismetSystemLibrary.ExecuteConsoleCommand(GWorld, string.format("gperf tag -key=player_name -value=%s", GamePlayer.szName), nil)
        KismetSystemLibrary.ExecuteConsoleCommand(GWorld, string.format("gperf tag -key=dungeon_id -value=%s", BattleGameModeSystem.nDungeonId), nil)
    else
        logerror("GPerfSystem Start", "GPerfSystem is not enable")
    end
end

function GPerfSystem:Stop()
    if self.bEnable then
        KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "gperf stop", nil)
    else
        logerror("GPerfSystem Stop", "GPerfSystem is not enable")
    end
end

function GPerfSystem:Upload()
    if self.bEnable then
        KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "gperf upload", nil)
        if self:IsAutomaticUploadingMode() then
            self.nLastUploadLogTime = getseconds()
        end
    else
        logerror("GPerfSystem Upload", "GPerfSystem is not enable")
    end
end

function GPerfSystem:ManualUploadLog()
    log("[GPerfSystem] Trigger ManualUploadLog")
    if self.bEnable then
        if self:IsManualUploadingMode() then
            log("[GPerfSystem] ManualUploadLog")
            -- 手动上传日志时间从GPerf启动算起
            local nElapsedTime = math.ceil(getseconds() - self.nGPerfStartTime)
            local GamePlayer = GamePlayerSelfHelper:Get()
            KismetSystemLibrary.ExecuteConsoleCommand(GWorld, string.format("gperf tag -key=player_id -value=%d", GamePlayer.nPlayerId), nil)
            KismetSystemLibrary.ExecuteConsoleCommand(GWorld, string.format("gperf tag -key=player_name -value=%s", GamePlayer.szName), nil)
            KismetSystemLibrary.ExecuteConsoleCommand(GWorld, string.format("gperf tag -key=dungeon_id -value=%s", "Manual"), nil)
            KismetSystemLibrary.ExecuteConsoleCommand(GWorld, string.format("gperf manualuploadlog -time=%d", nElapsedTime), nil)
            -- 上传之后需要把DungeonId设回去
            KismetSystemLibrary.ExecuteConsoleCommand(GWorld, string.format("gperf tag -key=dungeon_id -value=%s", BattleGameModeSystem.nDungeonId), nil)
        else
            logerror("GPerfSystem ManualUploadLog", "GPerfSystem is not manual uploading mode")
        end
    else
        logerror("GPerfSystem ManualUploadLog", "GPerfSystem is not enable")
    end
end

-- function GPerfSystem:AutoUploadLog()
--     log("[GPerfSystem] Trigger AutoUploadLog")
--     if self.bEnable then
--         if self:IsAutomaticUploadingMode() then
--             log("[GPerfSystem] AutoUploadLog")
--             local nCurrentTime = getseconds()
--             -- 自动上传日志时间从上次上传算起
--             local nElapsedTime = math.ceil(nCurrentTime - ((self.nLastUploadLogTime > 0) and self.nLastUploadLogTime or self.nGPerfStartTime))
--             local GamePlayer = GamePlayerSelfHelper:Get()
--             KismetSystemLibrary.ExecuteConsoleCommand(GWorld, string.format("gperf tag -key=player_id -value=%d", GamePlayer.nPlayerId), nil)
--             KismetSystemLibrary.ExecuteConsoleCommand(GWorld, string.format("gperf tag -key=player_name -value=%s", GamePlayer.szName), nil)
--             KismetSystemLibrary.ExecuteConsoleCommand(GWorld, string.format("gperf tag -key=dungeon_id -value=%s", "Lobby"), nil)
--             KismetSystemLibrary.ExecuteConsoleCommand(GWorld, string.format("gperf manualuploadlog -time=%d", nElapsedTime), nil)
--             self.nLastUploadLogTime = nCurrentTime
--         end
--     else
--         logerror("GPerfSystem ManualUploadLog", "GPerfSystem is not enable")
--     end
-- end

function GPerfSystem:SetLogUploadingMode(nInLogUploadingMode)
    log("[GPerfSystem] SetGPerfLogUploadingMode", nInLogUploadingMode)
    self.nLogUploadingMode = nInLogUploadingMode
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, string.format("gperf setloguploadingmode -mode=%d", nInLogUploadingMode), nil)
end

function GPerfSystem:SetLogUploadingModeByString(szInLogUploadingMode)
    log("[GPerfSystem] SetLogUploadingModeByString", szInLogUploadingMode)
    local nLogUploadingMode = LOG_UPLOADING_MODE_DEFAULT
    if szInLogUploadingMode == "manual" then
        nLogUploadingMode = LOG_UPLOADING_MODE_MANUAL
    elseif szInLogUploadingMode == "automatic" then
        nLogUploadingMode = LOG_UPLOADING_MODE_AUTOMATIC
    end
    self:SetLogUploadingMode(nLogUploadingMode)
end

function GPerfSystem:IsManualUploadingMode()
    return self.nLogUploadingMode == LOG_UPLOADING_MODE_MANUAL
end

function GPerfSystem:IsAutomaticUploadingMode()
    return self.nLogUploadingMode == LOG_UPLOADING_MODE_AUTOMATIC
end

function GPerfSystem:Init()
    log("GPerfSystem", "Init")
    self.bRetraveling = false
    self.bOver = false
    self.nGPerfStartTime = getseconds()
    EventHelper = SelfEventHelper()
    -- EventHelper:RegisterEvent(ClientEventDef.EV_FFA_PARACHUTION_END, self, OnParachutionEnd)
    -- EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnPawnDead)
    EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE, self, OnEnterBattle)
    EventHelper:RegisterEvent(ClientEventDef.EV_EXIT_LOADING, self, OnLoadingComplete)

    EventHelper:RegisterEvent(CommonEventDef.EV_DUNGEON_GAME_OVER, self, OnGameOver)
    EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_BATTLE, self, OnLeaveBattle)
    self.bStartWithAutoFinished = false
    return true
end

function GPerfSystem:Uninit()
    log("GPerfSystem", "Uninit")
    EventHelper:UnregisterAll()
    EventHelper = nil
    self.bRetraveling = false
    return true
end

return GPerfSystem