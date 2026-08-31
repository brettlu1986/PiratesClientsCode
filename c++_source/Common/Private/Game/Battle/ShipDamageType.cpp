
#include "Game/Battle/ShipDamageType.h"
#include "Common.h"
#include "Game/GameCommon.h"
#include "Game/Delegates/GameDelegateManager.h"
//#include "DataTableDelegate.h"

UWorld* UShipDamageType::GetWorld() const
{
    UObject *Outer = GetOuter();
    UWorld *World = nullptr;
    if (!HasAnyFlags(RF_ClassDefaultObject))
    {
        if (!IsValid(Outer))
        {
            UE_LOG(LogTemp, Warning, TEXT("Invalid Outer, use GWorld for object:%s."), *GetName());
        }
        else if (!(Outer->HasAnyFlags(RF_BeginDestroyed) || Outer->IsUnreachable()))
        {
            World = Outer->GetWorld();
            if (!IsValid(World))
            {
                World = nullptr;
#if !WITH_EDITOR && UE_BUILD_SHIPPING
                World = GWorld.GetReference(); // 在非PIE中且是发行版中， 如果无法从Outer获得World，则使用GWorld，此时GWorld不会受PIE影响，万一代码有Bug，也不至于导致宕机等后果
#endif
                UE_LOG(LogTemp, Warning, TEXT("%s's outer cannot provide a valid World."), *GetName());
            }
        }
    }
    return World;
}