local UEMapLoader = {}

function UEMapLoader:LoadMapAsync(szMapURL)   
    ClientShell.GetClient(GWorld):OpenLevelAsync(szMapURL)
end

function UEMapLoader:LoadMap(szMapURL, bAbsolute, szOptions)
    GameplayStatics.OpenLevel(GWorld, szMapURL, bAbsolute, szOptions)
end

function UEMapLoader:CancelPendingNetGame()
    ClientShell.GetClient(GWorld):GetDungeonShell():CancelPendingNetGame(GWorld)
end

function UEMapLoader:LoadSubLevelSync(szLevelPath)
    local pSubLevel = ExtendBlueprintFunctions.LoadSublevelSyncDynamic(GWorld, szLevelPath, Vector(), Rotator())
    if not pSubLevel then 
        return nil 
    end 
    ExtendBlueprintFunctions.SetLevelClientOnlyVisible(pSubLevel, true)
    return pSubLevel
end 

function UEMapLoader:UnLoadSubLevel(szLevelPath)
    if szLevelPath then 
        ExtendBlueprintFunctions.UnloadSubLevelDynamic(GWorld, szLevelPath)
    end
end 


return UEMapLoader
