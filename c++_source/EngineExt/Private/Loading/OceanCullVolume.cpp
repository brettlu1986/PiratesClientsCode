#include "Loading/OceanCullVolume.h"
#include "EngineExt.h"

AOceanCullVolume::AOceanCullVolume(const FObjectInitializer& ObjectInitializer)
	:Super(ObjectInitializer)
{
}

bool AOceanCullVolume::CheckVolumeInFrustum(UCanvas* Canvas)
{
	//Canvas.IsValid() && Canvas->SceneView && Canvas->SceneView->ViewFrustum.IntersectSphere(Location, 1.0f);
	if (!Canvas)
	{
		return false;
	}

	FVector Origin = FVector(0, 0, 0);
	FVector Extends = FVector(0, 0, 0);
	GetActorBounds(false, Origin, Extends);

	bool interactable = Canvas->SceneView->ViewFrustum.IntersectBox(Origin, Extends);

	float Distance = 0.0f;

	if (GetWorld() &&
		GetWorld()->GetFirstPlayerController() && 
		GetWorld()->GetFirstPlayerController()->GetPawn())
	{
		Distance = FVector::Dist(GetWorld()->GetFirstPlayerController()->GetPawn()->GetActorLocation(), Origin);
	}

	if (interactable && Distance < CullDistance)
	{
		//show ocean
		return true;
	}

	return false;
}