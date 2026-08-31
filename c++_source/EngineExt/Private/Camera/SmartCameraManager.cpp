// Fill out your copyright notice in the Description page of Project Settings.
#include "SmartCameraManager.h"
#include "EngineExt.h"
#include "KMCameraActor.h"
#include "LazyFollowCameraHead.h"
#include "FocusTargetCameraHead.h"

struct USmartCameraManager::Impl
{
	USmartCameraManager *Self;
    TWeakObjectPtr<AActor> CurrentAttachedActor;
	ECameraName::Type CurrentCameraMode = ECameraName::None;
	int CurrentCameraIdx = 1;

	Impl(USmartCameraManager *OuterManager) : Self(OuterManager), CurrentAttachedActor(nullptr) { }

    void CleanUp()
    {
        if (Self && Self->CameraActorArray.Num() > CurrentCameraIdx)
        {
            AKMCameraActor* CameraActor = Self->CameraActorArray[CurrentCameraIdx];

            if (CameraActor)
                CameraActor->SetCameraHeadDelegate(nullptr);
        }
    }

	void InitCameraActorArray()
	{
		Self->CameraActorArray.SetNum(2);
	}

	AKMCameraActor *SetupNextCameraActorToHead(UCameraHeadBase *NextCameraHead)
	{
		auto CurrentCameraActor = GetCurrentCameraActor();
		CurrentCameraIdx = 1 - CurrentCameraIdx;
        AKMCameraActor *NextCameraActor = nullptr;
		if (CurrentCameraIdx < Self->CameraActorArray.Num())
		{
            AKMCameraActor *CameraActor = Self->CameraActorArray[CurrentCameraIdx];
			if (nullptr == CameraActor || !CameraActor->IsValidLowLevel())
			{
				CameraActor = Self->PlayerController->GetWorld()->SpawnActor<AKMCameraActor>();
				CameraActor->GetCameraComponent()->bConstrainAspectRatio = false;
				CameraActor->GetCameraComponent()->FieldOfView = 80;
				Self->CameraActorArray[CurrentCameraIdx] = CameraActor;
			}
			NextCameraActor = CameraActor;
		}
		if (NextCameraActor)
		{
			NextCameraActor->SetCameraHeadDelegate(Self);
			NextCameraHead->SetCameraActor(NextCameraActor);
			// 需要在设置CameraHead之后再Sync，否则可能在CameraHead中找不到CameraActor
			SyncCameraActorTransformToCameraHead(CurrentCameraActor, NextCameraHead);
		}
		return NextCameraActor;
	}

    AKMCameraActor *GetCurrentCameraActor()
	{
        AKMCameraActor *RetCamera = nullptr;
		if (CurrentCameraIdx < Self->CameraActorArray.Num())
		{
            AKMCameraActor *CameraActor = Self->CameraActorArray[CurrentCameraIdx];
			if (nullptr != CameraActor && CameraActor->IsValidLowLevel())
			{
				RetCamera = CameraActor;
			}
		}
		return RetCamera;
	}

	void SyncCameraActorTransformToCameraHead(AActor *OriginCameraActor, UCameraHeadBase *CameraHead)
	{
		if (nullptr != OriginCameraActor && OriginCameraActor->IsValidLowLevel() &&
			nullptr != CameraHead && CameraHead->IsValidLowLevel())
		{
			UCameraComponent *CameraComponent = Cast<UCameraComponent>(OriginCameraActor->GetComponentByClass(UCameraComponent::StaticClass()));
			FTransform Transform;
			if (CameraComponent)
			{
				Transform = CameraComponent->GetComponentTransform();
			}
			else
			{
				Transform = OriginCameraActor->GetTransform();
			}
			CameraHead->SetTargetCameraTransform(Transform);
		}
	}

	UCameraHeadBase *GetCameraHeadWithName(ECameraName::Type CameraMode)
	{
		switch (CameraMode)
		{
			case ECameraName::LazyFollowPlayerCamera:
				return Self->LazyFollowCameraHead;
			case ECameraName::FocusPlayerCamera:
				return Self->FocusTargetCameraHead;
			default:
				return nullptr;
		}
	}

	void SetCurrentCamera(ECameraName::Type CameraMode, UCameraHeadBase *CameraHead, float BlendTime)
	{
        AActor* AttachedActor = GetAttachedActor();
        if (!(IsValid(CameraHead) && Self->PlayerController->IsValidLowLevel() && IsValid(AttachedActor)))
            return;

        Self->PendingCamera = ECameraName::None;
		if (CurrentCameraMode == CameraMode)
		{
			auto Camera = GetCurrentCameraActor();
			auto ViewTarget = Self->PlayerController->GetViewTarget();
			if (ViewTarget != Camera)
			{
				SyncCameraActorTransformToCameraHead(ViewTarget, CameraHead);
				Self->PlayerController->SetViewTargetWithBlend(Camera, BlendTime);
			}
			return;
		}
		CurrentCameraMode = CameraMode;
		if (Self->CurrentCameraHead.IsValid())
		{
			CameraHead->SyncCameraParamsWithHead(Self->CurrentCameraHead.Get());
		}
		Self->CurrentCameraHead = CameraHead;
		Self->CurrentCameraHead->AttachToActor(AttachedActor);
		auto Camera = SetupNextCameraActorToHead(CameraHead);
		Self->PlayerController->SetViewTargetWithBlend(Camera, BlendTime, EViewTargetBlendFunction::VTBlend_Linear, 0, true);
	}

    AActor* GetAttachedActor()
    {
        return CurrentAttachedActor.IsValid() ? CurrentAttachedActor.Get() : Self->PlayerController->GetPawn();
    }
};

USmartCameraManager::~USmartCameraManager()
{
    if (impl.IsValid())
        impl->CleanUp();
}

void USmartCameraManager::Init()
{
	LazyFollowCameraHead = NewObject<ULazyFollowCameraHead>();
	FocusTargetCameraHead = NewObject<UFocusTargetCameraHead>();
	impl = MakeShareable(new Impl(this));
	impl->InitCameraActorArray();
}

void USmartCameraManager::SetPlayerController(APlayerController *Controller)
{
	if (Controller != nullptr && Controller->IsValidLowLevel())
	{
		PlayerController = Controller;
	}
	else
	{
		PlayerController = nullptr;
	}
}

void USmartCameraManager::UseCamera(ECameraName::Type Name, AActor* AttachedActor/* = nullptr*/, float BlendTime /* = 1.0*/ , bool AutoSwitch/* = true*/)
{
    impl->CurrentAttachedActor = AttachedActor;
	if (UsingCustomCamera)
	{
		PendingCamera = Name;
	}
	else
	{
		auto CameraHead = impl->GetCameraHeadWithName(Name);
		if (CheckCameraHead(CameraHead))
		{
			impl->SetCurrentCamera(Name, CameraHead, BlendTime);
		}
		else if (AutoSwitch)
		{
			auto AvailableType = SwitchToAvailableCameraHead(BlendTime);
			PendingCamera = AvailableType == Name ? ECameraName::None : Name;
		}
	}
}

void USmartCameraManager::UpdateCamera(float DeltaSeconds)
{
	if (PendingCamera != ECameraName::None)
	{
		UseCamera(PendingCamera, 0, false);
	}

	if (CheckCameraHead(CurrentCameraHead.Get()))
	{
		CurrentCameraHead->UpdateCamera(DeltaSeconds);
	}
	else
	{
		auto OldCameraMode = impl->CurrentCameraMode;
		auto AvailableType = SwitchToAvailableCameraHead(0);
		PendingCamera = AvailableType == OldCameraMode ? ECameraName::None : OldCameraMode;
	}

    if (IsSeamlessTravel)
    {
        IsSeamlessTravel = false;
        
        if (CurrentCameraHead.IsValid() && CurrentCameraHead->IsValidLowLevel())
        {
            CurrentCameraHead->SetCameraLocationAndRotation(TravelSaveLocation, TravelSaveRotation);
            CurrentCameraHead->SetTargetTransform(TravelSaveTransform.GetLocation(), TravelSaveTransform.GetRotation().Rotator());
        }
    }
}

void USmartCameraManager::RotateCameraManually(const FRotator &RotationOffset)
{
	if (CurrentCameraHead.IsValid() && CurrentCameraHead->IsValidLowLevel())
	{
		CurrentCameraHead->RotateCameraManually(RotationOffset);
	}
}

void USmartCameraManager::EnableRotateCameraManually(bool Enable)
{
	if (CurrentCameraHead.IsValid() && CurrentCameraHead->IsValidLowLevel())
	{
		CurrentCameraHead->SetRotationManually(Enable);
	}
}

void USmartCameraManager::ResetCameraLocation()
{
	if (CurrentCameraHead.IsValid() && CurrentCameraHead->IsValidLowLevel())
	{
		CurrentCameraHead->FreezeCameraLoc(false);
		CurrentCameraHead->ResetCameraLocRot();
	}
}

void USmartCameraManager::SetFocusActor(AActor *Actor)
{
	FocusTargetCameraHead->SetFocusActor(Actor);
	if (!CheckCameraHead(CurrentCameraHead.Get()))
	{
		SwitchToAvailableCameraHead(0);
	}
}

void USmartCameraManager::RefreshAttachedActor()
{
	if (CurrentCameraHead.IsValid() && CurrentCameraHead->IsValidLowLevel() &&
		PlayerController.IsValid() && PlayerController->IsValidLowLevel())
	{
		CurrentCameraHead->FreezeCameraLoc(false);
		CurrentCameraHead->AttachToActor(impl->GetAttachedActor());
		if (!UsingCustomCamera)
		{
			PlayerController->SetViewTargetWithBlend(impl->GetCurrentCameraActor(), 0);
		}
	}
}

void USmartCameraManager::SetCameraArmLength(float ArmLength)
{
    if (CurrentCameraHead.IsValid())
    {
        CurrentCameraHead->SetCameraArmLength(ArmLength);
    }
}

void USmartCameraManager::SetCameraPitch(float Pitch)
{
    if (CurrentCameraHead.IsValid())
    {
        CurrentCameraHead->SetCameraPitch(Pitch);
    }
}

void USmartCameraManager::SetAttachLocationOffset(FVector Offset)
{
    if (CurrentCameraHead.IsValid())
    {
        CurrentCameraHead->SetAttachLocationOffset(Offset);
    }
}

void USmartCameraManager::SetCustomViewTarget(class AActor* NewViewTarget, float BlendTime /* = 0 */, enum EViewTargetBlendFunction BlendFunc /* = VTBlend_Linear */, float BlendExp /* = 0 */, bool bLockOutgoing /* = false */)
{
	if (PlayerController.IsValid() && PlayerController->IsValidLowLevel())
	{
		UsingCustomCamera = true;
		PlayerController->SetViewTargetWithBlend(NewViewTarget, BlendTime, BlendFunc, BlendExp, bLockOutgoing);
	}
}

void USmartCameraManager::ResumeAutoCamera(float BlendTime/* = 0.0f*/)
{
	UsingCustomCamera = false;
	if (PendingCamera != ECameraName::None)
	{
		UseCamera(PendingCamera, nullptr, BlendTime);
	}
	else
	{
		UseCamera(impl->CurrentCameraMode, nullptr, BlendTime);
	}
}

bool USmartCameraManager::CheckCameraHead(UCameraHeadBase *CameraHead)
{
    if (IsValid(CameraHead) && CameraHead->IsValidLowLevel())
	{
		return CameraHead->IsAvailable();
	}
	return false;
}

ECameraName::Type USmartCameraManager::SwitchToAvailableCameraHead(float BlendTime)
{
	ECameraName::Type RetType = ECameraName::None;
	if (CheckCameraHead(FocusTargetCameraHead))
	{
		RetType = ECameraName::FocusPlayerCamera;
		impl->SetCurrentCamera(RetType, FocusTargetCameraHead, BlendTime);
	}
	else if (CheckCameraHead(LazyFollowCameraHead))
	{
		RetType = ECameraName::LazyFollowPlayerCamera;
		impl->SetCurrentCamera(RetType, LazyFollowCameraHead, BlendTime);
	}
	return RetType;
}

void USmartCameraManager::FreezeCameraLoc(bool Freeze)
{
	CurrentCameraHead->FreezeCameraLoc(true);
}

void USmartCameraManager::UpdateSeamlessTravelCamera(bool bReload, FVector& Location, FRotator& Rotation, FTransform& Transform)
{
    if (bReload)
    {
        IsSeamlessTravel = true;
        TravelSaveLocation = Location;
        TravelSaveRotation = Rotation;
        TravelSaveTransform = Transform;
    }
    else if (CurrentCameraHead.IsValid() && CurrentCameraHead->IsValidLowLevel())
    {
        CurrentCameraHead->GetCameraLocationAndRotation(Location, Rotation);
        
        FVector TargetLocation;
        FRotator TargetRotation;
        CurrentCameraHead->GetTargetTransform(TargetLocation, TargetRotation);
        Transform = FTransform(TargetRotation, TargetLocation);
    }
}

