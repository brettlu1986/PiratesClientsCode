local CopyFileRegisterServer = {}

function CopyFileRegisterServer:Register(Exporter)
    Exporter:RegisterFile("protos/dungeon.pb")
    Exporter:RegisterFile("protos/dungeon_analytics.pb")
    Exporter:RegisterFile("protos/gamecore.pb")
end

return CopyFileRegisterServer