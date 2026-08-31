local SyncDataRegisterRealPlayer = {}

function SyncDataRegisterRealPlayer:Register(tbGameCoreSyncSystem)
    tbGameCoreSyncSystem:Register("SyncDataPlayerBaseState")
    tbGameCoreSyncSystem:Register("SyncDataVisiblePlayer")
end


return SyncDataRegisterRealPlayer