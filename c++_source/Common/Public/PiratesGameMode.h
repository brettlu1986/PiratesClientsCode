#pragma once

#include "KMGameMode.h"
#include "PiratesGameMode.generated.h"


UCLASS()
class COMMON_API APiratesGameMode : public AKMGameMode
{
    GENERATED_UCLASS_BODY()
public:
    virtual TSubclassOf<class AGameSession> GetGameSessionClass() const override;
    virtual APawn* SpawnDefaultPawnFor_Implementation(AController* NewPlayer, AActor* StartSpot) override;

	//yangjingzhao add for toggle debug camera
	virtual bool AllowCheats(APlayerController* P);
public:
};