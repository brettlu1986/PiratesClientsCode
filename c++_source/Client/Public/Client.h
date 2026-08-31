// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "Engine.h"
#include "GlobalDefinition.h"
#include "GameModule.h"

class CLIENT_API FClientModule : public IGameModule, private FSelfRegisteringExec
{
    // IModuleInterface
public:
    virtual void OnGameInstanceInit(UGameInstance* GameInstance) override;
    virtual void OnGameInstanceStart(UGameInstance* GameInstance) override;
    virtual void OnGameInstanceShutdown(UGameInstance* GameInstance) override;
    virtual void OnGameInstancePostShutdown(UGameInstance* GameInstance) override;

    virtual void StartupModule() override;

    virtual void ShutdownModule() override;

    // IGameModule
public:
    // FExec
    virtual bool Exec(class UWorld* InWorld, const TCHAR* Cmd, FOutputDevice& Ar) override;

    //bool SendLogin(float DeltaTime);
};