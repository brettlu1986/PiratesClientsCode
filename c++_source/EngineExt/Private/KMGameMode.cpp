// Fill out your copyright notice in the Description page of Project Settings.

#include "KMGameMode.h"
#include "EngineExt.h"

#include "KMPlayerController.h"
#include "EngineExt.h"
#include "Shell/EngineExtActorShell.h"
#include "Game/Delegates/KMDelegateManager.h"
#include "Game/Delegates/GameModeDelegate.h"
#include "Game/GameEngineExt.h"
#include "HttpManager.h"
#include "HttpModule.h"


DEFINE_LOG_CATEGORY_STATIC(KMGameModeLog, Log, All)

AKMGameMode::AKMGameMode(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

void AKMGameMode::InitGameState()
{
    Super::InitGameState();

    // 编辑器预览的时候没有，所以这里得判下
    UGameEngineExt* EngineExt = UGameEngineExt::Get(this);
    if (EngineExt)
    {
        //  这里是最早gamemode和gamestate都有的了时间点
        auto DelegateMgr = EngineExt->GetKMDelegateManager();
        check(IsValid(DelegateMgr));
        DelegateMgr->GameMode->OnInitGameMode.ExecuteIfBound(this, OptionsString);
    }
}

void AKMGameMode::StartPlay()
{
    Super::StartPlay();

    // 编辑器预览的时候没有，所以这里得判下
    UGameEngineExt* EngineExt = UGameEngineExt::Get(this);
    if (EngineExt)
    {
        //  这里是最早gamemode和gamestate都有的了时间点
        auto DelegateMgr = EngineExt->GetKMDelegateManager();
        check(IsValid(DelegateMgr));
        DelegateMgr->GameMode->OnStartPlay.ExecuteIfBound(this, OptionsString);
    }
}

void AKMGameMode::InitGame(const FString& MapName, const FString& Options, FString& ErrorMessage)
{
    UE_LOG(KMGameModeLog, Log, TEXT("AKMGameMode::InitGame %s"), *MapName);
#if PLATFORM_UNIX        
    bool bFork = false;
    bFork = FParse::Param(FCommandLine::Get(), TEXT("fork"));
    if (bFork && IsRunningDedicatedServer())
    {
        GEngine->BlockTillLevelStreamingCompleted(GetWorld());

        //FNavigationSystem::AddNavigationSystemToWorld(*GetWorld(), FNavigationSystemRunMode::GameMode);

        UE_LOG(KMGameModeLog, Log, TEXT("InitGameState FORK BEGIN"));

        auto World = GetWorld();
        if (World)
        {
            GEngine->ShutdownWorldNetDriver(World);
        }
        FHttpModule::Get().GetHttpManager().Flush(false);
        
        FGenericPlatformProcess::EWaitAndForkResult result = FUnixPlatformProcess::WaitAndFork();
        if (result == FGenericPlatformProcess::EWaitAndForkResult::Parent)
        {
            UE_LOG(KMGameModeLog, Log, TEXT("This is Parent by fork, ProcessId is %i"), getpid());
        }
        else if (result == FGenericPlatformProcess::EWaitAndForkResult::Child)
        {
            int TemplateId = 0;
            FParse::Value(FCommandLine::Get(), TEXT("preload-map-id="), TemplateId);
            if (TemplateId == 0)
            {
                UE_LOG(KMGameModeLog, Error, TEXT("WaitAndFork Error TemplateId is 0, ProcessId is %i"), getpid());
                return;
            }
            FString PackageName = UGameMapsSettings::GetGameDefaultMap();
            PackageName = MapName + Options;

            FURL DefaultURL;
            DefaultURL.LoadURLConfig(TEXT("DefaultPlayer"), GGameIni);

            FURL URL(&DefaultURL, *PackageName, TRAVEL_Partial);
            URL.StaticExit();
            URL.StaticInit();
            GetWorld()->Listen(URL);
            UE_LOG(KMGameModeLog, Log, TEXT("This is Child by fork, ProcessId is %i"), getpid());
        }
        else
        {
            UE_LOG(KMGameModeLog, Error, TEXT("This Process Fork Error, ProcessId is %i"), getpid());
        }

        UE_LOG(KMGameModeLog, Log, TEXT("InitGameState FORK END"));
    }
#endif
    Super::InitGame(MapName, Options, ErrorMessage);
}

FString AKMGameMode::ParseInitOptions(const FString &InKey)
{
    return UGameplayStatics::ParseOption(OptionsString, InKey);
}

FString AKMGameMode::InitNewPlayer(class APlayerController* NewPlayerController, const FUniqueNetIdRepl& UniqueId, const FString& Options, const FString& Portal/* = TEXT("")*/)
{
    AKMPlayerController* KMPlayerController = Cast<AKMPlayerController>(NewPlayerController);
    check(IsValid(KMPlayerController));
    auto DelegateMgr = UGameEngineExt::Get(this)->GetKMDelegateManager();
    check(IsValid(DelegateMgr));

    DelegateMgr->GameMode->OnInitNewPlayer.ExecuteIfBound(KMPlayerController, KMPlayerController->GetUniqueID(), 
        UEngineExtActorShell::GetActorNetGuid(KMPlayerController), Options);

	return Super::InitNewPlayer(NewPlayerController, UniqueId, Options, Portal);
}

void AKMGameMode::PostLogin(APlayerController* NewPlayer)
{
    Super::PostLogin(NewPlayer);

    auto DelegateMgr = UGameEngineExt::Get(this)->GetKMDelegateManager();
    check(IsValid(DelegateMgr));

    AKMPlayerController* KMPlayerController = Cast<AKMPlayerController>(NewPlayer);
    check(IsValid(KMPlayerController));

    DelegateMgr->GameMode->OnPostLogin.ExecuteIfBound(KMPlayerController->GetUniqueID());
}

void AKMGameMode::Logout(AController* Exiting)
{
    auto DelegateMgr = UGameEngineExt::Get(this)->GetKMDelegateManager();
    check(IsValid(DelegateMgr));
    DelegateMgr->GameMode->OnLogout.ExecuteIfBound(Exiting->GetUniqueID());

    Super::Logout(Exiting);
}

bool AKMGameMode::ReadyToStartMatch_Implementation()
{
    return true;
}

void AKMGameMode::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
    auto DelegateMgr = UGameEngineExt::Get(this)->GetKMDelegateManager();
    check(IsValid(DelegateMgr));
    DelegateMgr->GameMode->OnEndPlay.ExecuteIfBound();

    Super::EndPlay(EndPlayReason);
}

void AKMGameMode::FinishRestartPlayer(AController* NewPlayer, const FRotator& StartRotation)
{
    // 这里如果不调整rotation，controller的face会不对，导致tick时会将pawn的朝向改掉
    auto Rotation = StartRotation;
    if (NewPlayer->GetPawn())
    {
        Rotation = NewPlayer->GetPawn()->K2_GetActorRotation();
    }
    Super::FinishRestartPlayer(NewPlayer, Rotation);
}

APawn* AKMGameMode::SpawnDefaultPawnFor_Implementation(AController* NewPlayer, AActor* StartSpot)
{
    // don't allow pawn to be spawned with any pitch or roll
    //FRotator StartRotation(ForceInit);
    //StartRotation.Yaw = StartSpot->GetActorRotation().Yaw;
    //FVector StartLocation = StartSpot->GetActorLocation();

    //FActorSpawnParameters SpawnInfo;
    //SpawnInfo.Instigator = Instigator;
    //SpawnInfo.ObjectFlags |= RF_Transient;	// We never want to save default player pawns into a map
    //UClass* PawnClass = GetDefaultPawnClassForController(NewPlayer);

    //FString ScriptType(TEXT("PlayerController"));
    //if (KMPC)
    //{
    //    ScriptType = KMPC->GetPawnScriptType();
    //}
    //AActor* RetActor = UEngineExtActorShell::SpawnActorForScript_LRP(this, PawnClass, ScriptType, StartLocation, StartRotation, SpawnInfo);


    AKMPlayerController* KMPC = Cast<AKMPlayerController>(NewPlayer);
    if (!KMPC)
    {
        UE_LOG(KMGameModeLog, Error, TEXT("Couldn't cast Controller to KMController"));
        return nullptr;
    }

    auto DelegateMgr = UGameEngineExt::Get(this)->GetKMDelegateManager();
    check(IsValid(DelegateMgr));

    // StartLocation和StartRotation等公博去掉FindPlayerStart就可以不传到lua里了
    AActor* RetActor = nullptr;
    auto& Delegate = DelegateMgr->GameMode->OnSpawnDefaultPawnForController;
    if (Delegate.IsBound())
    {
        RetActor = Delegate.Execute(KMPC->GetUniqueID());

        APawn* ResultPawn = Cast<APawn>(RetActor);
        if (ResultPawn == NULL)
        {
            UE_LOG(KMGameModeLog, Log, TEXT("Couldn't spawn player pawn"));
        }
        return ResultPawn;
    }

    return Super::SpawnDefaultPawnFor_Implementation(NewPlayer, StartSpot);
}

void AKMGameMode::GetAllPlayerStart(TArray<APlayerStart*>& Out)
{
    for (TActorIterator<APlayerStart> It(GetWorld()); It; ++It)
    {
        APlayerStart* PlayerStart = *It;
        Out.Add(PlayerStart);
    }    
}

void AKMGameMode::ReplicateStreamingStatus(APlayerController* PC)
{
	//yangjingzhao 2019.3.18
	//We don't implement this function for now, for avoiding huge data replication when initializing player
	//World will update local level streaming state when character is spawned

	//But, this will rise unkown Loading issues in future, if epic use this interface doing other things
	//if this happens, we should reopen/rewrite it

	//override gamemode base; using bUseClientSideLevelStreamingVolumes in worldsettings

	Super::ReplicateStreamingStatus(PC);

}