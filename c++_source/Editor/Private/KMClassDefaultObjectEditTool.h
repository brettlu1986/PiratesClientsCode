#pragma once
#include "KMClassDefaultObjectEditTool.generated.h"

class UBlueprint;
class UKMUnrealEdEngine;
class UBPVariableHelper;

UCLASS(Blueprintable)
class EDITOR_API UKMClassDefaultObjectEditTool : public UObject
{
	GENERATED_UCLASS_BODY()

public:
	void Init(UKMUnrealEdEngine* Editor);

private:
    void OnPreFlushCompilation(UBlueprint* BP);
	void OnPreCompile(UBlueprint* BP);
	void OnReinstance();
	void OnPostCompile();
	void CallFunction(UBlueprint* BP, const TCHAR* Name);

private:
    void ProcessBPVariables(UBlueprint* BP);

private:
	UBlueprint* CurrentCompileBP;

    UPROPERTY()
    UBPVariableHelper* BPVariableHelper;
};