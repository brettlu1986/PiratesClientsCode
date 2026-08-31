#pragma once

#include "EngineExtSetting.generated.h"

UCLASS(config = Game, meta = (DisplayName = "KMGame"), defaultconfig)
class ENGINEEXT_API UEngineExtSetting : public UObject
{
    GENERATED_UCLASS_BODY()
public:
   
    UFUNCTION(BlueprintPure, Category = Settings)
    static bool IsDevMode();
public:

  
    UPROPERTY(config, EditAnywhere, Category = "Game")
    bool DevMode;
};