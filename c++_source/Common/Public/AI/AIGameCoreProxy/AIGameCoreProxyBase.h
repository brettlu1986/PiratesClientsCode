#pragma once

#include "AIGameCoreProxyBase.generated.h"


UCLASS()
class UAIGameCoreProxyBase : public UObject
{
    GENERATED_BODY()

public:
    
    virtual void Init();

    virtual void Start(const FString& EndPoint);

    virtual void Stop();

    virtual void Uninit();

    virtual void Tick(float DelataTime);
};