#pragma once

//#include "KMPlayerController.h"
#include "KMSmartPlayerController.h"
#include "SmoothTravel.h"

#include "PiratesPlayerController.generated.h"

UCLASS()
class COMMON_API APiratesPlayerController : public AKMPlayerController, public ISmoothTravel
{
    GENERATED_UCLASS_BODY()

public:

    virtual void BeginPlay() override;

    virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;

    virtual void InitPlayerState() override;

    virtual void OnActorChannelOpen(class FInBunch& InBunch, class UNetConnection* Connection) override;

    virtual void ClientRestart_Implementation(APawn* NewPawn) override;

    virtual void PreClientTravel(const FString& PendingURL, ETravelType TravelType, bool bIsSeamlessTravel);

    virtual void Destroyed() override;

    virtual void SmoothTravelSwap_Implementation(AActor* Actor) override;

    virtual void SmoothTravelPreTravel_Implementation() override;

	virtual void SetViewTarget(class AActor* NewViewTarget, FViewTargetTransitionParams TransitionParams = FViewTargetTransitionParams()) override;

	void RequestExitGame(); 

	//yangjingzhao add for toggle debug camera
	virtual void AddCheats(bool bForce /* = false */);

    /** Clean up when a Pawn's player is leaving a game. Base implementation destroys the pawn. */
    virtual void PawnLeavingGame() override;

public:
    UFUNCTION(BlueprintCallable, Category = "PiratesPlayerController")
    void StartSpectating();

    UFUNCTION()
    void OnMarkClientPlayerSelfReady();

    UFUNCTION(BlueprintPure)
    bool IsClientPlayerSelfReady() { return ClientPlayerSelfReady; }

    UFUNCTION(BlueprintCallable, Category = "PiratesPlayerController")
    void OnTouchActorBegin(AActor* ClickActor);

    UFUNCTION(BlueprintCallable, Category = "PiratesPlayerController")
    void OnTouchActorEnd(AActor* ClickActor);
	
    UFUNCTION(BlueprintCallable, Category = "PiratesPlayerController")
    void OnLeaveTouchActor(AActor* ClickActor);

    /** add a camera lens effect (e.g. blood). */
    UFUNCTION(reliable, client, BlueprintCallable, Category = "Game|Feedback")
    void ClientAddCameraLensEffect(TSubclassOf<class AEmitterCameraLensEffectBase> LensEffectEmitterClass);

    /** remove a camera lens effect (e.g. blood). */
    UFUNCTION(reliable, client, BlueprintCallable, Category = "Game|Feedback")
    void ClientRemoveCameraLensEffect(TSubclassOf<class AEmitterCameraLensEffectBase> LensEffectEmitterClass);

private:
    //Pawn before smooth travel. Used in client.
    APawn *OldPawnInSmoothTravel;

    //Pawn location and rotation when player controller destroyed.
    //Used for transfer these data to hub server when logout in smooth travel case.
    //Server use.
    UPROPERTY()
    FVector PawnExitLocation;

    UPROPERTY()
    float PawnExitYaw;

    bool ClientPlayerSelfReady;

    AActor* TouchedActor;
};