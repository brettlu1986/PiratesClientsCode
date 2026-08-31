local ServerEventDef = {}

-- Common消息从1000 - 9999
-- Client消息从10000 - 49999
-- Server消息从50000 - 99999

--local nNextEventId = 50000
-- local function Define(szEventName)
--     ServerEventDef[szEventName] = nNextEventId
--     nNextEventId = nNextEventId + 1
-- end

function ServerEventDef.Init()    
end


ServerEventDef.Init()

return ServerEventDef