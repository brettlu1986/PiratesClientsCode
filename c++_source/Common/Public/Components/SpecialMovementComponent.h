// 简单粗暴版移动同步，当正式版移动同步没做好时先用这个，做好了就不用了
#pragma once

#include "GameFramework/CharacterMovementComponent.h"
#include "SpecialMovementComponent.generated.h"

//#define USE_AICONTROLLER

UCLASS()
class COMMON_API USpecialMovementComponent : public UPawnMovementComponent
{
public:
	GENERATED_BODY()
	DECLARE_DYNAMIC_DELEGATE_FourParams(FOnSpecialMovementChanged, USpecialMovementComponent*, Component, const FVector&, Location, float, Yaw, int, MoveState);
	FOnSpecialMovementChanged OnSpecialMovementChanged;

public:
	USpecialMovementComponent(const FObjectInitializer& ObjectInitializer);
	virtual void Init(bool ControlledByServer);
	virtual void Uninit();
	virtual void BeginPlay() override;
	virtual void TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction) override;
	virtual void SetSynData(const FVector& Location, float Yaw, int MoveState);
	virtual int GetMoveState() { return 0; }
	virtual bool IsValid() const { return PawnOwner && !PawnOwner->IsPendingKill() && UpdatedPrimitive; }

protected:
	virtual void TickControlledByServer(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction);
	virtual void TickControlledBySelf(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction);

protected:
	bool ControlledByServer;
	FVector LastSavedLocation;
	float LastSavedYaw;

#ifndef USE_AICONTROLLER
	FVector DestLocation;
	FVector SrcLocation;
	float DestLocationPercentage;

	FQuat DestRotation;
	FQuat SrcRotation;
	float DestRotationPercentage;
#endif
};
