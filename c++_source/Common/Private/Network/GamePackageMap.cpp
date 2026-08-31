
#include "Network/GamePackageMap.h"
#include "Common.h"
#include "Game/GameCommon.h"
#include "Shell/CommonShell.h"
#include "PiratesLocalPlayer.h"

#include "GameActorChannel.h"
#include "UObject/UObjectThreadContext.h"

DEFINE_LOG_CATEGORY_STATIC(GamePackageMapLog, Log, All);

//enum ESmoothTravelActorFlag
//{
//    Default = 0,
//    PlayerController,
//    PlayerPawn,
//};

/**
* Default constructor
*/
UGamePackageMap::UGamePackageMap(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{
}
//
//bool UGamePackageMap::SerializeNewActor(FArchive& Ar, class UActorChannel* Channel, class AActor*& Actor)
//{
//    bool bActorWasSpawned = false;
//    bool bSmoothTravel = false;
//    auto Controller = GWorld->GetFirstPlayerController();
//    auto LocalPlayer = Cast<UPiratesLocalPlayer>(Controller->GetLocalPlayer());
//    if (Ar.IsLoading())
//    {
//        bSmoothTravel = LocalPlayer ? LocalPlayer->InSmoothTravel() : false;
//    }
//
//    //Add extra flag to mark actor type to help achieve smooth travel.
//    uint32 ActorFlag = ESmoothTravelActorFlag::Default;
//    if (Ar.IsSaving())
//    {
//        if (Actor->IsA(APlayerController::StaticClass()))
//        {
//            UE_LOG(GamePackageMapLog, Log, TEXT("UGamePackageMap::SerializeNewActor PlayerController"));
//            ActorFlag = ESmoothTravelActorFlag::PlayerController;
//        }
//        else
//        {
//            auto Pawn = Cast<APawn>(Actor);
//            if (Pawn && Pawn->IsControlled()
//                && Pawn->GetNetConnection() == Channel->Connection)
//            {
//                UE_LOG(GamePackageMapLog, Log, TEXT("UGamePackageMap::SerializeNewActor Controlled pawn"));
//                ActorFlag = ESmoothTravelActorFlag::PlayerPawn;
//            }
//            else if (Pawn)
//            {
//                UE_LOG(GamePackageMapLog, Log, TEXT("UGamePackageMap::SerializeNewActor Non controlled pawn"));
//            }
//        }
//        Ar << ActorFlag;
//    }
//    else if (Ar.IsLoading())
//    {
//        Ar << ActorFlag;
//    }
//
//    bActorWasSpawned = Super::SerializeNewActor(Ar, Channel, Actor);
//    
//    if (Ar.IsLoading() && ActorFlag != ESmoothTravelActorFlag::Default && bSmoothTravel)
//    {
//        if (ActorFlag == ESmoothTravelActorFlag::PlayerController)
//        {
//            UE_LOG(GamePackageMapLog, Log, TEXT("UGamePackageMap::SerializeNewActor client player controller"));
//        }
//        else if (ActorFlag == ESmoothTravelActorFlag::PlayerPawn)
//        {
//            UE_LOG(GamePackageMapLog, Log, TEXT("UGamePackageMap::SerializeNewActor client player pawn"));
//            Actor->SetActorHiddenInGame(true);
//        }
//    }
//    return bActorWasSpawned;
//}

//bool UGamePackageMap::SerializeNewActor(FArchive& Ar, UActorChannel* Channel, AActor*& Actor)
//{
//    bool IsActorSpawned = Super::SerializeNewActor(Ar, Channel, Actor);
//    if (!IsActorSpawned)
//    {
//        if (auto GameActorChannel = Cast<UGameActorChannel>(Channel))
//        {
//            return Actor != nullptr && !GameActorChannel->IsComponentDataSerializerUsed() && !Actor->HasActorBegunPlay();
//        }
//    }
//    
//    return IsActorSpawned;
//}