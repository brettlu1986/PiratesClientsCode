local OtherExporterRegisterClient = {}

function OtherExporterRegisterClient:Register(Exporter)
    -- 这玩意应该也没用了
    Exporter:Register("NoobParachutingJsonTable")
    Exporter:Register("FFAMapPointJsonTable")
    Exporter:Register("HumanWeaponDefaultDataTable")
end

return OtherExporterRegisterClient