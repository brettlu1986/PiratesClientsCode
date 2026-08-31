#include "PiratesGameMode.h"
#include "Common.h"
#include "Game/GameCommon.h"
#include "PiratesGameSession.h"
#include "PiratesPlayerStart.h"
#include "PiratesGameState.h"
#include "PiratesPlayerState.h"
#include "Shell/EngineExtActorShell.h"
#include "Game/Delegates/KMDelegateManager.h"
#include "Game/Delegates/GameModeDelegate.h"


DEFINE_LOG_CATEGORY_STATIC(PiratesGameModeLog, Log, All);

APiratesGameMode::APiratesGameMode(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{
}

TSubclassOf<AGameSession> APiratesGameMode::GetGameSessionClass() const
{
    return APiratesGameSession::StaticClass();
}

APawn * APiratesGameMode::SpawnDefaultPawnFor_Implementation(AController * NewPlayer, AActor * StartSpot)
{
    /*APawn* Pawn = Super::SpawnDefaultPawnFor_Implementation(NewPlayer, StartSpot);
    if (Pawn != nullptr)
    {
        UEngineExtActorShell::MovePawnToSafeLocation(this, Pawn);
    }
    
    return Pawn;*/
    return Super::SpawnDefaultPawnFor_Implementation(NewPlayer, StartSpot);
}

bool APiratesGameMode::AllowCheats(APlayerController* P)
{
	if (!UE_BUILD_SHIPPING && !UE_BUILD_TEST)
	{
		return true;
	}

	return Super::AllowCheats(P);
}