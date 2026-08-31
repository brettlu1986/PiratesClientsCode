// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "KMActor.generated.h"

UCLASS(meta=(ChildCanTick))
class ENGINEEXT_API AKMActor : public AActor
{
    GENERATED_UCLASS_BODY()

public:
    UFUNCTION(BlueprintNativeEvent, Category = "KMActor", meta = (CallInEditor = "true"))
    void OnEditPropertyChanged(const FString& PropertyName);
    UFUNCTION(BlueprintNativeEvent, Category = "KMActor", meta = (CallInEditor = "true"))
    void OnEditActorAttached(const AActor* InParent);
    UFUNCTION(BlueprintNativeEvent, Category = "KMActor", meta = (CallInEditor = "true"))
    void OnEditActorDetached(const AActor* InParent);

    UFUNCTION(BlueprintCallable, Category = "KMActor", meta = (CallInEditor = "true"))
    void SetPropertyReadyOnlyInInstance(const FString& PropertyName);

#if WITH_EDITOR
    virtual void PostInitProperties() override;
    virtual void BeginDestroy() override;

    void OnObjectPropertyChangedCallback(UObject* Object, struct FPropertyChangedEvent& PropertyChangedEvent);
    void OnLevelActorAttachedCallback(AActor* InActor, const AActor* InParent);
    void OnLevelActorDetachedCallback(AActor* InActor, const AActor* InParent);
#endif

    UFUNCTION(BlueprintCallable, BlueprintNativeEvent, Category = "KMActor")
    bool NeedReplicate(const FName& PropertyName);

public:
    const TArray<uint8>& GetInitProtoData() const { return InitProtoData; }

    UFUNCTION(BlueprintPure, Category = "KMActor")
    const int GetLogicInstanceId() const { return LogicInstanceId; }

    UFUNCTION()
    void BeginPlayManually();

    void PreBeginPlay();
    void OrignalBeginPlay();
    void PostBeginPlay();
    inline const bool HasBeginPlayCompletely() const { return bHasBeginPlayCompletely; }    
    virtual void Destroyed() override;
public:
    UPROPERTY(EditDefaultsOnly)
    bool EnableDebugLog;    

protected:
    virtual void BeginPlay() override;
    virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
	virtual void OnSerializeNewActor(FOutBunch& OutBunch) override;
	virtual void OnActorChannelOpen(FInBunch& InBunch, UNetConnection* Connection) override;    
    //virtual void PreReplication(IRepChangedPropertyTracker & ChangedPropertyTracker) override;

private:
    TArray<uint8> InitProtoData;
    int LogicInstanceId;
    bool IsBeginPlayManually;
    bool bHasBeginPlayCompletely;
    bool HasActorChannelOpened;  // 防止重复触发delegate

#if WITH_EDITOR
    FDelegateHandle OnLevelActorAttachedHandle;
    FDelegateHandle OnLevelActorDetachedHandle;
#endif
};
