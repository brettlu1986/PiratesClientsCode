#pragma once

#include "CoreMinimal.h"
#include "UObject/ObjectMacros.h"
#include "UObject/UObjectGlobals.h"
#include "UObject/Object.h"
#include "GPerfReporterManagerServer.generated.h"

class UGameServer;

UCLASS()
class UGPerfReporterManagerServer : public UObject
{
    GENERATED_BODY()

//#ifdef WITH_GPERF
public:
    void Init(UGameServer* GameServer);
    void Uninit();

private:
    void InitReporters(UGameServer* GameServer);

private:
    TArray<TSharedPtr<class FGPerfReporter>> Reporters;
//#endif
};
