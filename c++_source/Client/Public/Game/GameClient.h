// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Game/GameCommon.h"
#include "ClientTabFileManager.h"
#include "SaveGame/GameAssetCache.h"
#include "GameClient.generated.h"

UCLASS(config = Game)
class CLIENT_API UGameClient : public UGameCommon
{
	GENERATED_UCLASS_BODY()

public:
    static UGameClient* Get(const UObject* WorldContextObject);

    virtual void Init() override;
    virtual void Start() override;
    virtual void Shutdown() override;
	virtual bool Exec(const TCHAR* Cmd, FOutputDevice& Ar) override;
	virtual void PlayerControllerUpdate(APiratesPlayerController* PC) override;

    class USocketNetworkManager* GetClientNetworkManager() const { return NetworkManager; }
    class USaveGameManager* GetSaveGameManager() const { return SaveGameManager; }
    class UPersistentTimer* GetPersistentTimer() const { return PersistentTimer; }
    class UChannelSdkManager* GetChannelSdkManager() const { return ChannelSdkManager; }
    class UGVoiceSdkManager* GetGVoiceSdkManager() const { return GVoiceSdkManager; }
    class UDataSdkManager* GetDataSdkManager() const { return DataSdkManager; }
    class UClientDelegateManager* GetClientDelegateManager() const;
	class USensitiveWordManager* GetSensitiveWordManager() { return SensitiveWordManager; }
	class URenderSettingsManager* GetRenderSettingsManager() { return RenderSettingsManager; }
    class USystemInfoManager* GetSystemInfoManager() { return SystemInfoManager; }

	virtual UClass* GetKMDelegateManagerClass() override;

    void ClientTravel(const FString& URL, bool bIsSmoothTravel);

    bool IsInSmoothTravel();

    void OpenLevelAsync(const FString& URL);

    class UHydraClient* GetHydraClient();

	//modified by yangjingzhao
	void InitiallyLoadLevelStreaming();

	void ToggleSceneRendering(bool InFlag);

    // for setting static mesh lod model
    //void SetStaticMeshLODBias(FString LevelPath);
    //~end

	//yangjingzhoa add for screenshot
	UTexture2D* CreateTexture2DByBitmapData(int32 Width, int32 Height, TArray<FColor>& BitmapData);

	//序列化shaderresource
	void SerializeMatShaderAfterUpdate();

    void SetPlayerPawn(AActor* Player);

    TWeakObjectPtr<AActor> GetPlayerPawn();

    void AddReferencedObject(UObject* Object);
    void RemoveReferencedObject(UObject* Object);
    void DumpReferencedObject();

	//yangjingzhao add for cache game asset cross maps
	UGameAssetCache* GetAssetCache();

    void SetClientConnectionTimeout(float Value);
    float GetClientConnectionTimeout();

    void VerifyIpConnectionTimeout(float DeltaTime);
protected:
    virtual void TickImplement(float DeltaTime) override;
    virtual void InitLua() override;
    virtual void UninitLua() override;

private:
    UPROPERTY()
    class UGPerfReporterManager* GPerfReporterManager;

    UPROPERTY()
    class USocketNetworkManager* NetworkManager;

    FClientTabFileManager TabFileManager;

    UPROPERTY()
    class UHydraClient* HydraClient;

    UPROPERTY()
    class USaveGameManager* SaveGameManager;

    UPROPERTY()
    class UPersistentTimer* PersistentTimer;

    UPROPERTY()
    class UChannelSdkManager* ChannelSdkManager;

    UPROPERTY()
    class UGVoiceSdkManager* GVoiceSdkManager;

    UPROPERTY()
    class UDataSdkManager* DataSdkManager;

	UPROPERTY()
	class USensitiveWordManager* SensitiveWordManager;

	UPROPERTY()
	class URenderSettingsManager* RenderSettingsManager;

    UPROPERTY()
    class USystemInfoManager* SystemInfoManager;

    UPROPERTY(config)
    bool AllowNetAsyncLoading;

    void LoadPackageAsyncCallback(const FName& PackageName, UPackage* LevelPackage, EAsyncLoadingResult::Type Result);
    void OnPostLoadMap(UWorld* CurrentWorld);

	//yangjingzhao add for levlestreaming loading
	FScriptDelegate OnLevelStreamingLoaded;

	UFUNCTION()
	void OnLevelStreamingPostLoaded();

    FDelegateHandle OnPostLoadMapHandle;

    FString PendingURL;
    UPROPERTY()
    UObject* HoldingWorld;

    TWeakObjectPtr<AActor> PlayerActor;

    UPROPERTY()
    TArray<UObject*> ReferencedObjects;

	//yangjingzhao add for cache game asset cross maps
	UPROPERTY()
	UGameAssetCache* AssetsCache;

    bool bIpConnectionTimeout;
    double LastTickRealTime;
    float ClientConnectionTimeout;
};
