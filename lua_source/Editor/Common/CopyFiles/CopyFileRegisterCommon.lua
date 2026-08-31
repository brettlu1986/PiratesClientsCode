local CopyFileRegisterCommon = {}

function CopyFileRegisterCommon:Register(Exporter)
    Exporter:RegisterFile("common/res/scene_res.tab")
    Exporter:RegisterFile("common/dungeon/dungeon.tab")
    Exporter:RegisterFile("common/dungeon/dungeon_mode.tab")
    Exporter:RegisterFolder("common/res/part")
    -- 这俩因为有重定向的需求，所以挪到CopyFileWithSceneRedirection里了
    -- Exporter:RegisterFolder("common/navigation")
    -- Exporter:RegisterFolder("common/gridtype")
    Exporter:RegisterFolder("common/engineconfig")
    Exporter:RegisterFolder("common/ai")
    Exporter:RegisterFolder("common/scene/land_id_name")
    Exporter:RegisterFile("common/sensitivewords/sensitivewords.txt")
end

return CopyFileRegisterCommon