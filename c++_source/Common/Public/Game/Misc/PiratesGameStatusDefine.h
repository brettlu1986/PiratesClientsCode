#pragma once

UENUM(BlueprintType)
enum class EPiratesGameStatus : uint8
{
    NONE,
    LOGIN,
    LOBBY,
    WILD_OCEAN,
    WILD_LAND,
    BATTLE_STANDALONE,
    BATTLE_CLIENT,
    BATTLE_SERVER,
    NUM,
};
