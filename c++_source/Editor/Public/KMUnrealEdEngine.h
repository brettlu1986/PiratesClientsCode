// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "UnrealEd.h"
#include "KMUnrealEdEngine.generated.h"
/**
 * 
 */
UCLASS(config = Engine, transient)
class UKMUnrealEdEngine : public UUnrealEdEngine
{
	GENERATED_UCLASS_BODY()

private:
	struct FImplement;
	TSharedPtr<FImplement> Impl;

	FDelegateHandle WordCompositionCollecthandle;

public:
	virtual void Init(IEngineLoop* InEngineLoop) override;
	virtual void PreExit() override;	
	virtual void StartPlayInEditorSession(FRequestPlaySessionParams& InRequestParams) override;
	virtual void EndPlayMap() override;
    static void AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector);
    virtual void AddReferencedObjects(FReferenceCollector& Collector) override;
	UWorld* GetWorldFromContextObject(const UObject* Object, EGetWorldErrorMode ErrorMode) const;

	void OnWorldCompositionCollecting(const FString& PersistentName, TArray<FString>& WorldRoots);
};
