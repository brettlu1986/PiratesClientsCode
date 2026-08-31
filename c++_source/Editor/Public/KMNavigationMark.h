#pragma once
#include "GameFramework/Actor.h"
#include "KMNavigationMark.generated.h"

class AKMNavigationLine;


UENUM()
enum class ENavigationMarkType : uint8
{
    Waypoint,
    SceneEntrance,
    SceneExit
};

UCLASS()
class EDITOR_API AKMNavigationMark: public AActor
{
    GENERATED_BODY()

public:
    AKMNavigationMark();

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "NavigationLines")
    TArray<AKMNavigationLine*> NavigationLines;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "NavigationMark")
    ENavigationMarkType Type;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "NavigationMark")
    int SceneId;

    UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "NavigationMark")
    float Radius;

    UPROPERTY(BlueprintReadWrite, VisibleAnywhere, Category = "StaticMesh")
    UStaticMeshComponent* NavigationMarkMesh;

    UFUNCTION(BlueprintCallable, Category = "NavigationMark")
    void AddUniqueNavigationLine(AKMNavigationLine* InLine);

    UFUNCTION(BlueprintCallable, Category = "NavigationMark")
    void RemoveNavigationLine(AKMNavigationLine* InLine);

    //~ Begin UObject Interface
    virtual bool IsEditorOnly() const  override { return true; }
    virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent) override;
    //~ End UObject Interface

    //~ Begin AActor Interface
    virtual void Destroyed() override;
    //~ End AActor Interface
};
