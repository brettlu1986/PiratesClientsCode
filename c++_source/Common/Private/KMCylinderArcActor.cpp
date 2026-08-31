// Fill out your copyright notice in the Description page of Project Settings.

#include "KMCylinderArcActor.h"
#include "Common.h"
#include "Engine/CollisionProfile.h"
#include "Camera/PlayerCameraManager.h"

DEFINE_LOG_CATEGORY_STATIC(LogKMCylinderArcActor, Log, All);

static const int32 KMMaxCylinderSection = 8;
inline
int32 IndexOfSection(float ArcRatio)
{
	return FMath::Max(FMath::CeilToInt(ArcRatio * KMMaxCylinderSection) - 1, 0);
}

bool GetCylinderHitResultFast(FVector2D Eye, FVector2D Dir, FVector2D Center, float Radius, float& HitNear, float& HitFar)
{
	if (FVector2D::DistSquared(Eye, Center) > Radius * Radius) return false; // 不处理在圆外的情形
	FVector2D EC = Eye - Center;            // 圆心到射线起点的向量
	float B = FVector2D::DotProduct(EC, Dir);    // B大于0，说明射线方向背向圆心
	float C = FVector2D::DotProduct(EC, EC) - Radius * Radius;
	if (C > 0.0f && B > 0.0f)           // 如果射线起点在圆外，并且方向与到圆方向相反，则不相交
		return false;
	float Discr = B * B - C;
	if (Discr < 0.0f)
		return false;
	HitNear = -B - FMath::Sqrt(Discr); // 近处交点
	HitFar = -B + FMath::Sqrt(Discr); // 远处交点
	return true;
}

float GetForwardArcRatio(FVector Eye, FVector Dir, float FrustumDownTangent, FVector Center, float Distance, float Radius)
{
	FVector2D DirProj(Dir.X, Dir.Y);
	float Cosine = FVector::DotProduct(FVector(DirProj, 0.0f).GetSafeNormal(), Dir);
	if (FMath::IsNearlyZero(Cosine)) return 0.0f;
	//float DistanceTangent = Distance / FMath::Abs(Cosine);
	float DistanceTangent = FMath::Sqrt(FMath::Pow(Distance, 2) + FMath::Pow(Distance * FrustumDownTangent, 2));
	float EyeProj = FVector2D::DotProduct(FVector2D(Eye - Center), DirProj);
	//float EyeProj = FVector::DotProduct(Eye - FVector(Center.X, Center.Y, 0.0f), Dir);
	//float Range = (Distance + EyeProj + Radius) * 0.5f / Radius;
	float Range = (DistanceTangent + EyeProj) / Radius;
	//return FMath::Acos(FMath::Clamp(Range, 0.0f, 1.0f)) * INV_PI;
	return FMath::Acos(FMath::Clamp(-Range, -1.0f, 1.0f)) * INV_PI;
}

UKMCylinderProceduralMeshComponent::UKMCylinderProceduralMeshComponent(const FObjectInitializer& ObjectInitializer)
	:Super(ObjectInitializer)
{
	PrimaryComponentTick.bStartWithTickEnabled = true;
	PrimaryComponentTick.bCanEverTick = true;
	FadeDistance = 500000.0f;
	SetGenerateOverlapEvents(false);
	SetCollisionProfileName(UCollisionProfile::NoCollision_ProfileName);
}

void UKMCylinderProceduralMeshComponent::BeginPlay()
{
	Super::BeginPlay();
	// Multi-threaded PhysX cooking.
	bUseAsyncCooking = true;
	InitCylinders();
	InitFadeDistance();
}

void UKMCylinderProceduralMeshComponent::TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
	if (FadeDistance < 1.0f) return;
	UWorld* World = GetWorld();
	if (!IsValid(World)) return;
	APlayerController* PlayerController = World->GetFirstPlayerController();
	if (!IsValid(PlayerController)) return;
	APlayerCameraManager* CameraManager = PlayerController->PlayerCameraManager;
	if (!IsValid(CameraManager)) return;
	AActor* Actor = GetOwner();
	if (!IsValid(Actor)) return;

	FVector Eye = CameraManager->GetCameraLocation();
	FVector Forward = CameraManager->GetActorForwardVector();
	FVector Center = GetComponentLocation();
	FVector Scale = GetComponentScale();
	float Fov = CameraManager->GetFOVAngle();
	float Aspect = CameraManager->GetCameraCachePOV().AspectRatio;
	float Radius = CylinderRadius * FMath::Max(Scale.X, Scale.Y);
	float FrustumDownTangent = FMath::Tan(FMath::DegreesToRadians(Fov * 0.5f)) / Aspect;
	float ForwardArcRatio = GetForwardArcRatio(Eye, Forward, FrustumDownTangent, Center, FadeDistance, Radius);
	//CreateCylinder(0, CylinderRadius, CylinderHeight, ForwardArcRatio, true);
	ArcRatio = ForwardArcRatio;
	CurrentSection = IndexOfSection(ArcRatio);
	EnableSection(CurrentSection);
	SetRelativeRotation(FVector(-Forward.X, -Forward.Y, 0.0f).Rotation());
	float UVX = (1.0f - float(CurrentSection) / float(KMMaxCylinderSection) - FMath::Atan2(Forward.Y, Forward.X) * INV_PI) * 0.5f;
	SetScalarParameterValueOnMaterials(TEXT("UVX"), UVX);
}

void UKMCylinderProceduralMeshComponent::InitCylinders()
{
	CurrentSection = KMMaxCylinderSection - 1;
	for (int32 SectionId = 0; SectionId < KMMaxCylinderSection; SectionId++)
	{
		float Ratio = float(SectionId + 1) / float(KMMaxCylinderSection);
		CreateCylinder(SectionId, CylinderRadius, CylinderHeight, Ratio, true);
		SetMeshSectionVisible(SectionId, SectionId == CurrentSection);
		if (ArcMaterial)
		{
			SetMaterial(SectionId, ArcMaterial);
		}
	}
	// Enable collision data
	//CylinderArcMesh->ContainsPhysicsTriMeshData(true);
}

void UKMCylinderProceduralMeshComponent::InitFadeDistance()
{
	FString FadeDistanceParamName = TEXT("CamDistFadeOffSet");
	GConfig->GetString(TEXT("/Script/Common.CylinderProceduralMesh"), TEXT("CylinderProceduralMeshFadeDistance"), FadeDistanceParamName, GEngineIni);
	if (ArcMaterial)
	{
		float CamDistFadeOffSet = 0.0f;
		if (ArcMaterial->GetScalarParameterValue(*FadeDistanceParamName, CamDistFadeOffSet))
		{
			FadeDistance = CamDistFadeOffSet;
		}
		else
		{
			UE_LOG(LogKMCylinderArcActor, Error, TEXT("Failed to get material instance parameter \"%s\"!"), *FadeDistanceParamName);
		}
	}
}

void UKMCylinderProceduralMeshComponent::EnableSection(int32 InSectionId)
{
	for (int32 SectionId = 0; SectionId < KMMaxCylinderSection; SectionId++)
	{
		SetMeshSectionVisible(SectionId, SectionId == InSectionId);
	}
}

void UKMCylinderProceduralMeshComponent::CreateCylinder(int32 SectionIndex, float InCylinderRadius, float InCylinderHeight, float InArcRatio, bool bCreateCollision)
{
	Vertices.Empty(Vertices.Num());
	Triangles.Empty(Triangles.Num());
	Normals.Empty(Normals.Num());
	UV0.Empty(UV0.Num());
	Tangents.Empty(Tangents.Num());

	float AnglePerSlice = 2.0f * PI / (float)SliceNum;
	float UVPerSlice = 1.0f / (float)SliceNum;
	int32 FinishIndex = SliceNum * InArcRatio;
	for (int32 Index = 0; Index <= FinishIndex; Index++)
	{
		float Arc = AnglePerSlice * Index + HALF_PI - AnglePerSlice * 0.5f * FinishIndex;
		float U = UVPerSlice * Index;
		float X = FMath::Sin(Arc) * InCylinderRadius;
		float Y = FMath::Cos(Arc) * InCylinderRadius;
		Vertices.Add(FVector(X, Y, 0));
		Vertices.Add(FVector(X, Y, InCylinderHeight));
		UV0.Add(FVector2D(U, 1));
		UV0.Add(FVector2D(U, 0));
		Normals.Add(FVector(1, 0, 0));
		Normals.Add(FVector(1, 0, 0));
		Tangents.Add(FProcMeshTangent(0, 1, 0));
		Tangents.Add(FProcMeshTangent(0, 1, 0));
	}
	for (int32 Index = 0; Index < FinishIndex; Index++)
	{
		Triangles.Add(Index * 2 + 0);
		Triangles.Add(Index * 2 + 2);
		Triangles.Add(Index * 2 + 1);
		Triangles.Add(Index * 2 + 2);
		Triangles.Add(Index * 2 + 3);
		Triangles.Add(Index * 2 + 1);
	}

	CreateMeshSection(SectionIndex, Vertices, Triangles, Normals, UV0, {}, Tangents, bCreateCollision);
}

FBoxSphereBounds UKMCylinderProceduralMeshComponent::CalcBounds(const FTransform& LocalToWorld) const
{
	FVector Center = LocalToWorld.GetLocation();
	Center.Z += CylinderHeight * 0.5f;
	FVector Radius3D = LocalToWorld.GetScale3D();
	FVector Extend = FVector(CylinderRadius * Radius3D.X, CylinderRadius * Radius3D.Y, CylinderHeight * 0.5f * Radius3D.Z);
	return FBoxSphereBounds(Center, Extend, Extend.Size());
}

// Sets default values
AKMCylinderArcActor::AKMCylinderArcActor()
{
	CylinderArcMesh = CreateDefaultSubobject<UKMCylinderProceduralMeshComponent>(TEXT("GeneratedMesh"));
	RootComponent = CylinderArcMesh;
	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;
}

void AKMCylinderArcActor::OnConstruction(const FTransform& Transform)
{
	Super::OnConstruction(Transform);
	CylinderArcMesh->InitCylinders();
}

#if WITH_EDITOR

void AKMCylinderArcActor::PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent)
{
	Super::PostEditChangeProperty(PropertyChangedEvent);
	FName PropertyName = PropertyChangedEvent.Property ? PropertyChangedEvent.Property->GetFName() : NAME_None;
	if (PropertyName == TEXT("CylinderArcMesh")
		)
	{
		CylinderArcMesh->InitCylinders();
		float UVX = (1.0f - CylinderArcMesh->ArcRatio) * 0.5f;
		CylinderArcMesh->SetScalarParameterValueOnMaterials(TEXT("UVX"), UVX);
	}
}

#endif//WITH_EDITOR
