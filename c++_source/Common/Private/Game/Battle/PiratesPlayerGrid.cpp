#include "Game/Battle/PiratesPlayerGrid.h"
#include "Common.h"
#include "PiratesPlayerController.h"
#include "Game/GameCommon.h"
#include "Game/Delegates/PiratesGameMiscDelegate.h"
#include "Kismet/GameplayStatics.h"

UPiratesPlayerGrid::UPiratesPlayerGrid(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , EffectiveTime(1.0f)
    , CurrentTime(0.0f)
    , GridSize(0.0f)
{
    PrimaryComponentTick.bCanEverTick = false;
}

void UPiratesPlayerGrid::SetUpdateInterval(float InEffetiveTime)
{
//    Clear();
    EffectiveTime = InEffetiveTime;
}

void UPiratesPlayerGrid::Clear()
{

}

void UPiratesPlayerGrid::Update(float DeltaTime)
{
    if (GridSize == 0.0f)
        return;

    bool bExecute = false;
    CurrentTime += DeltaTime;
    while (CurrentTime >= EffectiveTime)
    {
        bExecute = true;
        CurrentTime -= EffectiveTime;
    }
    if (bExecute)
    {
        Execute();
    }
}

void UPiratesPlayerGrid::AddActor(AActor* Actor)
{
	for (int ii = 0; ii < ActorInfos.Num();)
	{
		auto& ActorInfo = ActorInfos[ii];
        if (!ActorInfo.Actor.IsValid())
        {
            ActorInfos.RemoveAt(ii);
            continue;
        }

        

		if (ActorInfo.Actor == Actor)
		{
			return;
		}
        ii++;
	}

	ActorInfos.AddDefaulted();
	UPiratesPlayerGrid::FActorInfo& Info = ActorInfos[ActorInfos.Num() - 1];
	Info.Actor = Actor;
	Actor->OnDestroyed.AddDynamic(this, &UPiratesPlayerGrid::OnActorDestroyed);
}

void UPiratesPlayerGrid::RemoveActor(AActor* Actor)
{
	if (!Actor)
	{
		return;
	}
	for (int ii = 0; ii < ActorInfos.Num(); )
	{
		auto& ActorInfo = ActorInfos[ii];
        if (!ActorInfo.Actor.IsValid())
        {
            ActorInfos.RemoveAt(ii);
            continue;
        }
		if (ActorInfo.Actor == Actor)
		{
			Actor->OnDestroyed.RemoveDynamic(this, &UPiratesPlayerGrid::OnActorDestroyed);
			ActorInfos.RemoveAt(ii);
			break;
		}
        ii++;
	}
}

void UPiratesPlayerGrid::OnActorDestroyed(AActor* ActorToDestroy)
{
	RemoveActor(ActorToDestroy);
}

void UPiratesPlayerGrid::Execute()
{
	for (int ii = 0; ii < ActorInfos.Num(); )
	{
		auto& ActorInfo = ActorInfos[ii];
        if (!ActorInfo.Actor.IsValid())
        {
            ActorInfos.RemoveAt(ii);
            continue;
        }
        
		FVector position = ActorInfo.Actor->GetActorLocation();
		int GridX = position.X / GridSize;
		int GridY = position.Y / GridSize;
		if (ActorInfo.GridPos.X != GridX || ActorInfo.GridPos.Y != GridY)
		{
			ActorInfo.GridPos.X = GridX;
			ActorInfo.GridPos.Y = GridY;
			OnEnterGrid.ExecuteIfBound(ActorInfo.Actor.Get(), GridX, GridY);
		}
        ii++;
	}

    //TArray<APlayerController*>  PlayerList;
    //GEngine->GetAllLocalPlayerControllers(PlayerList);
    //APawn* PlayerPawn = nullptr;
    //if (PlayerList.Num() > 0)
    //{
    //    PlayerPawn = PlayerList[0]->GetPawn();
    //}
    //if (!PlayerPawn)
    //    return;
    //FVector position = PlayerPawn->GetActorLocation();
    //int GridX = position.X / GridSize;
    //int GridY = position.Y / GridSize;
    //if (GridPos.X != GridX || GridPos.Y != GridY)
    //{
    //    GridPos.X = GridX;
    //    GridPos.Y = GridY;
    //    OnEnterGrid.ExecuteIfBound(GridX, GridY);
    //}
}
