local LogEventSystem = {}

local SelfEventHelper = require("SelfEventHelper")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

LogEventSystem.tbSubOpList = nil
LogEventSystem.EventHelper = nil
LogEventSystem.tbParam     = nil

function LogEventSystem:Register(szSubOpName)
    local SubOpClass = dynamic_require(szSubOpName)
    if SubOpClass == nil then
        error("szSubOpName not found! "..szSubOpName)
    end
    local Instance = SubOpClass()
    Instance.tbParam = self.tbParam
    Instance:Init()
    table.insert(self.tbSubOpList, Instance)
    return Instance
end

local function UnRegisterAll(self)
    local tbSubOpList = self.tbSubOpList
    for nIndex = #tbSubOpList, 1, -1 do
        tbSubOpList[nIndex]:Uninit()
    end

    self.tbSubOpList = nil
end

function LogEventSystem:OnBattleBegin()
    self.tbParam.szDungeonUuid    = BattleGameModeSystem:GetDungeonSessionId()
    self.tbParam.nBattleBeginTime = GlobalVariableSystem:GetLocalTime()
    self.tbParam.bIsBattleBegin   = true

    for _, Instance in ipairs(self.tbSubOpList) do
        Instance:OnBattleBegin()
    end
end

function LogEventSystem:OnBattleEnd()
    --逆序执行OnBattleEnd.保证第一次注册的第一次调用OnBattleBegin，最后一次调用OnBattleEnd.
    local nCount = #self.tbSubOpList
    for nIndex = nCount, 1, -1 do
        self.tbSubOpList[nIndex]:OnBattleEnd()
    end

    -- self.tbParam.bIsBattleBegin = false
end

function LogEventSystem:Init()
    self.tbSubOpList = {}
    local tbParam = {}
    tbParam.szDungeonUuid = ""
    tbParam.nBattleBeginTime = 0
    tbParam.bIsBattleBegin = false
    self.tbParam = tbParam

    self.EventHelper = SelfEventHelper()

    dynamic_require("LogEventRegister"):Register(self)
end

function LogEventSystem:Uninit()
    UnRegisterAll(self)
    self.EventHelper:UnregisterAll()
    self.tbSubOpList = nil
    self.tbParam = nil
end

return LogEventSystem