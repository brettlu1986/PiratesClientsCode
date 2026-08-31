local GameCoreSDKAnalysis = {}

GameCoreSDKAnalysis.nWindowTime = 1
GameCoreSDKAnalysis.nTotalCommand = 0
GameCoreSDKAnalysis.nMaxCommandPerWindowTime = 0
GameCoreSDKAnalysis.nCommandPerWindowTime = 0
GameCoreSDKAnalysis.nEplasedTime = 0
GameCoreSDKAnalysis.nLastRecordTime = 0
GameCoreSDKAnalysis.tbMessages = nil

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCoreSDKAnalysis:", ...)
end
-- luacheck: pop

local self = GameCoreSDKAnalysis


function GameCoreSDKAnalysis.Record(szMessageType)
    local nTime = os.time()
    self.nEplasedTime = self.nEplasedTime + nTime - self.nLastRecordTime
    self.nLastRecordTime = nTime
    if self.nEplasedTime > self.nWindowTime then
        if self.nCommandPerWindowTime > self.nMaxCommandPerWindowTime then
            self.nMaxCommandPerWindowTime = self.nCommandPerWindowTime
        end
        LOG("recv ai adk command " .. self.nCommandPerWindowTime .. " in " .. self.nWindowTime .. " seconds")
        self.nEplasedTime = 0
        self.nCommandPerWindowTime = 0
        GameCoreSDKAnalysis.Print()
    end
    self.nCommandPerWindowTime = self.nCommandPerWindowTime + 1
    self.nTotalCommand = self.nTotalCommand + 1
    local nCount = self.tbMessages[szMessageType] or 0
    self.tbMessages[szMessageType] =  nCount + 1
end

function GameCoreSDKAnalysis.Reset()
    self.nTotalCommand = 0
    self.nMaxCommandPerWindowTime = 0
    self.nCommandPerWindowTime = 0
    self.nEplasedTime = 0
    self.nLastRecordTime = 0
    self.tbMessages = {}
end

local function ConvertTableToJsonString(tbToPrint)
    local json = require("dkjson")
    return json.encode(tbToPrint, { indent = true })
end

function GameCoreSDKAnalysis.Print()
    LOG("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")
    log(ConvertTableToJsonString(self.tbMessages))
    LOG("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")
    for k,v in pairs(self.tbMessages) do
        self.tbMessages[k] = nil
    end
end

return GameCoreSDKAnalysis