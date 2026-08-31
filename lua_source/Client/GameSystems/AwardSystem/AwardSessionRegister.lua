local AwardSessionRegister = {}

local AwardSessionType = require("AwardSessionType")

function AwardSessionRegister:Register(AwardSessionSystem)
    local T = AwardSessionType
    AwardSessionSystem:Register(T.CommonAwardSession,       "CommonAwardSession")
    AwardSessionSystem:Register(T.SeasonAwardSession,       "SeasonAwardSession")
    AwardSessionSystem:Register(T.SeasonResultAwardSession, "SeasonResultAwardSession")
    AwardSessionSystem:Register(T.BuyAwardSession,          "BuyAwardSession")
    AwardSessionSystem:Register(T.ScheduleRouletteAwardSession, "ScheduleRouletteAwardSession")
end

return AwardSessionRegister