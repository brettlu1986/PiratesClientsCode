local CopyFileRegisterClient = {}

function CopyFileRegisterClient:Register(Exporter)
    Exporter:RegisterFile("protos/client2.pb")

    Exporter:RegisterFolder("common/version")
    Exporter:RegisterFolder("client/url")
end

return CopyFileRegisterClient