#pragma once
#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "GoodsDetectComponent.generated.h"

USTRUCT(BlueprintType)
struct FGoodsInfo
{
   GENERATED_USTRUCT_BODY()

   FGoodsInfo() :
       InstanceID(0),
       Location(FVector::ZeroVector),
       TemplateID(0), DistanceSQ(0), Dot(0)
    {

    }

    UPROPERTY(Transient, BlueprintReadOnly)
    int32 InstanceID;

    UPROPERTY(Transient, BlueprintReadOnly)
    FVector Location;

    UPROPERTY(Transient, BlueprintReadOnly)
    int32 TemplateID;

    float DistanceSQ;
    float Dot;
    
};

UCLASS(Blueprintable, meta = (BlueprintSpawnableComponent))
class COMMON_API UGoodsDetectComponent : public UActorComponent
{
    GENERATED_UCLASS_BODY()

public:
   
    virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

    UFUNCTION(BlueprintPure, Category = "GoodsDetect")
    const TArray<FGoodsInfo>& GetItems() const;

    UFUNCTION(BlueprintCallable, Category = "GoodsDetect")
    void AddGlobalItem(int32 InstanceID, const FVector& Location, int32 TemplateID);

	UFUNCTION(BlueprintCallable, Category = "GoodsDetect")
	void ClearAllGlobalItem();

    UPROPERTY(Category = "GoodsDetect", EditAnywhere, BlueprintReadWrite)
    float SightDistance;

    UPROPERTY(Category = "GoodsDetect", EditAnywhere, BlueprintReadWrite)
    float SightFOV;

    UPROPERTY(Category = "GoodsDetect", EditAnywhere, BlueprintReadWrite)
    float RefreshInterval;

    UPROPERTY(Category = "GoodsDetect", EditAnywhere, BlueprintReadWrite)
    bool bIsShip;

    UPROPERTY(Category = "GoodsDetect", EditAnywhere, BlueprintReadWrite)
    int32 MaxVisibelItemNum;

private:
    void UpdateItems();
    int32 GetMinPriorityItemIndex() const;
    
    float TimeToNextRefresh;

    TArray<FGoodsInfo>  GlobalItems;
    TArray<FGoodsInfo>  FoundItems;
};
