//// Fill out your copyright notice in the Description page of Project Settings.
//
#include "KMSignificanceComponent.h"
#include "EngineExt.h"
//#include "KMSignificanceComponent.h"
//#include "KMSignificanceManager.h"
//
//
//// Sets default values for this component's properties
//UKMSignificanceComponent::UKMSignificanceComponent()
//	: SignificanceTag(TEXT("KMDefaultTag"))
//	, CachedManager(nullptr)
//{
//	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
//	// off to improve performance if you don't need them.
//	PrimaryComponentTick.bCanEverTick = true;
//}
//
//
//void UKMSignificanceComponent::TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction)
//{
//	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
//	
//	// get target object
//	AActor* Owner = GetOwner();
//
//	// get current significance
//	float CurrentSignificance = 0.f;
//
//	// if the owner is tracked
//	if (USignificanceManager::Get(GetWorld())->QuerySignificance(Owner, CurrentSignificance))
//	{
//		// if significance changed, apply the new significance
//		if (CurrentSignificance != LastSignificance)
//		{
//			TickSignificance(Owner, CurrentSignificance);
//
//			// update the last significance
//			LastSignificance = CurrentSignificance;
//		}
//	}
//}
//
//// Called when the game starts
//void UKMSignificanceComponent::BeginPlay()
//{
//	Super::BeginPlay();
//
//	AActor* Owner = GetOwner();
//	
//	// cache the manager
//	CachedManager = Cast<UKMSignificanceManager>(USignificanceManager::Get(GetWorld()));
//
//	// if manager is online
//	if (CachedManager)
//	{
//		check(CachedManager->SignificanceLevels.Num());
//		CachedManager->RegisterObject(Owner, SignificanceTag,
//			[this](UObject* InObj, const FTransform& InViewpoint)->float {
//			return SignificanceFunctionImpl(InObj, InViewpoint);
//		},
//			[this](UObject* InObj, float InOldSigni, float InSigni, bool bUnregister) {
//			PostSignificanceFunctionImpl(InObj, InOldSigni, InSigni, bUnregister);
//		});
//
//		// initialize the last significance
//		LastSignificance = CachedManager->GetSignificance(Owner);
//
//		UE_LOG(LogTemp, Log, TEXT("[Significance] %s Significance BeginPlay"), *Owner->GetName());
//	}
//}
//
//void UKMSignificanceComponent::EndPlay(const EEndPlayReason::Type EndPlayReason)
//{
//    Super::EndPlay(EndPlayReason);
//
//	if (CachedManager)
//	{
//		CachedManager->UnregisterObject(GetOwner());
//
//		UE_LOG(LogTemp, Log, TEXT("[Significance] %s Significance EndPlay"), *GetOwner()->GetName());
//	}
//}
//
