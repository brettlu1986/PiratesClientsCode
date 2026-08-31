#pragma once

#include "Game/GameCommon.h"
#include "HistoryService.generated.h"

UCLASS(config = BackendService)
class UHistoryService : public UObject
{
    GENERATED_BODY()

public:
    void Init();

    FString GetSavePlayerStatsUrl();

    FString GetSaveTeamRankUrl();
   
private:
    UPROPERTY(Config)
    FString Endpoint;

private:
    void InitUrls();

private:
    FString SavePlayerStatsUrl;
    FString SaveTeamRankUrl;
};