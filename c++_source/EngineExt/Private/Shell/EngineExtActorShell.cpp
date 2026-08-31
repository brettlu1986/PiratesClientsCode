
#include "Shell/EngineExtActorShell.h"
#include "EngineExt.h"
#include "Game/GameEngineExt.h"
//#include "ScriptActorComponent.h"
#include "Kismet/GameplayStatics.h"
#include "Game/Delegates/KMDelegateManager.h"
#include "Game/Delegates/ActorDelegate.h"
#include "Components/SkinnedMeshComponent.h"
#include "Engine/SkeletalMeshSocket.h"
#include <SocketSubsystem.h>
#include <IPAddress.h>
#include "Shell/EngineExtShell.h"

DECLARE_STATS_GROUP(TEXT("GameSpawnActor"), STATGROUP_GameSpawnActor, STATCAT_Advanced);
DEFINE_LOG_CATEGORY_STATIC(UEngineExtActorShellLog, Log, All)


void UEngineExtActorShell::SetActorLocation(AActor* Actor, const FVector& Position)
{
    if (Actor)
    {
        Actor->SetActorLocation(Position);
    }
}

void UEngineExtActorShell::SetActorLocationXYZ(AActor* Actor, float X, float Y, float Z)
{
    if (Actor)
    {
        Actor->SetActorLocation(FVector(X, Y, Z));
    }
}

FVector UEngineExtActorShell::GetActorLocation(AActor* Actor)
{
    if (Actor)
    {
        return Actor->GetActorLocation();
    }
    return FVector::ZeroVector;
}

void UEngineExtActorShell::GetActorLocationXYZ(AActor* Actor, float& X, float& Y, float& Z)
{
    FVector Location = GetActorLocation(Actor);
    X = Location.X;
    Y = Location.Y;
    Z = Location.Z;
}

void UEngineExtActorShell::SetActorRotation(AActor* Actor, const FRotator& Rotation)
{
    if (Actor)
    {
        Actor->SetActorRotation(Rotation);
    }
}

void UEngineExtActorShell::SetActorRotationYawPitchRoll(AActor* Actor, float Yaw, float Pitch, float Roll)
{
    if (Actor)
    {
        Actor->SetActorRotation(FRotator(Pitch, Yaw, Roll));
    }
}

FRotator UEngineExtActorShell::GetActorRotation(AActor* Actor)
{
    if (Actor)
    {
        return Actor->GetActorRotation();
    }
    return FRotator::ZeroRotator;
}

void UEngineExtActorShell::GetActorRotationYawPitchRoll(AActor* Actor, float& Yaw, float& Pitch, float& Roll)
{
    FRotator Rotator = GetActorRotation(Actor);
    Yaw = Rotator.Yaw;
    Pitch = Rotator.Pitch;
    Roll = Rotator.Roll;
}

void UEngineExtActorShell::SetActorScale(AActor* Actor, float Scale)
{
    if (Actor)
    {
        Actor->SetActorScale3D(FVector(Scale, Scale, Scale));
    }
}

void UEngineExtActorShell::SetActorScale3D(AActor* Actor, const FVector& Scale)
{
    if (Actor)
    {
        Actor->SetActorScale3D(Scale);
    }
}

FVector UEngineExtActorShell::GetActorScale3D(AActor* Actor)
{
    if (Actor)
    {
        return Actor->GetActorScale();
    }
    return FVector(1.0f, 1.0f, 1.0f);
}

uint32 UEngineExtActorShell::GetActorUniqueId(AActor* Actor)
{
    return IsValid(Actor) ? Actor->GetUniqueID() : INDEX_NONE;
}

uint32 UEngineExtActorShell::GetActorNetGuid(AActor* Actor)
{
    if (IsValid(Actor))
    {
        if (Actor->GetNetDriver())
        {
            check(Actor->GetNetDriver()->GuidCache.IsValid());
            FNetworkGUID Guid = Actor->GetNetDriver()->GuidCache->GetOrAssignNetGUID(Actor);
            return Guid.Value;
        }
        return Actor->GetUniqueID();
    }
    return INDEX_NONE;
}

FRotator UEngineExtActorShell::GetRotatorFromVectors(const FVector& Vector1, const FVector& Vector2)
{
    FQuat Quat = FQuat::FindBetweenVectors(Vector1, Vector2);
    return Quat.Rotator();
}

bool UEngineExtActorShell::HasActorBegunPlay(AActor* Actor)
{
    return Actor && Actor->HasActorBegunPlay();
}

static bool EnableActorSpawnLog = false;
void UEngineExtActorShell::SetSpawnLogEnabled(bool bEnabled)
{
    EnableActorSpawnLog = bEnabled;
}

AActor* UEngineExtActorShell::SpawnActorWithoutTransform(UObject* WorldContextObject, TSubclassOf<AActor> UC, APawn* Instigator)
{
    FTransform Temp;
    return SpawnActorForScript(WorldContextObject, UC, Temp, Instigator);
}

AActor* UEngineExtActorShell::SpawnActorForScript_LR(UObject* WorldContextObject, TSubclassOf<AActor> UC, FVector const& Location, FRotator const& Rotation, APawn* Instigator)
{
    return SpawnActorForScript(WorldContextObject, UC, FTransform(Rotation, Location), Instigator);
}

AActor* UEngineExtActorShell::SpawnActorForScript(UObject* WorldContextObject, TSubclassOf<AActor> UC, const FTransform& SpawnTransform, APawn* Instigator)
{
    AActor* NewActor = nullptr;
    if (!IsValid(WorldContextObject))
    {
        UE_LOG(UEngineExtActorShellLog, Warning, TEXT("WorldContextObject is a nullptr or invalid"));
        return NewActor;
    }
    auto World = WorldContextObject->GetWorld();
    if (!IsValid(World))
    {
        UE_LOG(UEngineExtActorShellLog, Warning, TEXT("World is a nullptr or invalid"));
        return NewActor;
    }
    if (!IsValid(UC))
    {
        UE_LOG(UEngineExtActorShellLog, Warning, TEXT("Spawn Actor the param UC is a nullptr or invalid"));
        return NewActor;
    }

    if (EnableActorSpawnLog)
    {
        UE_LOG(UEngineExtActorShellLog, Log, TEXT("Spawn actor begin: %s"), *UC->GetName());
    }

#if STATS
    const TStatId StatId = FDynamicStats::CreateStatId<FStatGroup_STATGROUP_GameSpawnActor>(UC->GetFName());
    FScopeCycleCounter CycleCounter(StatId);
#endif

    const FVector& Location = SpawnTransform.GetLocation();
    const FRotator& Rotation = SpawnTransform.GetRotation().Rotator();
    FActorSpawnParameters SpawnParam;
    SpawnParam.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	SpawnParam.Instigator = Instigator;
    NewActor = World->SpawnActor(UC, &Location, &Rotation, SpawnParam);
    NewActor->SetActorScale3D(SpawnTransform.GetScale3D());

    if (EnableActorSpawnLog)
    {
        UE_LOG(UEngineExtActorShellLog, Log, TEXT("Spawn actor end: %s"), *NewActor->GetName());
    }

    return NewActor;
}

bool UEngineExtActorShell::MovePawnToSafeLocation(UObject* WorldContextObject, APawn* Pawn)
{
    if (Pawn == nullptr)
    {
        return false;
    }

    UWorld* World = WorldContextObject->GetWorld();
    if (World == nullptr)
    {
        return false;
    }

    int32 TEST_HALF_EXTENT = 7;

    UPrimitiveComponent* PrimitiveComp = Cast<UPrimitiveComponent>(Pawn->GetRootComponent());
    if (PrimitiveComp != nullptr)
    {
        FCollisionQueryParams QueryParams("ChangePawnToSafeLocation", false, Pawn);
        FCollisionResponseParams ResponseParams;
        PrimitiveComp->InitSweepCollisionParams(QueryParams, ResponseParams);

        ECollisionChannel BlockingChannel = PrimitiveComp->GetCollisionObjectType();
        FCollisionShape CollisionShape = PrimitiveComp->GetCollisionShape();
        FVector InitialLoc = PrimitiveComp->GetComponentLocation();
        FRotator InitialRot = PrimitiveComp->GetComponentRotation();
        FQuat InitialQuat = PrimitiveComp->GetComponentQuat();

        if (World->OverlapBlockingTestByChannel(InitialLoc, InitialQuat,
            BlockingChannel, CollisionShape, QueryParams, ResponseParams))
        {
            auto ComputeOffsetFunc = [](float InLength, float InYaw)
            {
                float Radian = FMath::DegreesToRadians(InYaw);
                return FVector(InLength * FMath::Cos(Radian), InLength * FMath::Sin(Radian), 0.f);
            };

            float BoxHeight = CollisionShape.Box.HalfExtentX * 2.5f;
            float BoxWidth = CollisionShape.Box.HalfExtentY * 2.5f;
            FVector LeftOffset = ComputeOffsetFunc(BoxWidth, InitialRot.Yaw - 90.f);
            FVector RightOffset = ComputeOffsetFunc(BoxWidth, InitialRot.Yaw + 90.f);
            FVector UpOffset = ComputeOffsetFunc(BoxHeight, InitialRot.Yaw);

            TMap<int32, FVector> TestLocMap;
            int32 TestAreaWidth = TEST_HALF_EXTENT * 2 + 1;
            int32 TestAreaHeight = TEST_HALF_EXTENT + 1;
            int32 MaxTestLocCount = TestAreaWidth * TestAreaHeight;

            TQueue<int32> TestQueue;
            auto EnqueueTestLocFun = [&](int32 InIndex, const FVector& InLoc)
            {
                if (InIndex > -1 && InIndex < MaxTestLocCount && !TestLocMap.Contains(InIndex))
                {
                    TestLocMap.Emplace(InIndex, InLoc);
                    TestQueue.Enqueue(InIndex);
                }
            };

            bool bBlocked = true;
            FVector CurrentTestLoc = InitialLoc;
            int32 CurrentIndex = TEST_HALF_EXTENT + TEST_HALF_EXTENT * TestAreaWidth;
            TestLocMap.Emplace(CurrentIndex, CurrentTestLoc);
            while (bBlocked)
            {
                EnqueueTestLocFun(CurrentIndex - TestAreaWidth, CurrentTestLoc + UpOffset);
                EnqueueTestLocFun(CurrentIndex - 1, CurrentTestLoc + LeftOffset);
                EnqueueTestLocFun(CurrentIndex + 1, CurrentTestLoc + RightOffset);

                if (TestQueue.Dequeue(CurrentIndex))
                {
                    CurrentTestLoc = TestLocMap[CurrentIndex];
                    bBlocked = World->OverlapBlockingTestByChannel(CurrentTestLoc, InitialQuat,
                        BlockingChannel, CollisionShape, QueryParams, ResponseParams);
                }
                else
                {
                    break;
                }
            }

            if (!bBlocked)
            {
                PrimitiveComp->SetWorldLocationAndRotation(CurrentTestLoc, InitialQuat, false, nullptr, ETeleportType::TeleportPhysics);
            }

            return !bBlocked;
        }

        return true;
    }

    return false;
}

bool UEngineExtActorShell::IsPawnLocationBlocked(UObject* WorldContextObject, APawn* Pawn)
{
    if (Pawn == nullptr)
    {
        return false;
    }

    UWorld* World = WorldContextObject->GetWorld();
    if (World == nullptr)
    {
        return false;
    }

    bool bBlocked = false;
    UPrimitiveComponent* PrimitiveComp = Cast<UPrimitiveComponent>(Pawn->GetRootComponent());
    if (PrimitiveComp != nullptr)
    {
        FCollisionQueryParams QueryParams("ChangePawnToSafeLocation", false, Pawn);
        FCollisionResponseParams ResponseParams;
        PrimitiveComp->InitSweepCollisionParams(QueryParams, ResponseParams);

        ECollisionChannel BlockingChannel = PrimitiveComp->GetCollisionObjectType();
        FCollisionShape CollisionShape = PrimitiveComp->GetCollisionShape();
        FVector InitialLoc = PrimitiveComp->GetComponentLocation();
        FRotator InitialRot = PrimitiveComp->GetComponentRotation();
        FQuat InitialQuat = PrimitiveComp->GetComponentQuat();

        bBlocked = World->OverlapBlockingTestByChannel(InitialLoc, InitialQuat,
            BlockingChannel, CollisionShape, QueryParams, ResponseParams);
    }

    return bBlocked;
}

bool UEngineExtActorShell::IsCanSafeTeleport(UObject* WorldContextObject, APawn* Pawn)
{
    if (Pawn == nullptr)
    {
        return false;
    }

    UWorld* World = WorldContextObject->GetWorld();
    if (World == nullptr)
    {
        return false;
    }

    bool bBlocked = false;
    UPrimitiveComponent* PrimitiveComp = Cast<UPrimitiveComponent>(Pawn->GetRootComponent());
    if (PrimitiveComp == nullptr)
    {
        return false;
    }

    FCollisionQueryParams QueryParams("ChangePawnToSafeLocation", false, Pawn);
    FCollisionResponseParams ResponseParams;
    PrimitiveComp->InitSweepCollisionParams(QueryParams, ResponseParams);

    ECollisionChannel BlockingChannel = PrimitiveComp->GetCollisionObjectType();
    FCollisionShape CollisionShape = PrimitiveComp->GetCollisionShape();
    FVector InitialLoc = PrimitiveComp->GetComponentLocation();
    FRotator InitialRot = PrimitiveComp->GetComponentRotation();
    FQuat InitialQuat = PrimitiveComp->GetComponentQuat();
    ResponseParams.CollisionResponse.SetResponse(ECC_GameTraceChannel3, ECR_Ignore);
    // this loc
    if (World->OverlapBlockingTestByChannel(InitialLoc, InitialQuat,
        BlockingChannel, CollisionShape, QueryParams, ResponseParams))
    {
        return true;
    }

    auto ComputeOffsetFunc = [](float InLength, float InYaw)
    {
        float Radian = FMath::DegreesToRadians(InYaw);
        return FVector(InLength * FMath::Cos(Radian), InLength * FMath::Sin(Radian), 0.f);
    };

    float BoxHeight = CollisionShape.Box.HalfExtentX * 2.5f;
    float BoxWidth = CollisionShape.Box.HalfExtentY * 2.5f;
    FVector LeftOffset = ComputeOffsetFunc(BoxWidth, InitialRot.Yaw - 90.f);
    FVector RightOffset = ComputeOffsetFunc(BoxWidth, InitialRot.Yaw + 90.f);
    FVector UpOffset = ComputeOffsetFunc(BoxHeight, InitialRot.Yaw);
    FVector CurrentTestLoc = InitialLoc;
    // up
    if (World->OverlapBlockingTestByChannel(CurrentTestLoc + UpOffset, InitialQuat,
        BlockingChannel, CollisionShape, QueryParams, ResponseParams))
    {
        return true;
    }
    // left and right
    if (World->OverlapBlockingTestByChannel(CurrentTestLoc + LeftOffset, InitialQuat, BlockingChannel, CollisionShape, QueryParams, ResponseParams)
        && World->OverlapBlockingTestByChannel(CurrentTestLoc + RightOffset, InitialQuat, BlockingChannel, CollisionShape, QueryParams, ResponseParams))
    {
        return true;
    }

    return bBlocked;
}

void UEngineExtActorShell::DestroyActor(UObject* WorldContextObject, AActor* Actor, bool bNetForce/* = false*/)
{
    if (!IsValid(WorldContextObject))
    {
        UE_LOG(UEngineExtActorShellLog, Warning, TEXT("WorldContextObject is a nullptr or invalid"));
        return;
    }
    auto World = WorldContextObject->GetWorld();
    if (!IsValid(World))
    {
        UE_LOG(UEngineExtActorShellLog, Warning, TEXT("World is a nullptr or invalid"));
        return;
    }
    if (!Actor || !IsValid(Actor) || !Actor->IsValidLowLevel())
    {
        return;
    }
    World->DestroyActor(Actor, bNetForce);
}

void UEngineExtActorShell::DestroyActorComponent(AActor* Actor, UActorComponent* Component)
{
    if (!Actor || !IsValid(Actor) || !Actor->IsValidLowLevel())
    {
        return;
    }
    if (!Component || !IsValid(Component) || !Component->IsValidLowLevel())
    {
        return;
    }
    Component->DestroyComponent();
}

FRotator UEngineExtActorShell::GetWorldRotationToTargetLocation(AActor* Actor, const FVector& TargetLocation)
{
    if (!Actor || !IsValid(Actor) || !Actor->IsValidLowLevel())
    {
        return FRotator();
    }

    FVector Dir = TargetLocation - Actor->GetActorLocation();
    FVector OrignalFace(1.0f, 0.0f, 0.0f);
    return GetRotatorFromVectors(OrignalFace, Dir);
}

UStaticMesh* UEngineExtActorShell::GetStaticMeshFromMeshComponent(UStaticMeshComponent* Component)
{
    return Component ? Component->GetStaticMesh() : nullptr;
}

UActorComponent* UEngineExtActorShell::CreateActorComponent(AActor* Actor, TSubclassOf<UActorComponent> UC)
{
    UActorComponent* Ret = NewObject<UActorComponent>(Actor, UC);
    if (!Ret)
    {
        UE_LOG(UEngineExtActorShellLog, Error, TEXT("CreateActorComponent failed, invalid ComponentClass"));
        return nullptr;
    }

    Ret->RegisterComponentWithWorld(Actor->GetWorld());
    Actor->AddOwnedComponent(Ret);
    return Ret;
}

TSubclassOf<AActor> UEngineExtActorShell::ConvertToActorClass(UObject* Object)
{
    return Cast<UClass>(Object);
}

ALevelScriptActor* UEngineExtActorShell::FindFirstLevelScriptActor(UObject* WorldContextObject)
{
    if (WorldContextObject)
    {
        UWorld* World = WorldContextObject->GetWorld();
        for (TActorIterator<ALevelScriptActor> ItActor(World); ItActor; ++ItActor)
        {
            return *ItActor;
        }
    }

    return nullptr;
}

void UEngineExtActorShell::SetActorSkeletalMeshLightChannel(AActor* pActor, bool Channel0, bool Channel1, bool Channel2)
{
    if (!pActor)
        return;

    TArray<UActorComponent*> MeshComponents = pActor->K2_GetComponentsByClass(UMeshComponent::StaticClass());

    for (UActorComponent* Component : MeshComponents)
    {
        UMeshComponent* meshComponent = Cast<UMeshComponent>(Component);
        if(meshComponent)
            meshComponent->SetLightingChannels(Channel0, Channel1, Channel2);
    }
}

void UEngineExtActorShell::SetActorSkeletalMeshMipMap(AActor* pActor, bool bForceMipStreaming)
{
    if (!pActor)
        return;

    TArray<UActorComponent*> MeshComponents = pActor->K2_GetComponentsByClass(UMeshComponent::StaticClass());

    for (UActorComponent* Component : MeshComponents)
    {
        UMeshComponent* meshComponent = Cast<UMeshComponent>(Component);
        if (meshComponent)
        {
            meshComponent->bForceMipStreaming = bForceMipStreaming;
            if (bForceMipStreaming)
            {
                TArray<UMaterialInterface*> UsedMaterials;
                meshComponent->GetUsedMaterials(UsedMaterials);
                for (auto Material : UsedMaterials)
                {
                    if (Material)
                    {
                        TArray<UTexture*> UsedTextures;
                        Material->GetUsedTextures(UsedTextures, EMaterialQualityLevel::Num, true, ERHIFeatureLevel::Num, true);
                        for (auto UsedTexture : UsedTextures)
                        {
                            auto Texture2D = Cast<UTexture2D>(UsedTexture);
                            if (Texture2D)
                            {
                                Texture2D->bForceMiplevelsToBeResident = true;
                                Texture2D->WaitForStreaming();
                            }
                        }
                    }
                }
            }
        }
    }
}

void UEngineExtActorShell::SetActorSkeletalMeshCastShadow(AActor* pActor, bool bCastShadow)
{
    if (!pActor)
        return;

    TArray<UActorComponent*> MeshComponents = pActor->K2_GetComponentsByClass(UMeshComponent::StaticClass());

    for (UActorComponent* Component : MeshComponents)
    {
        UMeshComponent* meshComponent = Cast<UMeshComponent>(Component);
		if (meshComponent)
		{
			/*meshComponent->CastShadow = bCastShadow;
			meshComponent->bCastDynamicShadow = bCastShadow;*/
			meshComponent->SetCastShadow(bCastShadow);
		}
    }
    TArray<class AActor*> OutActors;
    pActor->GetAttachedActors(OutActors);
    for (int i = 0; i < OutActors.Num(); i++)
    {
        SetActorSkeletalMeshCastShadow(OutActors[i], bCastShadow);
    }
}

void UEngineExtActorShell::SetActorMaxDrawDistance(AActor* pActor, float NewCullDistance)
{
    if (!pActor)
        return;

    TArray<UActorComponent*> Components;
    pActor->GetComponents(Components, true);

    for (UActorComponent* Component : Components)
    {
        UPrimitiveComponent* meshComponent = Cast<UPrimitiveComponent>(Component);
		// Avoid setting ship wake particles (!!NOT a appropriate way, as now ship wake particle using 1.0f as show only in planar reflection. this would removed when ship wake form changed or show only in planar reflection is good enough)
        if (meshComponent && !FMath::IsNearlyEqual(meshComponent->CachedMaxDrawDistance, 1.0f))
            meshComponent->SetCullDistance(NewCullDistance);
    }
}

void UEngineExtActorShell::GetPlayerViewPoint(AController* PC, FVector& out_Location, FRotator& out_Rotation)
{
    if (PC)
    {
        PC->GetPlayerViewPoint(out_Location, out_Rotation);
    }
}

FVector UEngineExtActorShell::GetLocationOnFloor(UObject* WorldContextObject, const FVector& Location, const TArray<AActor*>& ActorsToIgnore, float AddZ, float MinusZ)
{
    FHitResult HitResult;
    FVector WorldOrigin = Location + FVector(0.0f, 0.0f, AddZ);
    FVector WorldDirection = WorldOrigin + FVector(0, 0, MinusZ);

    FLinearColor TraceColor = FLinearColor::Green;
    FLinearColor TraceHitColor = FLinearColor::Red;
    if (UKismetSystemLibrary::LineTraceSingle(WorldContextObject, WorldOrigin, WorldDirection, UEngineTypes::ConvertToTraceType(ECollisionChannel::ECC_WorldStatic), false, ActorsToIgnore, EDrawDebugTrace::Type::None, HitResult, true, TraceColor, TraceHitColor, 10.0f))
    {
        //if (HitResult.Location.Z < Location.Z)
        //    return HitResult.Location + FVector(0.0f, 0.0f, 1.0f);
        if (HitResult.Actor.IsValid())
        {
            return HitResult.Location;
        }
    }

    //if (UKismetSystemLibrary::LineTraceSingle(WorldContextObject, WorldOrigin, WorldDirection, UEngineTypes::ConvertToTraceType(ECollisionChannel::ECC_Pawn), false, ActorsToIgnore, EDrawDebugTrace::Type::None, HitResult, true, TraceColor, TraceHitColor, 10.0f))
    //{
    //    //if (HitResult.Location.Z < Location.Z)
    //    //    return HitResult.Location + FVector(0.0f, 0.0f, 1.0f);
    //    if (HitResult.Actor.IsValid())
    //    {
    //        return HitResult.Location;
    //    }
    //}

    return Location;
}

float UEngineExtActorShell::GetLocationZOnFloor(UObject* WorldContextObject, const FVector& Location, const TArray<AActor*>& ActorsToIgnore, float AddZ, float MinusZ)
{
    FVector NewLocation = GetLocationOnFloor(WorldContextObject, Location, ActorsToIgnore, AddZ, MinusZ);
    return NewLocation.Z;
}

float UEngineExtActorShell::GetLocationZOnStaticWorld(UObject* WorldContextObject, const FVector& Location, const TArray<AActor*>& ActorsToIgnore, float AddZ, float MinusZ)
{
    FHitResult HitResult;
    FVector WorldOrigin = Location + FVector(0.0f, 0.0f, AddZ);
    FVector WorldDirection = WorldOrigin + FVector(0, 0, MinusZ);

    FLinearColor TraceColor = FLinearColor::Green;
    FLinearColor TraceHitColor = FLinearColor::Red;

    TArray<TEnumAsByte<EObjectTypeQuery> >  ObjectTypes;
    ObjectTypes.Add(UEngineTypes::ConvertToObjectType(ECollisionChannel::ECC_WorldStatic));

    if (UKismetSystemLibrary::LineTraceSingleForObjects(WorldContextObject, WorldOrigin, WorldDirection, ObjectTypes, false, ActorsToIgnore, EDrawDebugTrace::Type::None, HitResult, true, TraceColor, TraceHitColor, 10.0f))
    {
        if (HitResult.Actor.IsValid())
        {
            return HitResult.Location.Z;
        }
    }

    return Location.Z;
}

void UEngineExtActorShell::SetComponentEditorOnly(UActorComponent* ActorComponent, bool bEditorOnly)
{
    if (ActorComponent)
    {
        ActorComponent->bIsEditorOnly = bEditorOnly ? 1:0;
    }
}

FTransform UEngineExtActorShell::GetSkeletalMeshSocketTransformRTSMesh(USkinnedMeshComponent* Component, FName InSocketName)
{
    if (!Component)
    {
        return FTransform::Identity;
    }
    if (!InSocketName.IsValid())
    {
        return FTransform::Identity;
    }

    FTransform OutSocketTransform(FTransform::Identity);
    USkeletalMeshSocket const* const Socket = Component->GetSocketByName(InSocketName);

    // apply the socket transform first if we find a matching socket
    if (Socket)
    {
        FTransform SocketLocalTransform = Socket->GetSocketLocalTransform();

        int32 BoneIndex = Component->GetBoneIndex(Socket->BoneName);
        if (BoneIndex != INDEX_NONE)
        {
            FTransform BoneTransform = Component->GetBoneTransform(BoneIndex, FTransform::Identity);
            OutSocketTransform = SocketLocalTransform * BoneTransform;
        }
    }
    else
    {
        int32 BoneIndex = Component->GetBoneIndex(InSocketName);
        if (BoneIndex != INDEX_NONE)
        {
            OutSocketTransform = Component->GetBoneTransform(BoneIndex, FTransform::Identity);
        }
    }

    return OutSocketTransform;
}

FString UEngineExtActorShell::GetLocalHostAddress()
{
    bool canBind = false;
    TSharedRef<FInternetAddr> LocalAddress = ISocketSubsystem::Get(PLATFORM_SOCKETSUBSYSTEM)->GetLocalHostAddr(*GLog, canBind);

    return (LocalAddress->IsValid() ? LocalAddress->ToString(false) : "");
}

void UEngineExtActorShell::SetActorMeshTranslucency(AActor* pActor, float nTranslucencySortPriority)
{
    if (!pActor)
        return;

    TArray<UActorComponent*> MeshComponents = pActor->K2_GetComponentsByClass(UMeshComponent::StaticClass());

    for (UActorComponent* Component : MeshComponents)
    {
        UMeshComponent* meshComponent = Cast<UMeshComponent>(Component);
        if (meshComponent)
        {
            meshComponent->SetTranslucentSortPriority(nTranslucencySortPriority);
        }
    }
}

void UEngineExtActorShell::ResetDrawDistanceWithCharacterValue(AActor* Actor)
{
    TArray<AActor*> OutActors;
    Actor->GetAttachedActors(OutActors, true);
    for (AActor* tmpActor : OutActors)
    {
        UEngineExtActorShell::ResetDrawDistanceWithCharacterValue(tmpActor);
    }
    TArray<UActorComponent*> tmpComponents = Actor->K2_GetComponentsByClass(UPrimitiveComponent::StaticClass());
    for (UActorComponent* tmpComponent : tmpComponents)
    {
        UEngineExtShell::SetComponentDrawDistance(Cast<UPrimitiveComponent>(tmpComponent));
    }
}