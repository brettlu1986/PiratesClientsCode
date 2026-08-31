#include "AI/Tests/EnvQueryTest_CanShot.h"
#include "EnvironmentQuery/Items/EnvQueryItemType_VectorBase.h"
#include "EnvironmentQuery/Contexts/EnvQueryContext_Querier.h"
#include "EnvironmentQuery/Contexts/EnvQueryContext_Item.h"
#include "EnvironmentQuery/EnvQueryTypes.h"
#include "CollisionQueryParams.h"
#include "Engine/World.h"


UEnvQueryTest_CanShot::UEnvQueryTest_CanShot(const FObjectInitializer& ObjectInitializer) : Super(ObjectInitializer)
{
    Cost = EEnvTestCost::High;
    ValidItemType = UEnvQueryItemType_VectorBase::StaticClass();
    SetWorkOnFloatValues(false);

    Context = UEnvQueryContext_Querier::StaticClass();
    IngnoreContext = UEnvQueryContext_Querier::StaticClass();
}

void UEnvQueryTest_CanShot::RunTest(FEnvQueryInstance& QueryInstance) const
{
    UObject* DataOwner = QueryInstance.Owner.Get();
    BoolValue.BindData(DataOwner, QueryInstance.QueryID);
    ItemHeightOffset.BindData(DataOwner, QueryInstance.QueryID);
    SphereRadius.BindData(DataOwner, QueryInstance.QueryID);

    bool bWantsHit = BoolValue.GetValue();
    float ItemZ = ItemHeightOffset.GetValue();
    float SphereSize = SphereRadius.GetValue();

    TArray<AActor*> Actors;
    if (!QueryInstance.PrepareContext(Context, Actors))
    {
        return;
    }

    TArray<AActor*> IngoreActors;
    QueryInstance.PrepareContext(IngnoreContext, IngoreActors);


    for (FEnvQueryInstance::ItemIterator It(this, QueryInstance); It; ++It)
    {
        const FVector ItemLocation = GetItemLocation(QueryInstance, It.GetIndex()) + FVector(0, 0, ItemZ);
        for (int32 ContextIndex = 0; ContextIndex < Actors.Num(); ContextIndex++)
        {
            const bool bHit = RunLineTraceTo(ItemLocation, Actors[ContextIndex], QueryInstance.World, SphereSize, ObjectTypes, IngoreActors);
            It.SetScore(TestPurpose, FilterType, bHit, bWantsHit);
        }
    }
}


bool UEnvQueryTest_CanShot::RunLineTraceTo(const FVector& ItemPos, AActor* ContextActor, UWorld* World, int32 SphereSize, const TArray<TEnumAsByte<EObjectTypeQuery> > & InObjectTypes, const TArray<AActor*>& IngoreActors) const
{
    FHitResult OutHit;
    FCollisionObjectQueryParams ObjectQueryParams(InObjectTypes);
    FCollisionQueryParams Params;
    Params.AddIgnoredActors(IngoreActors);
    const bool bHit = World->SweepSingleByObjectType(OutHit, ItemPos, ContextActor->GetActorLocation(), FQuat(), ObjectQueryParams, FCollisionShape::MakeSphere(SphereSize), Params);
    return bHit && OutHit.Actor == ContextActor;
}

FText UEnvQueryTest_CanShot::GetDescriptionDetails() const
{
    return DescribeBoolTestParams(TEXT("can shot"));
}