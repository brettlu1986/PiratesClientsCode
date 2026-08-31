local GameDayIni = {}
GameDayIni.szFileName = "common/time/gameday.ini"


function GameDayIni:OnParse(Parser)
    self.nResetHour  = Parser:Get("game_day", "reset_hour"          , -1, Parser.TypeNumber)
    self.nResetWeek  = Parser:Get("game_week", "reset_day"          , -1, Parser.TypeNumber)
end

return GameDayIni