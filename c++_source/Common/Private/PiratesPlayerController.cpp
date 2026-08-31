#include "PiratesPlayerController.h"
#include "Common.h"
#include "PiratesLocalPlayer.h"
#include "SmoothTravel.h"
#include "Game/GameCommon.h"
#include "Shell/CommonShell.h"
#include "PiratesGameMode.h"
#include "ReplicatedProtoCallComponent.h"
#include "ReplicatedProtoPropertyComponent.h"
#include "GameEngineExt.h"
#include "Game/Delegates/PlayerDelegate.h"
#include "Shell/EngineExtActorShell.h"
#include "Components/InputComponent.h"
#include "Game/Delegates/KMDelegateManager.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "Game/Delegates/PiratesGameMiscDelegate.h"
#include "Pawns/PiratesMountCharacter.h"
#include "Game/Delegates/ActorDelegate.h"
#include "Particles/EmitterCameraLensEffectBase.h"
#include "Kismet/GameplayStatics.h"

DEFINE_LOG_CATEGORY_STATIC(PiratesPlayerControllerLog, Log, All)


APiratesPlayerController::APiratesPlayerController(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{
    static FName DefaultRPCCompName = FName("ReplicatedProtoCallComponent");
    CreateOptionalDefaultSubobject<UReplicatedProtoCallComponent>(DefaultRPCCompName);

    static FName DefaultRPCPropertyCompName = FName("ReplicatedProtoPropertyComponent");
    auto PropertyComponent = CreateOptionalDefaultSubobject<UReplicatedProtoPropertyComponent>(DefaultRPCPropertyCompName);
    PropertyComponent->SetClientRecvType(false);
    TouchedActor = nullptr;
	bShowMouseCursor = true;
    bEnableTouchOverEvents = true;
    OldPawnInSmoothTravel = NULL;
    ClientPlayerSelfReady = false;
    // bAutoManageActiveCameraTarget = false;


}

void APiratesPlayerController::BeginPlay()
{
	Super::BeginPlay();
	auto GameCommon = UGameCommon::Get(this);
	if (GameCommon)
	{
		GameCommon->PlayerControllerUpdate(this);
	}
	if (InputComponent)
	{
		InputComponent->BindKey(EKeys::Android_Back, IE_Pressed, this, &APiratesPlayerController::RequestExitGame);
		InputComponent->BindKey(EKeys::End, IE_Pressed, this, &APiratesPlayerController::RequestExitGame);
		InputComponent->BindKey(EKeys::Escape, IE_Pressed, this, &APiratesPlayerController::RequestExitGame);
	}
}

void APiratesPlayerController::Destroyed()
{
    if (GetPawn())
    {
        PawnExitLocation = GetPawn()->GetActorLocation();
        PawnExitYaw = GetPawn()->GetActorRotation().Yaw;
    }

    Super::Destroyed();
}

void APiratesPlayerController::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);
}

void APiratesPlayerController::ClientRestart_Implementation(APawn* NewPawn)
{
    UE_LOG(PiratesPlayerControllerLog, Log, TEXT("APiratesPlayerController::ClientRestart_Implementation client restart"));
    Super::ClientRestart_Implementation(NewPawn);
    auto localPlayer = Cast<UPiratesLocalPlayer>(GetLocalPlayer());
    auto bInSmoothTravel = localPlayer != NULL && localPlayer->InSmoothTravel();
    if (NewPawn != NULL)
    {
        //if (NewPawn->IsA(APiratesMountCharacter::StaticClass()))
        //    return;
        if (bInSmoothTravel)
        {
            UE_LOG(PiratesPlayerControllerLog, Log,
                TEXT("APiratesPlayerController::ClientRestart_Implementation: Reset smooth travel to false."));

            localPlayer->SetSmoothTravel(false);

            //Swap later than set smooth travel to false to give a chance to set custom view target.
            AActor *SwapFrom = OldPawnInSmoothTravel;
            ISmoothTravel *SwapTo = Cast<ISmoothTravel>(NewPawn);
            if (SwapFrom != NULL && SwapTo != NULL)
            {
                UE_LOG(PiratesPlayerControllerLog, Log, TEXT("APiratesPlayerController::ClientRestart_Implementation SmoothTravelSwap"));
                SwapTo->Execute_SmoothTravelSwap(NewPawn, SwapFrom);
            }
            else
            {
                UE_LOG(PiratesPlayerControllerLog, Log, TEXT("APiratesPlayerController::ClientRestart_Implementation Skip SmoothTravelSwap"));
            }

            NewPawn->SetActorHiddenInGame(false);

            if (OldPawnInSmoothTravel)
            {
                UE_LOG(PiratesPlayerControllerLog, Log, TEXT("APiratesPlayerController::ClientRestart_Implementation destroy old pawn"));
                GetWorld()->DestroyActor(OldPawnInSmoothTravel);
                OldPawnInSmoothTravel = NULL;
            }
        }

        // 这里保证了controller里的pawn和pawn里的controller都设进去了
        UGameEngineExt* Ext = UGameEngineExt::Get(this);
        if (Ext)
        {
            Ext->GetKMDelegateManager()->Player->OnClientRestart.ExecuteIfBound(this, GetUniqueID(), UEngineExtActorShell::GetActorNetGuid(this),
                NewPawn, NewPawn->GetUniqueID(), UEngineExtActorShell::GetActorNetGuid(NewPawn));
        }
    }
}

void APiratesPlayerController::InitPlayerState()
{
    Super::InitPlayerState();

    if (PlayerState != nullptr)
    {
        PlayerState->bAlwaysRelevant = true;
        PlayerState->bOnlyRelevantToOwner = false;
    }
}

void APiratesPlayerController::OnActorChannelOpen(class FInBunch& InBunch, class UNetConnection* Connection)
{
    if (InBunch.bClose || InBunch.AtEnd())
    {
        Super::OnActorChannelOpen(InBunch, Connection);
        return;
    }

    ULocalPlayer* LocalPlayer = NULL;
    for (FLocalPlayerIterator It(GEngine, GetWorld()); It; ++It)
    {
        LocalPlayer = *It;
        break;
    }

    check(LocalPlayer);
    UPiratesLocalPlayer* PiratesLocalPlayer = Cast<UPiratesLocalPlayer>(LocalPlayer);
    if (PiratesLocalPlayer && PiratesLocalPlayer->InSmoothTravel())
    {
        APlayerController *OldPlayerController = LocalPlayer->PlayerController;
        if (OldPlayerController != NULL)
        {
            Execute_SmoothTravelSwap(this, OldPlayerController);

            OldPawnInSmoothTravel = OldPlayerController->GetPawn();
            OldPlayerController->SetPawn(NULL);

            //OldPlayerController will be destroyed in Super::OnActorChannelOpen
        }
    }

    Super::OnActorChannelOpen(InBunch, Connection);
}

void APiratesPlayerController::PreClientTravel(const FString& PendingURL, ETravelType TravelType, bool bIsSeamlessTravel)
{
    Super::PreClientTravel(PendingURL, TravelType, bIsSeamlessTravel);
    UPiratesLocalPlayer *LocalPlayer = Cast<UPiratesLocalPlayer>(GetLocalPlayer());
    if (LocalPlayer && LocalPlayer->InSmoothTravel())
    {
        UE_LOG(PiratesPlayerControllerLog, Log, TEXT("UGamePackageMap::PreClientTravel. %s"), *GetName());
        Execute_SmoothTravelPreTravel(this);
        ISmoothTravel* SmoothTravelActor = Cast<ISmoothTravel>(GetPawn());
        if (SmoothTravelActor)
        {
            UE_LOG(PiratesPlayerControllerLog, Log, TEXT("UGamePackageMap::PreClientTravel. %s"), *GetPawn()->GetName());
            SmoothTravelActor->Execute_SmoothTravelPreTravel(GetPawn());
        }
        else
        {
            UE_LOG(PiratesPlayerControllerLog, Log, TEXT("UGamePackageMap::PreClientTravel. Skip."));
        }
    }
}

void APiratesPlayerController::SmoothTravelSwap_Implementation(AActor* Actor)
{
    APiratesPlayerController* SwapFrom = Cast<APiratesPlayerController>(Actor);
    if (SwapFrom)
    {
        //Rep Cache.POV to prevent that before the next tick PlayerCameraManager::DoUpdateCamera,
        //POV.Location and POV.Rotation remain zero which may cause some components display wrong in this tick.
        //Currently InfiniteSystemComponent use these properties
        //to calculate display related parameters.

        FMinimalViewInfo InPOV = SwapFrom->PlayerCameraManager->GetCameraCachePOV();
        PlayerCameraManager->SetCameraCachePOV(InPOV);

        //BP_Weather system call GetPlayerPawn(0) in its tick function. So we need ensure
        //PlayerController[0] always has valid pawn.
        SetPawn(SwapFrom->GetPawn());
    }
}

void APiratesPlayerController::SmoothTravelPreTravel_Implementation()
{
}

void APiratesPlayerController::SetViewTarget(AActor* NewViewTarget, FViewTargetTransitionParams TransitionParams)
{
	Super::SetViewTarget(NewViewTarget, TransitionParams);
	if (ACameraActor* CameraActor = Cast<ACameraActor>(NewViewTarget))
	{
		UCameraComponent* CameraComponent = CameraActor->GetCameraComponent();
		if (CameraComponent)
		{
			CameraComponent->SetConstraintAspectRatio(false);
		}
	}
}

void APiratesPlayerController::RequestExitGame()
{
	auto GameCommon = UGameCommon::Get(this);
	if (GameCommon)
	{
		GameCommon->GetGameDelegateManager()->GameMisc->OnRequestExitGame.Execute();
	}

}

void APiratesPlayerController::StartSpectating()
{
    if (GetLocalRole() == ROLE_Authority)
    {
        ChangeState(NAME_Spectating);
        ClientGotoState(NAME_Spectating);
    }
}

void APiratesPlayerController::OnMarkClientPlayerSelfReady()
{
    ClientPlayerSelfReady = true;
    UGameCommon::Get(this)->GetGameDelegateManager()->GameMisc->OnClientPlayerSelfReady.Broadcast();
}

void APiratesPlayerController::OnTouchActorBegin(AActor* ClickActor)
{
    TouchedActor = ClickActor;
}

void APiratesPlayerController::OnTouchActorEnd(AActor* ClickActor)
{
    if (TouchedActor == ClickActor)
    {
        UGameEngineExt* Ext = UGameEngineExt::Get(this);
        if (Ext)
        {
            Ext->GetKMDelegateManager()->OnActorTouched.ExecuteIfBound(ClickActor);
        }
    }

    TouchedActor = nullptr;
}

void APiratesPlayerController::OnLeaveTouchActor(AActor* ClickActor)
{
    if (ClickActor == TouchedActor)
        TouchedActor = nullptr;
}

void APiratesPlayerController::AddCheats(bool bForce)
{
	if (!UE_BUILD_SHIPPING && !UE_BUILD_TEST)
	{
		CheatManager = NewObject<UCheatManager>(this, CheatClass);
		CheatManager->InitCheatManager();

		return;
	}

	Super::AddCheats(bForce);
}

void APiratesPlayerController::PawnLeavingGame()
{
    UGameEngineExt* Game = UGameEngineExt::Get(this);
    UActorDelegate* ActorDelegate = Game ? Game->GetKMDelegateManager()->Actor : nullptr;
    if (ActorDelegate)
    {
        ActorDelegate->OnPawnLeavingGame.Broadcast(this,
            GetUniqueID(), GetLogicInstanceId());
    }
/*
    if(GetPawn() && GetPawn()->IsA(APiratesMountCharacter::StaticClass()))
    {
        return;
    }

    Super::PawnLeavingGame();
*/
}

void APiratesPlayerController::ClientAddCameraLensEffect_Implementation(TSubclassOf<AEmitterCameraLensEffectBase> LensEffectEmitterClass)
{
    if (PlayerCameraManager != NULL)
    {
        PlayerCameraManager->AddCameraLensEffect(LensEffectEmitterClass);
    }
}

void APiratesPlayerController::ClientRemoveCameraLensEffect_Implementation(TSubclassOf<AEmitterCameraLensEffectBase> LensEffectEmitterClass)
{
    if (PlayerCameraManager != NULL)
    {
        TArray<AActor*> OutActors;
        UGameplayStatics::GetAllActorsOfClass(this, LensEffectEmitterClass, OutActors);
        for (AActor* Actor : OutActors)
        {
            if (AEmitterCameraLensEffectBase* Emitter = Cast<AEmitterCameraLensEffectBase>(Actor))
            {
                PlayerCameraManager->RemoveCameraLensEffect(Emitter);
                Emitter->Deactivate();
            }
        }
    }
}