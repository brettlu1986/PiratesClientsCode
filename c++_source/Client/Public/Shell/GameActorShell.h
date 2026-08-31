#pragma once

#include "Shell/EngineExtActorShell.h"
#include "GameActorShell.generated.h"


class AActor;

UCLASS()
class CLIENT_API UGameActorShell : public UEngineExtActorShell
{
public:
    GENERATED_BODY()

public:
    void Init();

};