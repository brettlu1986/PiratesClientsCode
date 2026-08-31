// Fill out your copyright notice in the Description page of Project Settings.

#include "ClientShell.h"
#include "Client.h"
#include "GameClient.h"
#include "GameActorShell.h"
#include "GameDungeonShell.h"
#include "GameSoundShell.h"
#include "GameObjectShell.h"
#include "Pawns/PiratesShipPawn.h"
#include "Kismet/GameplayStatics.h"
#include "KMGameInstance.h"
#include "GameCameraShotShell.h"
#include "HAL/PlatformOutputDevices.h"
#include "RenderingThread.h"
#include "Blueprint/UserWidget.h"
#include "Components/Widget.h"
#include "Blueprint/WidgetTree.h"
#include "Components/TextBlock.h"
#include "UMG/KMRichTextBlock.h"
#include "UMG/KMTimerTextBlock.h"
#include "UMG/KMCountDownText.h"
#include "ILoadingScreenModule.h"
#include "Engine/LevelStreaming.h"

DEFINE_LOG_CATEGORY_STATIC(UClientShellLog, Log, All)

UClientShell::UClientShell(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , GameActorShell(nullptr)
    , GameDungeonShell(nullptr)
    , SoundShell(nullptr)
    , ObjectShell(nullptr)
{
}

UClientShell* UClientShell::GetClient(UObject* WorldContextObject)
{
    return Cast<UClientShell>(GetShell(WorldContextObject));
}

void UClientShell::Init()
{
    Super::Init();
    // 因为ClientModule内部的那些东西封的太死，所以这里只能设一遍。。

    GameActorShell = NewObject<UGameActorShell>(this);
    GameActorShell->Init();
    GameDungeonShell = NewObject<UGameDungeonShell>(this);
    SoundShell = NewObject<UGameSoundShell>(this);
    SoundShell->Init(this);
    ObjectShell = NewObject<UGameObjectShell>(this);
    CameraShotShell = NewObject<UGameCameraShotShell>(this);
}

USocketNetworkManager* UClientShell::GetClientNetworkManager()
{
    return UGameClient::Get(this)->GetClientNetworkManager();
}

ULandNavMeshDataManager * UClientShell::GetLandNavMeshDataManager()
{
    return UGameClient::Get(this)->GetLandNavMeshDataManager();
}

USaveGameManager* UClientShell::GetSaveGameManager()
{
    return UGameClient::Get(this)->GetSaveGameManager();
}

void UClientShell::ClientTravel(const FString& URL, bool bIsSmoothTravel)
{
    UGameClient::Get(this)->ClientTravel(URL, bIsSmoothTravel);
}

bool UClientShell::IsInSmoothTravel()
{
    return UGameClient::Get(this)->IsInSmoothTravel();
}

void UClientShell::OpenLevelAsync(const FString& URL)
{
    return UGameClient::Get(this)->OpenLevelAsync(URL);
}

UHydraClient* UClientShell::GetHydraClient()
{
    return UGameClient::Get(this)->GetHydraClient();
}

UPersistentTimer* UClientShell::GetPersistentTimer()
{
    return UGameClient::Get(this)->GetPersistentTimer();
}

class UChannelSdkManager* UClientShell::GetChannelSdkManager()
{
    return UGameClient::Get(this)->GetChannelSdkManager();
}

class UGVoiceSdkManager* UClientShell::GetGVoiceSdkManager()
{
    return UGameClient::Get(this)->GetGVoiceSdkManager();
}

class UDataSdkManager* UClientShell::GetDataSdkManager()
{
    return UGameClient::Get(this)->GetDataSdkManager();
}

class UClientDelegateManager* UClientShell::GetClientDelegateManager()
{
    return UGameClient::Get(this)->GetClientDelegateManager();
}

class USensitiveWordManager* UClientShell::GetSensitiveWordManager()
{
	return UGameClient::Get(this)->GetSensitiveWordManager();
}

class URenderSettingsManager* UClientShell::GetRenderSettingsManager()
{
	return UGameClient::Get(this)->GetRenderSettingsManager();
}

class USystemInfoManager* UClientShell::GetSystemInfoManager()
{
    return UGameClient::Get(this)->GetSystemInfoManager();
}

//bool UClientShell::IsForceDelayStartScriptLogic()
//{
//    auto KMGameInstance = Cast<UKMGameInstance>(UGameplayStatics::GetGameInstance(this));
//    return KMGameInstance ? KMGameInstance->IsForceDelayStartScriptLogic() : false;
//}

bool UClientShell::IsPlayFromHereInEditor()
{
#if WITH_EDITOR
    auto KMGameInstance = Cast<UKMGameInstance>(UGameplayStatics::GetGameInstance(this));
    return KMGameInstance ? KMGameInstance->IsPlayFromHereInEditor() : false;
#else
    return false;
#endif
}

void UClientShell::GetPlayFromHereTransform(FVector& Location, FRotator& Rotation)
{
#if WITH_EDITOR
    auto KMGameInstance = Cast<UKMGameInstance>(UGameplayStatics::GetGameInstance(this));
    if (KMGameInstance)
    {
        KMGameInstance->GetPlayFromHereTransform(Location, Rotation);
    }
#endif
}

void UClientShell::InitiallyLoadLevelStreaming()
{
	return UGameClient::Get(this)->InitiallyLoadLevelStreaming();
}

void UClientShell::ToggleSceneRendering(bool InFlag)
{
	UGameClient::Get(this)->ToggleSceneRendering(InFlag);
}

void UClientShell::SerializeMatShaderAfterUpdate()
{
	return UGameClient::Get(this)->SerializeMatShaderAfterUpdate();
}

void UClientShell::FlushAsyncLoading()
{
	::FlushAsyncLoading();
}

void UClientShell::LoadStreamLevel(UObject* WorldContextObject, const FString& PackageName)
{
    FLatentActionInfo ActionInfo;
    ActionInfo.UUID = 1;
    ActionInfo.Linkage = 1;
    ActionInfo.CallbackTarget = this;
    ActionInfo.ExecutionFunction = FName(TEXT("OnLoadLevelCompleted"));
    UGameplayStatics::LoadStreamLevel(WorldContextObject, FName(*PackageName), true, false, ActionInfo);
}

void UClientShell::OnLoadLevelCompleted()
{
    if (OnSubLevelLoadEnd.IsBound())
    {
        OnSubLevelLoadEnd.Broadcast();
    }
}

void UClientShell::UnloadStreamLevel(UObject* WorldContextObject, const FString& PackageName)
{
	FLatentActionInfo ActionInfo;
	ActionInfo.UUID = 1;
	ActionInfo.Linkage = 1;
	UGameplayStatics::UnloadStreamLevel(WorldContextObject, FName(*PackageName), ActionInfo, false);
}

ULevelStreaming* UClientShell::GetStreamingLevel(UObject* WorldContextObject, const FString& PackageName)
{
    return UGameplayStatics::GetStreamingLevel(WorldContextObject, FName(*PackageName));
}

void UClientShell::SetPlayerPawn(AActor* PlayerActor)
{
    UGameClient::Get(this)->SetPlayerPawn(PlayerActor);
}

int32 UClientShell::ShowMessageBox(int32 MessageType, const FString& Text, const FString& Caption)
{
    EAppReturnType::Type RetType = FPlatformMisc::MessageBoxExt(EAppMsgType::Type(MessageType), *Text, *Caption);
    return int32(RetType);
}

void UClientShell::TriggerCrashMannual(ECrashType CrashType)
{
    switch (CrashType)
    {
    case ECrashType::CTNullPointerAssignment:
        {
            int* Dummy = nullptr;
            (*Dummy) = 0;
        }
        break;
    case ECrashType::CTCheckFalse:
        check(false);
        break;
    case ECrashType::CTFatalLog:
        UE_LOG(UClientShellLog, Fatal, TEXT("this is a fatal log test, please ignore this crash."));
    default:
        break;
    }
}

void UClientShell::CrashRenderThread()
{
    ENQUEUE_RENDER_COMMAND(ManualTrigger_CrashRenderThread)(
    [](FRHICommandListImmediate& RHICmdList)
    {
        //check(false);
        UE_LOG(UClientShellLog, Fatal, TEXT("this is a fatal log test in RenderThread, please ignore this crash."));
    });

    FlushRenderingCommands();
}

/* Shipping版本：保存当前内存日志到文件；并开启文件日志 */
void UClientShell::DumpMemoryLogManual()
{
#if UE_BUILD_SHIPPING
    FOutputDevice* OutputDevice = FPlatformOutputDevices::GetLog();
    if (OutputDevice && GLog->IsRedirectingTo(OutputDevice))
    {
        GLog->RemoveOutputDevice(OutputDevice);

        const FString FileName = FPlatformOutputDevices::GetAbsoluteLogFilename();
        FString Name, Extension;
        FileName.Split(TEXT("."), &Name, &Extension, ESearchCase::CaseSensitive, ESearchDir::FromEnd);
        FString MemoryFilename = FString::Printf(TEXT("%s%s%s.%s"), *Name, TEXT("-Memory-"), *GSystemStartTime, *Extension);
        FArchive* MemoryLogFile = IFileManager::Get().CreateFileWriter(*MemoryFilename, FILEWRITE_AllowRead);
        if (MemoryLogFile)
        {
            OutputDevice->Dump(*MemoryLogFile);
            MemoryLogFile->Flush();
            delete MemoryLogFile;
        }
    }

    static struct FLogOutputDeviceFileInitializer
    {
        TUniquePtr<FOutputDeviceFile> LogDeviceFile;
        FLogOutputDeviceFileInitializer()
        {
            LogDeviceFile = MakeUnique<FOutputDeviceFile>();
        }
    }Singleton;

    OutputDevice = Singleton.LogDeviceFile.Get();
    GLog->AddOutputDevice(OutputDevice);
#endif
}

float UClientShell::Dump10KLogManual()
{
    const int32 BuffLength = 10 * 1024;
    static bool bInitialized = false;
    static TCHAR LogMessage[BuffLength];
    if (!bInitialized)
    {
        bInitialized = true;
        int32 i = 0;
        while (i < BuffLength)
        {
            LogMessage[i++] = TEXT('A');
        }
    }
    
    uint32 StartTime = FPlatformTime::Cycles();  
    UE_LOG(UClientShellLog, Log, LogMessage);
    return FPlatformTime::ToMilliseconds(FPlatformTime::Cycles() - StartTime);
}

FString UClientShell::GetMemoryLog()
{
    FString MemoryLog;
#if UE_BUILD_SHIPPING
    FOutputDevice* OutputDevice = FPlatformOutputDevices::GetLog();
    if (OutputDevice && GLog->IsRedirectingTo(OutputDevice))
    {
        FBufferArchive MemoryLogArchive;
        OutputDevice->Dump(MemoryLogArchive);
        ANSICHAR* LogData = (ANSICHAR*)MemoryLogArchive.GetData();
        MemoryLog = FString(UTF8_TO_TCHAR(LogData));
    }
#endif

    return MemoryLog;
}

FString UClientShell::GuidToString(const FGuid& Guid)
{
    return Guid.ToString();
}

void UClientShell::GetTextWidget(const UUserWidget* UserWidget, TArray<UWidget*>& OutWidgets)
{
    if (UserWidget == nullptr)
    {
        return;
    }
    if (IsValid(UserWidget->WidgetTree))
    {
        TArray<UWidget*> AllWidgets;
        UserWidget->WidgetTree->GetAllWidgets(AllWidgets);
        for (int32 i = 0; i < AllWidgets.Num(); i++)
        {
            UWidget* Widget = AllWidgets[i];
            if (Widget->IsA(UTextBlock::StaticClass()))
            {
                if ((!Widget->IsA(UKMTimerTextBlock::StaticClass()))
                    && (!Widget->IsA(UKMCountDownText::StaticClass())))
                {
                    OutWidgets.Add(Widget);
                }
            }
            else if (Widget->IsA(UKMRichTextBlock::StaticClass()))
            {
                OutWidgets.Add(Widget);
            }
        }
    }

}

bool UClientShell::BeginLoading(UUserWidget* InUserWidget, float InTargetPercent, float InMiniTime)
{
	if (FModuleManager::Get().IsModuleLoaded("LoadingScreen"))
	{
		ILoadingScreenModule& LoadingScreenModule = FModuleManager::GetModuleChecked<ILoadingScreenModule>("LoadingScreen");
		LoadingScreenModule.BeginLoading(InUserWidget, InTargetPercent, InMiniTime);
		return true;
	}
	return false;
}

void UClientShell::EndLoading()
{
	if (FModuleManager::Get().IsModuleLoaded("LoadingScreen"))
	{
		ILoadingScreenModule& LoadingScreenModule = FModuleManager::GetModuleChecked<ILoadingScreenModule>("LoadingScreen");
		LoadingScreenModule.EndLoading();
	}

}

void UClientShell::ResetLoading()
{
	if (FModuleManager::Get().IsModuleLoaded("LoadingScreen"))
	{
		ILoadingScreenModule& LoadingScreenModule = FModuleManager::GetModuleChecked<ILoadingScreenModule>("LoadingScreen");
		LoadingScreenModule.ResetLoading();
	}
}

void UClientShell::OnCollectingWCOrigin(FVector& Location)
{
    auto PlayerPawn = UGameClient::Get(this)->GetPlayerPawn();
     
    if (PlayerPawn.IsValid())
    {
        FVector Loc = PlayerPawn->GetActorLocation();
        Location.X = Loc.X;
        Location.Y = Loc.Y;
        Location.Z = Loc.Z;
        //UE_LOG(UClientShellLog, Error, TEXT("OnCollectingWCOrigin, player valid, %.1f, %.1f %.1f"), Location.X, Location.Y, Location.Z);
    }
    //else
    //{
    //    UE_LOG(UClientShellLog, Error, TEXT("OnCollectingWCOrigin, player not valid"));
    //}
}

void UClientShell::BindOnCollectingWCOriginDelegate()
{
    FCoreUObjectDelegates::OnCollectingWCOrigin.BindUObject(this, &UClientShell::OnCollectingWCOrigin);
}

void UClientShell::DumpReferencedObject()
{
    UGameClient::Get(this)->DumpReferencedObject();
}

void UClientShell::SetUseU4LuaEnabled(bool Enabled)
{
    UGameClient::Get(this)->SetUseU4LuaEnabled(Enabled);
}

void UClientShell::SetClientConnectionTimeout(float Value)
{
    UGameClient::Get(this)->SetClientConnectionTimeout(Value);
}

float UClientShell::GetClientConnectionTimeout()
{
    return UGameClient::Get(this)->GetClientConnectionTimeout();
}

bool UClientShell::LineActorIntersection(AActor* Actor, const FVector& BoxPosOffset, const FVector& BoxExtent, const FVector& LineStart, const FVector& LineEnd)
{
    if (Actor == nullptr)
    {
        return false;
    }
    FVector ActorPos = Actor->GetActorLocation();
    FVector BoxOrigin = ActorPos + BoxPosOffset;
    FBox Box = FBox::BuildAABB(BoxOrigin, BoxExtent);
    const FVector Direction = LineEnd - LineStart;
    bool Hit = FMath::LineBoxIntersection(Box, LineStart, LineEnd, Direction);
    return Hit;
}