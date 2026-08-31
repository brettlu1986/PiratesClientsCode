local SyncDataRegisterBot = {}

function SyncDataRegisterBot:Register(tbGameCoreSyncSystem)
    tbGameCoreSyncSystem:Register("SyncDataPlayerBaseState")
    tbGameCoreSyncSystem:Register("SyncDataBackpack")
    tbGameCoreSyncSystem:Register("SyncDataBuildlist")
    tbGameCoreSyncSystem:Register("SyncDataShipArmor")
    tbGameCoreSyncSystem:Register("SyncDataShipWeapons")
    tbGameCoreSyncSystem:Register("SyncDataHumanArmor")
    tbGameCoreSyncSystem:Register("SyncDataHumanWeapons")
    tbGameCoreSyncSystem:Register("SyncDataVisiblePlayer")
    tbGameCoreSyncSystem:Register("SyncDataVisibleItems")
    tbGameCoreSyncSystem:Register("SyncDataVehicleState")
    tbGameCoreSyncSystem:Register("SyncDataCamera")
    tbGameCoreSyncSystem:Register("SyncDataSounds")
    tbGameCoreSyncSystem:Register("SyncDataTrivialData")
    tbGameCoreSyncSystem:Register("SyncDataShipMovementState")
    tbGameCoreSyncSystem:Register("SyncDataThrownWeaponState")
    tbGameCoreSyncSystem:Register("SyncDataDamages")
    tbGameCoreSyncSystem:Register("SyncDataVisibleTorpedo")
    tbGameCoreSyncSystem:Register("SyncDataSmokes")
end


return SyncDataRegisterBot