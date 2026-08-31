#pragma once

//#include "PiratesGameGroupPrivateInfo.generated.h"

//
//class APiratesPlayerController;
//
//UENUM()
//enum class EPiratesSurrenderState : uint8
//{
//    Disabled,
//    Free,
//    Voting,
//    Approved,
//    CoolDown
//};
//
//UCLASS()
//class COMMON_API APiratesGameGroupPrivateInfo : public AActor
//{
//    GENERATED_UCLASS_BODY()
//
//public:
//
//    bool IsNetRelevantFor(const AActor* RealViewer, const AActor* ViewTarget, const FVector& SrcLocation) const override;
//
//    void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;
//
//public:
//
//    void Init(int32 InGroupIndex);
//
//    void AddPlayerController(APiratesPlayerController* PC);
//
//    void RemovePlayerController(APiratesPlayerController* PC);
//
//    void StartVotingForSurrender(int32 PlayerId);
//
//    void UpdateVotingStateForSurrender(int32 PlayerId, bool Agreed);
//
//    void FailToVoteForSurrender(int32 PlayerId);
//
//    void EndVotingForSurrender(bool Approved, float CoolDownTime);
//
//    void EndCoolDownForSurrender();
//
//
//public:
//
//    FTimerHandle SurrenderTimerHandle;
//
//public:
//
//    UPROPERTY(BlueprintReadOnly, Category = "PiratesGameGroupPrivateInfo", Replicated)
//    int32 GroupIndex;
//
//    UPROPERTY(BlueprintReadOnly, Category = "PiratesGameGroupPrivateInfo", ReplicatedUsing = OnRep_SurrenderState)
//    EPiratesSurrenderState SurrenderState;
//    UFUNCTION()
//    void OnRep_SurrenderState();
//
//
//protected:
//
//    TArray<APiratesPlayerController*> Controllers;
//
//};