#include "KMNavigationLine.h"
#include "PiratesEditor.h"
#include "KMNavigationMark.h"
#include "Components/SplineComponent.h"

AKMNavigationLine::AKMNavigationLine()
{
    PrimaryActorTick.bCanEverTick = false;
    RootComponent = CreateDefaultSubobject<USceneComponent>(USceneComponent::GetDefaultSceneRootVariableName());

    SplineComponent = CreateDefaultSubobject<USplineComponent>(FName(TEXT("SplineComponent")));
    SplineComponent->SetupAttachment(RootComponent);
    SplineComponent->SetClosedLoop(false);
}

void AKMNavigationLine::ClearUpReference()
{
    for (auto Mark : NavigationMarks)
    {
        if (Mark)
        {
            Mark->RemoveNavigationLine(this);
        }
    }

    NavigationMarks.Empty();
}

void AKMNavigationLine::PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent)
{
    Super::PostEditChangeProperty(PropertyChangedEvent);
}

void AKMNavigationLine::Destroyed()
{
    ClearUpReference();
    Super::Destroyed();
}


