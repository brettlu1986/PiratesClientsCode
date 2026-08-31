#include "KMNavigationMark.h"
#include "PiratesEditor.h"
#include "KMNavigationLine.h"
#include "ObjectTools.h"
#include "Components/StaticMeshComponent.h"


AKMNavigationMark::AKMNavigationMark()
{
    PrimaryActorTick.bCanEverTick = false;
    RootComponent = CreateDefaultSubobject<USceneComponent>(USceneComponent::GetDefaultSceneRootVariableName());

    NavigationMarkMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("NavigationMarkMesh"));
    NavigationMarkMesh->SetupAttachment(RootComponent);
}

void AKMNavigationMark::AddUniqueNavigationLine(AKMNavigationLine* InLine)
{
    NavigationLines.AddUnique(InLine);
}

void AKMNavigationMark::RemoveNavigationLine(AKMNavigationLine* InLine)
{
    NavigationLines.Remove(InLine);
}

void AKMNavigationMark::PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent)
{
    Super::PostEditChangeProperty(PropertyChangedEvent);
}

void AKMNavigationMark::Destroyed()
{
    if (NavigationLines.Num() > 0)
    {
        for (int nIndex = NavigationLines.Num() - 1; nIndex >= 0; --nIndex)
        {
            AKMNavigationLine* Line = NavigationLines[nIndex];
            if (Line)
            {   
                Line->ClearUpReference();
                GetWorld()->EditorDestroyActor(Line, true);
            }
        }

        NavigationLines.Empty();
    }

    Super::Destroyed();
}
