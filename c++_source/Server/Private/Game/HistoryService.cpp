#include "HistoryService.h"
#include "Server.h"

void UHistoryService::Init()
{
    InitUrls();
}

void UHistoryService::InitUrls()
{
    SavePlayerStatsUrl = Endpoint + TEXT("/SavePlayerStats");
    SaveTeamRankUrl = Endpoint + TEXT("/SaveTeamRank");
}

FString UHistoryService::GetSavePlayerStatsUrl()
{
    return SavePlayerStatsUrl;
}

FString UHistoryService::GetSaveTeamRankUrl()
{
    return SaveTeamRankUrl;
}

