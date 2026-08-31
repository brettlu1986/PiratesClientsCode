// Fill out your copyright notice in the Description page of Project Settings.

#include "Shell/EngineExtShell.h"
#include "EngineExt.h"
#include "Game/WorldObjectMap.h"
#include "Game/GameEngineExt.h"
#include "Game/Delegates/KMDelegateManager.h"
#include "Engine/StreamableManager.h"
#include "HAL/PlatformFilemanager.h"
#include "Config/KMEngineConfig.h"
#include "HAL/PlatformOutputDevices.h"
#include "DeviceProfiles/DeviceProfileManager.h"
#include "KMCharacter.h"

DECLARE_STATS_GROUP(TEXT("StaticLoadObjectWithoutFlush"), STATGROUP_StaticLoadObjectWithoutFlush, STATCAT_Advanced);
DEFINE_LOG_CATEGORY_STATIC(EngineExtShellLog, Log, All);

static FWorldObjectMap& GetGameWorldShellObjectMap()
{
    static FWorldObjectMap* g_ShellMap = new FWorldObjectMap();
    return *g_ShellMap;
}


UEngineExtShell::UEngineExtShell(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{
}

UObject* UEngineExtShell::GetShell(UObject* WorldContextObject)
{
    return GetGameWorldShellObjectMap().GetObject(WorldContextObject);
}

UEngineExtShell* UEngineExtShell::Get(UObject* WorldContextObject)
{
    return Cast<UEngineExtShell>(GetShell(WorldContextObject));
}

UWorld* UEngineExtShell::GetWorld() const
{
    auto Outer = GetOuter();
    return Outer ? Outer->GetWorld() : nullptr;
}

void UEngineExtShell::Init()
{
    GetGameWorldShellObjectMap().AddObject(this, this);
}

void UEngineExtShell::Start()
{

}

void UEngineExtShell::Shutdown()
{

}

void UEngineExtShell::Uninit()
{
    GetGameWorldShellObjectMap().RemoveObject(this);
}

void UEngineExtShell::AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector)
{
    Super::AddReferencedObjects(InThis, Collector);
}

const bool UEngineExtShell::IsEditor()
{
#if WITH_EDITOR
    return true;
#else
    return false;
#endif
}

const bool UEngineExtShell::IsEditMode(UObject* Object)
{
#if !(UE_BUILD_SHIPPING || UE_SERVER) && WITH_EDITOR
	if (Object->IsValidLowLevel())
	{
        if (Object->GetWorld() != nullptr)
        {
            EWorldType::Type WorldType = Object->GetWorld()->WorldType;
            if ((WorldType != EWorldType::Game) && (WorldType != EWorldType::PIE))
            {
                return true;
            }
        }
	}
#endif

	return false;
}

FString UEngineExtShell::GenerateObjectGuidString()
{
    FGuid NewGuid = FGuid::NewGuid();
    return NewGuid.ToString(EGuidFormats::UniqueObjectGuid);
}

UKMDelegateManager* UEngineExtShell::GetKMDelegateManager()
{
    return UGameEngineExt::Get(this)->GetKMDelegateManager();
}

FString UEngineExtShell::GetCurrentMapName()
{
    FString Name = GetWorld()->GetMapName();
    if (Name.StartsWith(PLAYWORLD_PACKAGE_PREFIX))
    {
        static FString PIEMapPrefix(PLAYWORLD_PACKAGE_PREFIX);
        int32 Index = Name.Find("_", ESearchCase::IgnoreCase, ESearchDir::FromStart, PIEMapPrefix.Len()+1);
        return &Name[Index + 1];
    }
    return Name;
}

float UEngineExtShell::GetWorldRealTimeSeconds()
{
    return GetWorld()->GetRealTimeSeconds();
}

bool UEngineExtShell::LoadAssetAsync(const FString& AssetName)
{
    if (AssetName.Len() == 0)
    {
        return false;
    }
    return UGameEngineExt::Get(this)->LoadAssetAsync(AssetName);
}

bool UEngineExtShell::LoadMultiAssetsAsync(const TArray<FString>& AssetNames, FOnMultiAssetsLoaded Callback)
{
    return UGameEngineExt::Get(this)->LoadMultiAssetsAsync(AssetNames, Callback);
}


void UEngineExtShell::ReloadEngineConfig()
{
    return UGameEngineExt::Get(this)->GetEngineConfig()->Load();
}

bool UEngineExtShell::LoadFileLines(const FString& Path, TArray<FString>& Lines)
{
    auto FileHandler = FPlatformFileManager::Get().GetPlatformFile().OpenRead(*Path);
    if (!FileHandler)
    {
        return false;
    }
    void* Buffer = nullptr;
    auto BufferSize = FileHandler->Size();
    if (BufferSize > 0)
    {
        Buffer = FMemory::Malloc(BufferSize + 2);
        FileHandler->Read((uint8*)Buffer, BufferSize);

        char* Temp = (char*)Buffer + BufferSize;
        *Temp = '\r';
        ++Temp;
        *Temp = 0;

        delete FileHandler;
    }
    else
    {
        delete FileHandler;
        return true;
    }

    static const uint8 bom[] = { 239, 187, 191 };
    static const int bomLen = sizeof(bom) / sizeof(char);
    int offset = 0;
    if ((BufferSize > bomLen) && memcmp(Buffer, bom, bomLen) == 0)
    {
        offset = bomLen;
    }

    char* P = (char*)Buffer + offset;
    int32 LineLen = 0;
    while (*P)
    {
        if (*P == '\r' || *P == '\n')
        {
            while (*P == '\r' || *P == '\n')
            {
                *P = 0;
                P++;
                LineLen++;
            }
            const char* Temp = P - LineLen;
            Lines.Add(UTF8_TO_TCHAR(Temp));
            LineLen = 0;
        }
        else
        {
            LineLen++;
            P++;
        }
    }

    FMemory::Free(Buffer);
    return true;
}

UObject* UEngineExtShell::StaticLoadObjectWithoutFlush(const FString& Path)
{
    if (Path.Len() == 0)
    {
        return nullptr;
    }

#if STATS
    const TStatId StatId = FDynamicStats::CreateStatId<FStatGroup_STATGROUP_StaticLoadObjectWithoutFlush>(FString::Printf(TEXT("StaticLoadObjectWithoutFlush:%s"), *Path));
    FScopeCycleCounter CycleCounter(StatId);
#endif

	//QUICK_SCOPE_CYCLE_COUNTER(STAT_UEngineExtShell_StaticLoadObjectWithoutFlush);
    //FPrintTimeHelper Helper(*FString::Printf(TEXT("StaticLoadObjectWithoutFlush %s: "), *Path));
    UObject* Object = nullptr;
    if (IsInGameThread() && !IsAsyncLoading())
    {
		UE_LOG(EngineExtShellLog, Verbose, TEXT("StaticLoadObject : %s"), *Path);
        Object = ::StaticLoadObject(UObject::StaticClass(), nullptr, *Path);
    }
    else
    {
        Object = ::StaticFindObject(UObject::StaticClass(), nullptr, *Path);
        if (!Object)
        {
			UE_LOG(EngineExtShellLog, Verbose, TEXT("StaticLoadObjectWithoutFlush : %s"), *Path);

            SetAsyncLoadingReturnImmediatelyWhenAnyPackageFinished(true);
			FStreamableManager AssetLoader;
			TSharedPtr<FStreamableHandle> ptrHandle = AssetLoader.RequestAsyncLoad(FStringAssetReference(Path),
				FStreamableDelegate(), FStreamableManager::AsyncLoadHighPriority);
			if (ptrHandle.IsValid())
			{
				while (!ptrHandle->HasLoadCompleted())
				{
					ProcessAsyncLoading(false, false, 0.0f);
				}
				Object = ptrHandle->GetLoadedAsset();
			}

            SetAsyncLoadingReturnImmediatelyWhenAnyPackageFinished(false);
        }
		else
		{
			UE_LOG(EngineExtShellLog, Log, TEXT("Found Object : %s"), *Path);
		}
    }
    return Object;
}

UObject* UEngineExtShell::StaticFindObject(const FString& Path)
{
    return ::StaticFindObject(UObject::StaticClass(), nullptr, *Path);
}

UClass* UEngineExtShell::StaticFindClass(const FString& Path)
{
    return Cast<UClass>(::StaticFindObject(UClass::StaticClass(), nullptr, *Path));
}

void UEngineExtShell::PrintLog(const FString& Log)
{
	UE_LOG(EngineExtShellLog, Log, TEXT("%s"), *Log);
}

void UEngineExtShell::PrintWarningLog(const FString& Log)
{
    UE_LOG(EngineExtShellLog, Warning, TEXT("%s"), *Log);
}

void UEngineExtShell::PrintErrorLog(const FString& Log)
{
    UE_LOG(EngineExtShellLog, Error, TEXT("%s"), *Log);
}

void UEngineExtShell::SetSkeletalMeshComDrawDis(USkeletalMeshComponent* Comp)
{
	int DistanceVar = AKMCharacter::GetCharacterDrawDis();

	Comp->LDMaxDrawDistance = DistanceVar;
	Comp->CachedMaxDrawDistance = DistanceVar;
	Comp->MarkRenderStateDirty();

	//add log for change mesh draw distance
	FString ComName = Comp->GetFullName();
	UE_LOG(EngineExtShellLog, Display, TEXT("change skeletal mesh draw distance using pir.CharacterDrawDis %s, Distance: %d"), *ComName, DistanceVar);
}

void UEngineExtShell::SetComponentDrawDistance(UPrimitiveComponent* Comp)
{
    int DistanceVar = AKMCharacter::GetCharacterDrawDis();

    Comp->LDMaxDrawDistance = DistanceVar;
    Comp->CachedMaxDrawDistance = DistanceVar;
    Comp->MarkRenderStateDirty();

	//add log for change mesh draw distance
	FString ComName = Comp->GetFullName();
	UE_LOG(EngineExtShellLog, Display, TEXT("change skeletal mesh draw distance using pir.CharacterDrawDis %s, Distance: %d"), *ComName, DistanceVar);
}

//////////////////////////////////////////////////////////////////////////
// test crash
//static void Test2(UObject* WorldContextObject)
//{
//    auto DelegateMgr = UGameEngineExt::Get(WorldContextObject)->GetKMDelegateManager();
//    DelegateMgr->Actor->OnInquiryActorInitData.Execute(-1);
//}
//
//static void Test1(UObject* WorldContextObject)
//{
//    Test2(WorldContextObject);
//}

//void UEngineExtShell::CrashTest(UObject* WorldContextObject)
//{
//    Test1(WorldContextObject);
//}
//

void UEngineExtShell::TriggerCrash(bool bOtherThread)
{
    class FAsyncCrashTask
    {
    public:
        FORCEINLINE TStatId GetStatId() const
        {
            RETURN_QUICK_DECLARE_CYCLE_STAT(FAsyncCrashTask, STATGROUP_TaskGraphTasks);
        }

        ENamedThreads::Type GetDesiredThread()
        {
            return ENamedThreads::AnyBackgroundThreadNormalTask;
        }

        static ESubsequentsMode::Type GetSubsequentsMode()
        {
            return ESubsequentsMode::FireAndForget;
        }

        void DoTask(ENamedThreads::Type CurrentThread, const FGraphEventRef& MyCompletionGraphEvent)
        {
            TestCrash();
        }
        void TestCrash()
        {
            UE_LOG(EngineExtShellLog, Log, TEXT("Fake crash happened."));
            UKMDelegateManager* DelegateMgr = nullptr;
            DelegateMgr->Init();
        }
    };

    if (bOtherThread)
    {
        TGraphTask<FAsyncCrashTask>::CreateTask().ConstructAndDispatchWhenReady();
    }
    else
    {
        FAsyncCrashTask().TestCrash();
    }
}

void UEngineExtShell::FlushLog()
{
    FOutputDevice* LogDevice = FPlatformOutputDevices::GetLog();
    if (LogDevice)
    {
#if WITH_LOGGING_TO_MEMORY && UE_BUILD_SHIPPING
        const FString LogFileName = FPlatformOutputDevices::GetAbsoluteLogFilename();
        FOutputDeviceFile::CreateBackupCopy(*LogFileName);
        IFileManager::Get().Delete(*LogFileName);

        FArchive* LogFile = IFileManager::Get().CreateFileWriter(*LogFileName, FILEWRITE_AllowRead);
        if (LogFile)
        {
            LogDevice->Dump(*LogFile);
            LogFile->Flush();
            delete LogFile;
        }
#else
        LogDevice->Flush();
#endif
    }
}

float UEngineExtShell::GetScreenPercentageDefault()
{
    float Value = 0;
    UDeviceProfile* Profile = UDeviceProfileManager::Get().GetActiveProfile();
    bool bGetFromDeviceProfile = false;
    if (Profile)
    {
        TMap<FString, FString> CVarInformation;
        Profile->GatherParentCVarInformationRecursively(CVarInformation);
        FString* StrCVar = CVarInformation.Find(TEXT("r.ScreenPercentage"));
        if (StrCVar)
        {
            FString StrValue;
            StrCVar->Split(TEXT("="), nullptr, &StrValue);
            Value = FCString::Atof(*StrValue);
            bGetFromDeviceProfile = true;
        }
    }
    if(!bGetFromDeviceProfile)
    {
        Value = Scalability::GetQualityLevels().ResolutionQuality;
    }
    return Value;
}

bool UEngineExtShell::GetNearestHitResult(ECollisionChannel DamagedChannel, const TArray<FHitResult>& Hits, const FVector& TargetLocation, FHitResult& OutHit)
{
    OutHit.Reset();
	float NearestDistSquared = 0;
	for (int32 i = 0; i < Hits.Num(); ++i)
	{
        const FHitResult& Hit = Hits[i];
        if (Hit.Component.IsValid() && (Hit.Component->GetCollisionObjectType() == DamagedChannel))
        {
            float DistSquared = FVector::DistSquared(TargetLocation, Hit.ImpactPoint);
            if ((i == 0) || (DistSquared < NearestDistSquared))
            {
                OutHit = Hit;
                NearestDistSquared = DistSquared;
            }
        }
	}
    return OutHit.bBlockingHit; // 可能刚好是爆炸点命中，用IsValidBlockingHit()的话bStartPenetrating会判不过
}