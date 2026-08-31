// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Shell/CommonShell.h"
#include "ClientShell.generated.h"

class FClientModule;
class UHubServerShell;
class UGameActorShell;
class UGameDungeonShell;
class UGameSoundShell;
class UGameObjectShell;
class UGameCameraShotShell;

UENUM()
enum class ECrashType : uint8
{
    CTNullPointerAssignment,
    CTCheckFalse,
    CTFatalLog,
};

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnSubLevelLoadEnd);
/**
 * Expose interfaces of UGameClient to Lua/Blueprint
 */
UCLASS(BlueprintType)
class CLIENT_API UClientShell : public UCommonShell
{
	GENERATED_UCLASS_BODY()
	
public:
    UFUNCTION(BlueprintPure, Category = "Client", meta = (WorldContext = "WorldContextObject", DisplayName = "GetClientShell"))
    static UClientShell* GetClient(UObject* WorldContextObject);

    virtual void Init() override;

    UFUNCTION()
    FORCEINLINE UGameActorShell* GetActorShell()
    {
        return GameActorShell;
    }

    UFUNCTION()
    class USocketNetworkManager* GetClientNetworkManager();

    UFUNCTION()
    class ULandNavMeshDataManager* GetLandNavMeshDataManager();

    UFUNCTION(BlueprintPure)
    class USaveGameManager* GetSaveGameManager();

    UFUNCTION()
    UGameDungeonShell* GetDungeonShell() { return GameDungeonShell; }

    UFUNCTION()
    UGameSoundShell* GetSoundShell() { return SoundShell; }

    UFUNCTION()
    UGameObjectShell* GetObjectShell() { return ObjectShell; }

    UFUNCTION()
    UGameCameraShotShell* GetCameraShotShell() { return CameraShotShell; }

    UFUNCTION()
    void ClientTravel(const FString& URL, bool bIsSmoothTravel);

    UFUNCTION()
    bool IsInSmoothTravel();

    UFUNCTION()
    void OpenLevelAsync(const FString& URL);

    UFUNCTION()
    class UHydraClient* GetHydraClient();

    UFUNCTION()
    class UPersistentTimer* GetPersistentTimer();

    UFUNCTION()
    class UChannelSdkManager* GetChannelSdkManager();

    UFUNCTION()
    class UGVoiceSdkManager* GetGVoiceSdkManager();

    UFUNCTION()
    class UDataSdkManager* GetDataSdkManager();

    UFUNCTION()
    class UClientDelegateManager* GetClientDelegateManager();

	UFUNCTION()
	class USensitiveWordManager* GetSensitiveWordManager();

	UFUNCTION(BlueprintCallable)
	class URenderSettingsManager* GetRenderSettingsManager();

    UFUNCTION()
    class USystemInfoManager* GetSystemInfoManager();

    //UFUNCTION()
    //bool IsForceDelayStartScriptLogic();

    UFUNCTION()
    bool IsPlayFromHereInEditor();

    UFUNCTION()
    void GetPlayFromHereTransform(FVector& Location, FRotator& Rotation);

	//modified by yangjingzhao
	UFUNCTION()
	void InitiallyLoadLevelStreaming();

	UFUNCTION(BlueprintCallable, Category="Loading|Optimization")
	void ToggleSceneRendering(bool InFlag);

	UFUNCTION()
	void SerializeMatShaderAfterUpdate();

	//
	UFUNCTION()
	void FlushAsyncLoading();

    UFUNCTION()
    void LoadStreamLevel(UObject* WorldContextObject, const FString& PackageName);

	UFUNCTION()
	void UnloadStreamLevel(UObject* WorldContextObject, const FString& PackageName);

    UFUNCTION()
    void OnLoadLevelCompleted();

    UFUNCTION()
    ULevelStreaming* GetStreamingLevel(UObject* WorldContextObject, const FString& PackageName);

    UFUNCTION(BlueprintCallable, Category = "Client", meta = (DisplayName = "ShowMessageBox"))
    static int32 ShowMessageBox(int32 MessageType, const FString& Text, const FString& Caption);

    UFUNCTION()
    void TriggerCrashMannual(ECrashType CrashType);

    UFUNCTION()
    void CrashRenderThread();

    UFUNCTION()
    void DumpMemoryLogManual();

    UFUNCTION()
    float Dump10KLogManual();

    UFUNCTION()
    FString GetMemoryLog();

    UFUNCTION()
    FString GuidToString(const FGuid& Guid);

    UFUNCTION()
    void GetTextWidget(const UUserWidget* UserWidget, TArray<UWidget*>& OutWidgets);

	UFUNCTION(BlueprintCallable, Category = "LoadingScreen")
	bool BeginLoading(UUserWidget* InUserWidget, float InTargetPercent, float InMiniTime);

	UFUNCTION(BlueprintCallable, Category = "LoadingScreen")
	void EndLoading();

	UFUNCTION(BlueprintCallable, Category = "LoadingScreen")
	void ResetLoading();

    UFUNCTION()
    void SetPlayerPawn(AActor* PlayerActor);

    UFUNCTION()
    void BindOnCollectingWCOriginDelegate();

    UFUNCTION()
    void DumpReferencedObject();

    UFUNCTION()
    void SetUseU4LuaEnabled(bool Enabled);
    
    UFUNCTION()
    void SetClientConnectionTimeout(float Value);
    
    UFUNCTION()
    float GetClientConnectionTimeout();

    UFUNCTION()
    bool LineActorIntersection(AActor* Actor, const FVector& BoxPosOffset, const FVector& BoxExtent, const FVector& LineStart, const FVector& LineEnd);
private:
    UPROPERTY()
    UGameActorShell* GameActorShell;

    UPROPERTY()
    UGameDungeonShell* GameDungeonShell;

    UPROPERTY()
    UGameSoundShell* SoundShell;

    UPROPERTY()
    UGameObjectShell* ObjectShell;

    UPROPERTY()
    FOnSubLevelLoadEnd OnSubLevelLoadEnd;

    UPROPERTY()
    UGameCameraShotShell* CameraShotShell;


private:
    void OnCollectingWCOrigin(FVector& Location);
};
