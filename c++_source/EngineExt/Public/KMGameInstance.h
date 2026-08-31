// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "Engine/GameInstance.h"

#include "KMGameInstance.generated.h"

/**
 *
 */

#define CREATE_MANAGER_WITH_CLASS(Manager, ManagerClass) \
    Manager = NewObject<ManagerClass>(this); \
    Manager->Init();

#define CREATE_MANAGER(Manager) \
	Manager = NewObject<U##Manager>(this); \
	Manager->Init();

#define DECLARE_MANAGER(Manager) \
	UPROPERTY(BlueprintReadOnly, Category = "KMGameInstance") \
	U##Manager* Manager; \
	U##Manager* Get##Manager() { return Manager; };

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnShutdown);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnLevelBeginPlay, const FString&, LevelName, bool, bPersistentLevel);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_ThreeParams(FOnLevelEndPlay, const FString&, LevelName, const EEndPlayReason::Type, EndPlayReason, bool, bPersistentLevel);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnRestartPlayer, AKMPlayerController*, PlayerController);
DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnNetworkFailureWithString, ENetworkFailure::Type, FailureType, const FString&, ErrorString);

UCLASS(Blueprintable, config = Game)
class ENGINEEXT_API UKMGameInstance : public UGameInstance
{
	GENERATED_UCLASS_BODY()

private:
	struct FImplement;
	TSharedPtr<FImplement> Impl;

	DECLARE_LOG_CATEGORY_CLASS(KMGameInstanceLog, Log, All);

public:
    virtual void BeginDestroy();

    UFUNCTION(BlueprintCallable, Category = "KMGameInstance")
    void RecreateGame();
    
    UFUNCTION(BlueprintCallable, Category = "KMGameInstance")
    void DestroyGame();

    UFUNCTION(BlueprintCallable, Category = "KMGameInstance")
    void ExitGame();

	UFUNCTION(BlueprintImplementableEvent, meta = (DisplayName = "NetworkErrorWithString"))
	void HandleNetworkErrorWithString(ENetworkFailure::Type FailureType, const FString& ErrorString);
public:
	/**
	*	The Init method of this class is only for init this instance but not game logics.
	*/
	virtual void Init() override;

	/** virtual function to allow custom GameInstances an opportunity to do cleanup when shutting down */
	virtual void Shutdown() override;

	virtual void StartGameInstance() override;
	virtual void OnWorldChanged(UWorld* OldWorld, UWorld* NewWorld) override;

    //bool IsForceDelayStartScriptLogic();
#if WITH_EDITOR
    bool IsPlayFromHereInEditor();
    void GetPlayFromHereTransform(FVector& Location, FRotator& Rotation);
#endif

	UFUNCTION(BlueprintPure, Category = "KMGameInstance", meta = (WorldContext = "WorldContextObject"))
	static UKMGameInstance* GetKMGameInstance(UObject* WorldContextObject);

    UPROPERTY(config)
    FString PIEWorldURL;

	UPROPERTY(BlueprintReadWrite, EditAnywhere, BlueprintAssignable)
    FOnShutdown OnShutdown;
    UPROPERTY()
    FOnLevelBeginPlay OnLevelBeginPlay;
    UPROPERTY()
    FOnLevelEndPlay OnLevelEndPlay;
	UPROPERTY()
	FOnRestartPlayer OnRestartPlayer;
	UPROPERTY()
	FOnNetworkFailureWithString OnNetworkFailureWithString;

    const static FString EmptyMapNameSuffix;
    const static FName EmptyMapURL;

	bool IsAsyncLoadingMap = false;

#if WITH_EDITOR
    virtual FGameInstancePIEResult InitializeForPlayInEditor(int32 PIEInstanceIndex, const FGameInstancePIEParameters& Params) override;
    virtual FGameInstancePIEResult StartPlayInEditorGameInstance(ULocalPlayer* LocalPlayer, const FGameInstancePIEParameters& Params) override;	
#endif

	//yangjingzhao for print loaded packaged when game client update
	UFUNCTION(BlueprintCallable, Category = "KMGameInstance")
	void PrintLoadedPackages();

	UFUNCTION(BlueprintCallable, Category = "KMGameInstance")
	void PrintPackageRefrence(FString InPackageName);
	//end

};
