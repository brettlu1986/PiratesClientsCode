#include "Game/Misc/BPVariableHelper.h"
#include "EngineExt.h"

UBPVariableHelper::UBPVariableHelper(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , BP(nullptr)
{
}

void UBPVariableHelper::RemoveMemberVariable(const FName& VariableName)
{
    for (int ii = 0; ii < NewVariables.Num(); ii++)
    {
        auto& Info = NewVariables[ii];
        if (Info.Name == VariableName)
        {
            NewVariables.RemoveAt(ii);
            return;
        }
    }

    RemovedVariables.AddUnique(VariableName);
}

void UBPVariableHelper::AddMemberVariable(EBPVariableType Type, const FName& VariableName, const FString& Category)
{
    for (int ii = 0; ii < NewVariables.Num(); ii++)
    {
        auto& Info = NewVariables[ii];
        if (Info.Name == VariableName)
        {
            NewVariables.RemoveAt(ii);
            break;
        }
    }

    auto& NewInfo = NewVariables[NewVariables.AddDefaulted()];
    NewInfo.Type = Type;
    NewInfo.Name = VariableName;
    NewInfo.Category = Category;
}

void UBPVariableHelper::DuplicateMemberVariable(const FName& SourceName, const FName& NewName)
{
    for (int ii = 0; ii < DupliactedInfos.Num(); ii++)
    {
        auto& Info = DupliactedInfos[ii];
        if (Info.SourceName == SourceName)
        {
            DupliactedInfos.RemoveAt(ii);
            break;
        }
    }

    auto& NewInfo = DupliactedInfos[DupliactedInfos.AddDefaulted()];
    NewInfo.SourceName = SourceName;
    NewInfo.NewName = NewName;
}

void UBPVariableHelper::SetVariableEditorOnly(const FName& Name, bool bEditorOnly)
{
    for (int ii = 0; ii < EditorOnlyInfos.Num(); ii++)
    {
        auto& Info = EditorOnlyInfos[ii];
        if (Info.Name == Name)
        {
            EditorOnlyInfos.RemoveAt(ii);
            break;
        }
    }

    auto& NewInfo = EditorOnlyInfos[EditorOnlyInfos.AddDefaulted()];
    NewInfo.Name = Name;
    NewInfo.bEditorOnly = bEditorOnly;
}

void UBPVariableHelper::Reset(UBlueprint* TempBP)
{
    BP = TempBP;
    RemovedVariables.Empty();
    NewVariables.Empty();    
    DupliactedInfos.Empty();
    EditorOnlyInfos.Empty();
}
