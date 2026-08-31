local DescriptorRegisterClient = {}

function DescriptorRegisterClient:Register(Exporter)
    Exporter:Register("NpcInstanceDescriptor")
    Exporter:Register("ShipShowDescriptor")
    Exporter:Register("GatherPointDescriptor")
    Exporter:Register("AtmospherePathNodeDescriptor")
    Exporter:Register("TeleportPointDescriptor")
    Exporter:Register("CameraShotTriggerDescriptor")
    Exporter:Register("FFAMapPointDescriptor")
    Exporter:Register("HomelandDescriptor")
    Exporter:Register("MapPointDescriptor")
    Exporter:Register("HomelandHQPlayerStartDescriptor")
    Exporter:Register("HomelandShipPositionDescriptor")
end

return DescriptorRegisterClient