#pragma once
#include "GameFramework/Actor.h"
#include "KMNavigationLine.generated.h"

class USplineComponent;
class AKMNavigationMark;

UCLASS()
class EDITOR_API AKMNavigationLine : public AActor
{
    GENERATED_BODY()

public:
    AKMNavigationLine();

    UPROPERTY(BlueprintReadWrite, VisibleAnywhere, Category = "NavigationLine")
    USplineComponent* SplineComponent;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "NavigationLine", meta=(ClampMin=1, ClampMax=255))
    int Weight;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "NavigationLine")
    TArray<AKMNavigationMark*> NavigationMarks;

    void ClearUpReference();

    //~ Begin UObject Interface
    virtual bool IsEditorOnly() const  override { return true; }
    virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent);
    //~ End UObject Interface

    //~ Begin AActor Interface
    virtual void Destroyed() override;
    //~ End AActor Interface
};
