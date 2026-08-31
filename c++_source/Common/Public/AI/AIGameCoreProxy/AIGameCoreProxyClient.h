#pragma once

#include "AI/AIGameCoreProxy/AIGameCoreProxyBase.h"
#include "AIGameCoreProxyClient.generated.h"

UCLASS()
class COMMON_API UAIGameCoreProxyClient : public UObject
{
    GENERATED_UCLASS_BODY()

public:
   
    bool Init();
    bool Uninit();
    void Update(float DeltaTime);

    UFUNCTION()
    bool Start();

    UFUNCTION()
    void Stop();

    UFUNCTION()
    bool Enabled() const;

    UFUNCTION()
    bool TrainingMode() const;

    UPROPERTY()
    class UAIGameCoreProxyTCP* GameCoreProxy;

private:
    FString Endpoint;
    bool bTrainingMode;
};