// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "PiratesReplicationBPHelpers.generated.h"

/**
 * 
 */
UCLASS()
class COMMON_API UPiratesReplicationBPHelpers : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()
	
public:

    /* 用来处理队伍同步信息，将队伍成员放进一个同步GraphNode */
    UFUNCTION(BlueprintCallable, Category = "Network")
    static void SetTeamForPlayerController(APlayerController* Player, int32 TeamId);

    /* 清除某个队伍的同步 */
    UFUNCTION(BlueprintCallable, Category = "Network")
    static void ClearTeamReplicateById(AActor* Actor, int32 TeamId);

    /* 不受controller的限制，强制同步某个actor，用于观战 */
    UFUNCTION(BlueprintCallable, Category = "Network")
    static void SetActorReplicateToController(APlayerController* OwnerController, AActor* Actor, bool bReplicate);

    /* 设置两个actor的同步依赖关系 */
    UFUNCTION(BlueprintCallable, Category = "Network")
    static void AddDependentActor(AActor* ReplicatorActor, AActor* DependentActor);

    UFUNCTION(BlueprintCallable, Category = "Network")
    static void RemoveDependentActor(AActor* ReplicatorActor, AActor* DependentActor);

    UFUNCTION(BlueprintCallable, Category = "Network")
    static void ChangeOwnerAndRefreshReplication(AActor* ActorToChange, AActor* NewOwner);

    /* 实时修改actor的同步距离 */
    UFUNCTION(BlueprintCallable, Category = "Network")
    static void ChangeActorCullDistanceSquared(AActor* ActorToChange, float CullDistance);

    UFUNCTION(BlueprintCallable, Category = "Network")
    static float GetActorCullDistanceSquared(AActor* Actor);

    /* 给Controller限制同步人数，主要用于效率考虑的同步限制 */
    UFUNCTION(BlueprintCallable, Category = "Network")
    static void SetReplicatePlayerMaxNum(APlayerController* Controller, int32 Num);

    UFUNCTION(BlueprintCallable, Category = "Network")
    static void SetEnableLimitPlayerNum(UObject* Actor, bool bLimit);

    /* 设置DormantActor针对OtherActor的同步休眠 */
    UFUNCTION(BlueprintCallable, Category = "Network")
    static void SetActorDormantForConnection(AActor* DormantActor, AActor* OtherActor, uint8 bDormant);

    UFUNCTION(BlueprintCallable, meta = (WorldContext = "WorldContextObject", Category = "Network"))
    static class UPiratesReplicationGraph* FindReplicationGraph(const UObject* WorldContextObject);
};
