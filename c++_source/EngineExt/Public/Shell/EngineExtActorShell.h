
#pragma once
#include "EngineExtActorShell.generated.h"


UCLASS(BlueprintType)
class ENGINEEXT_API UEngineExtActorShell : public UObject
{
    GENERATED_BODY()

public:
    UFUNCTION()
    static void SetActorLocation(AActor* Actor, const FVector& Position);

    UFUNCTION()
    static void SetActorLocationXYZ(AActor* Actor, float X, float Y, float Z);

    UFUNCTION()
    static FVector GetActorLocation(AActor* Actor);

    UFUNCTION()
    static void GetActorLocationXYZ(AActor* Actor, float& X, float& Y, float& Z);

    UFUNCTION()
    static void SetActorRotation(AActor* Actor, const FRotator& Rotation);

    UFUNCTION()
    static void SetActorRotationYawPitchRoll(AActor* Actor, float Yaw, float Pitch, float Roll);

    UFUNCTION()
    static FRotator GetActorRotation(AActor* Actor);

    UFUNCTION()
    static void GetActorRotationYawPitchRoll(AActor* Actor, float& Yaw, float& Pitch, float& Roll);

    UFUNCTION()
    static void SetActorScale(AActor* Actor, float Scale);

    UFUNCTION()
    static void SetActorScale3D(AActor* Actor, const FVector& Scale);

    UFUNCTION()
    static FVector GetActorScale3D(AActor* Actor);

    UFUNCTION()
    static uint32 GetActorUniqueId(AActor* Actor);

    UFUNCTION()
    static uint32 GetActorNetGuid(AActor* Actor);

    UFUNCTION(BlueprintPure, Category = "EngineExt")
    static FRotator GetRotatorFromVectors(const FVector& Vector1, const FVector& Vector2);

    UFUNCTION(BlueprintCallable, Category = "EngineExt")
    static AActor* SpawnActorForScript(UObject* WorldContextObject, TSubclassOf<AActor> UC, const FTransform& SpawnTransform, APawn* Instigator = nullptr);

    UFUNCTION(BlueprintCallable, Category = "EngineExt")
    static AActor* SpawnActorForScript_LR(UObject* WorldContextObject, TSubclassOf<AActor> UC, FVector const& Location, FRotator const& Rotation, APawn* Instigator = nullptr);

    UFUNCTION()
    static AActor* SpawnActorWithoutTransform(UObject* WorldContextObject, TSubclassOf<AActor> UC, APawn* Instigator = nullptr);

    UFUNCTION()
    static void SetSpawnLogEnabled(bool bEnabled);

    UFUNCTION()
    static bool MovePawnToSafeLocation(UObject* WorldContextObject, APawn* Pawn);

    UFUNCTION()
    static bool IsPawnLocationBlocked(UObject* WorldContextObject, APawn* Pawn);

    UFUNCTION()
    static bool IsCanSafeTeleport(UObject* WorldContextObject, APawn* Pawn);

    UFUNCTION()
    static bool HasActorBegunPlay(AActor* Actor);

    UFUNCTION(BlueprintCallable, Category = "EngineExt")
    static void DestroyActor(UObject* WorldContextObject, AActor* Actor, bool bNetForce = false);

    UFUNCTION(BlueprintCallable, Category = "EngineExt")
    static void DestroyActorComponent(AActor* Actor, UActorComponent* Component);

    UFUNCTION(BlueprintPure, Category = "EngineExt")
    static FRotator GetWorldRotationToTargetLocation(AActor* Actor, const FVector& TargetLocation);

    UFUNCTION(BlueprintPure, Category = "EngineExt")
    static UStaticMesh* GetStaticMeshFromMeshComponent(UStaticMeshComponent* Component);

    UFUNCTION(BlueprintCallable, Category = "EngineExt")
    static UActorComponent* CreateActorComponent(AActor* Actor, TSubclassOf<UActorComponent> UC);

    UFUNCTION(BlueprintPure, Category = "EngineExt")
    static TSubclassOf<AActor> ConvertToActorClass(UObject* Object);

    UFUNCTION(BlueprintPure, Category = "EngineExt")
    static ALevelScriptActor* FindFirstLevelScriptActor(UObject* WorldContextObject);

    UFUNCTION(BlueprintCallable, Category = "EngineExt")
    static void SetActorSkeletalMeshLightChannel(AActor* pActor, bool Channel0, bool Channel1, bool Channel2);

    UFUNCTION(BlueprintCallable, Category = "EngineExt")
    static void SetActorSkeletalMeshMipMap(AActor* pActor, bool bForceMipStreaming);

    UFUNCTION(BlueprintCallable, Category = "EngineExt")
    static void SetActorSkeletalMeshCastShadow(AActor* pActor, bool bCastShadow);

    UFUNCTION(BlueprintCallable, Category = "EngineExt")
    static void SetActorMaxDrawDistance(AActor* pActor, float NewCullDistance);

	UFUNCTION(BlueprintPure, Category = "EngineExt")
	static void GetPlayerViewPoint(AController* PC, FVector& out_Location, FRotator& out_Rotation);

    UFUNCTION(BlueprintCallable, Category = "EngineExt")
    static FVector GetLocationOnFloor(UObject* WorldContextObject, const FVector& Location, const TArray<AActor*>& ActorsToIgnore, float AddZ, float MinusZ);

    UFUNCTION(BlueprintCallable, Category = "EngineExt")
    static float GetLocationZOnFloor(UObject* WorldContextObject, const FVector& Location, const TArray<AActor*>& ActorsToIgnore, float AddZ, float MinusZ);

    UFUNCTION(BlueprintCallable, Category = "EngineExt")
    static float GetLocationZOnStaticWorld(UObject* WorldContextObject, const FVector& Location, const TArray<AActor*>& ActorsToIgnore, float AddZ, float MinusZ);

    UFUNCTION(BlueprintCallable, Category = "EngineExt", meta = (CallInEditor = "true"))
    static void SetComponentEditorOnly(UActorComponent* ActorComponent, bool bEditorOnly);

    UFUNCTION(BlueprintPure, Category = "EngineExt", meta = (Keywords = "Bone"))
    static FTransform GetSkeletalMeshSocketTransformRTSMesh(USkinnedMeshComponent* Component, FName InSocketName);
    
    UFUNCTION(BlueprintCallable, Category = "EngineExt")
    static FString GetLocalHostAddress();


    UFUNCTION(BlueprintCallable, Category = "EngineExt")
    static void SetActorMeshTranslucency(AActor* pActor, float nTranslucencySortPriority);

    UFUNCTION(BlueprintCallable, Category = "EngineExt")
    static void ResetDrawDistanceWithCharacterValue(AActor* Actor);

};
