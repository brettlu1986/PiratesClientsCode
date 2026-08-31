#pragma once
#include "BPVariableHelper.generated.h"

UENUM(BlueprintType)
enum class EBPVariableType : uint8
{
    Object = 0,
};


UCLASS(Blueprintable)
class ENGINEEXT_API UBPVariableHelper : public UObject
{
    GENERATED_UCLASS_BODY()

public:
    UFUNCTION(BlueprintCallable, Category = "Game", meta = (CallInEditor = "true"))
    void RemoveMemberVariable(const FName& VariableName);

    UFUNCTION(BlueprintCallable, Category = "Game", meta = (CallInEditor = "true"))
    void AddMemberVariable(EBPVariableType Type, const FName& VariableName, const FString& Category);

    UFUNCTION(BlueprintCallable, Category = "Game", meta = (CallInEditor = "true"))
    void DuplicateMemberVariable(const FName& SourceName, const FName& NewName);

    UFUNCTION(BlueprintCallable, Category = "Game", meta = (CallInEditor = "true"))
    void SetVariableEditorOnly(const FName& Name, bool bEditorOnly);

    UFUNCTION(BlueprintCallable, Category = "Game", meta = (CallInEditor = "true"))
    void Reset(UBlueprint* TempBP);

public:
    struct FNewVariableInfo
    {
        EBPVariableType Type;
        FName Name;
        FString Category;
    };

    struct FDupliactedInfo
    {
        FName SourceName;
        FName NewName;
    };

    struct FEditorOnlyInfo
    {
        FName Name;
        bool bEditorOnly;
    };

public:
    UBlueprint* BP;
    TArray<FName> RemovedVariables;
    TArray<FNewVariableInfo> NewVariables;    
    TArray<FDupliactedInfo> DupliactedInfos;
    TArray<FEditorOnlyInfo> EditorOnlyInfos;
};
