#include "KMClassDefaultObjectEditTool.h"
#include "PiratesEditor.h"
#include "KMUnrealEdEngine.h"
#include "Kismet2/BlueprintEditorUtils.h"
#include "EdGraphSchema_K2.h"
#include "Misc/BPVariableHelper.h"
#include "Engine/Blueprint.h"

#define ON_PRE_FLUSH_COMPILATION_FUNCTION_NAME TEXT("OnPreFlushCompilationInEditor")
#define ON_PRE_COMPILE_FUNCTION_NAME TEXT("OnPreCompileInEditor")
#define ON_REINSTANCE_FUNCTION_NAME TEXT("OnReinstanceInEditor")
#define ON_POST_COMPILE_FUNCTION_NAME TEXT("OnPostCompileInEditor")

UKMClassDefaultObjectEditTool::UKMClassDefaultObjectEditTool(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, CurrentCompileBP(nullptr)
    , BPVariableHelper(nullptr)
{

}

void UKMClassDefaultObjectEditTool::Init(UKMUnrealEdEngine* Editor)
{
    //Editor->BlueprintPreFlushCompilationEvent.AddUObject(this, &UKMClassDefaultObjectEditTool::OnPreFlushCompilation);
	Editor->OnBlueprintPreCompile().AddUObject(this, &UKMClassDefaultObjectEditTool::OnPreCompile);
	Editor->OnBlueprintReinstanced().AddUObject(this, &UKMClassDefaultObjectEditTool::OnReinstance);
	Editor->OnBlueprintCompiled().AddUObject(this, &UKMClassDefaultObjectEditTool::OnPostCompile);

    BPVariableHelper = NewObject<UBPVariableHelper>(this);
}

void UKMClassDefaultObjectEditTool::OnPreFlushCompilation(UBlueprint* BP)
{
    if (!BP || !BP->GeneratedClass || !BP->GeneratedClass->GetDefaultObject(false))
    {
        return;
    }

    CallFunction(BP, ON_PRE_FLUSH_COMPILATION_FUNCTION_NAME);

    //UObject* Object = BP->GeneratedClass->GetDefaultObject(false);
    //UFunction* Function = Object->FindFunction(ON_PRE_FLUSH_COMPILATION_FUNCTION_NAME);
    //if (!Function)
    //{
    //    return;
    //}

    //BPVariableHelper->Reset(BP);
    //uint8* Params = (uint8*)FMemory_Alloca(Function->ParmsSize);
    //FMemory::Memzero(Params, Function->ParmsSize);

    //UClass* BPHelperClass = UBPVariableHelper::StaticClass();
    //for (TFieldIterator<FProperty> It(Function); It; ++It)
    //{
    //    auto Property = *It;
    //    auto PropertyFlags = Property->GetPropertyFlags();
    //    if (PropertyFlags & CPF_ReturnParm)
    //    {
    //        continue;
    //    }
    //    if ((PropertyFlags & (CPF_ConstParm | CPF_OutParm | CPF_ReferenceParm)) == CPF_OutParm)
    //    {
    //        continue;
    //    }

    //    auto ObjectProperty = CastField<FObjectProperty>(Property);
    //    if (ObjectProperty && ObjectProperty->PropertyClass == BPHelperClass)
    //    {
    //        ObjectProperty->SetObjectPropertyValue_InContainer(Params, BPVariableHelper);
    //        break;
    //    }
    //}

    //Object->ProcessEvent(Function, Params);

    //ProcessBPVariables(BP);
    //BPVariableHelper->Reset(nullptr);
}

void UKMClassDefaultObjectEditTool::OnPreCompile(UBlueprint* BP)
{
	if (!CurrentCompileBP)
	{
		CurrentCompileBP = BP;
	}

	CallFunction(BP, ON_PRE_COMPILE_FUNCTION_NAME);
}

void UKMClassDefaultObjectEditTool::OnReinstance()
{
	if (!CurrentCompileBP || !IsValid(CurrentCompileBP))
	{
		return;
	}

	CallFunction(CurrentCompileBP, ON_REINSTANCE_FUNCTION_NAME);
}

void UKMClassDefaultObjectEditTool::OnPostCompile()
{
	UBlueprint* BP = CurrentCompileBP;
	CurrentCompileBP = nullptr;

	if (!BP || !IsValid(BP))
	{
		return;
	}

	//CallFunction(BP, ON_POST_COMPILE_FUNCTION_NAME);
}

void UKMClassDefaultObjectEditTool::CallFunction(UBlueprint* BP, const TCHAR* Name)
{
	if (!BP || !BP->GeneratedClass || !BP->GeneratedClass->GetDefaultObject(false))
	{
		return;
	}

	UObject* Object = BP->GeneratedClass->GetDefaultObject(false);
	UFunction* Function = Object->FindFunction(Name);
	if (!Function)
	{
		return;
	}

	struct FCall_Params
	{
	} Params;
	Object->ProcessEvent(Function, &Params);
}

void UKMClassDefaultObjectEditTool::ProcessBPVariables(UBlueprint* BP)
{
    check(BPVariableHelper && BP);

    if (BPVariableHelper->RemovedVariables.Num() > 0)
    {
        FBlueprintEditorUtils::BulkRemoveMemberVariables(BP, BPVariableHelper->RemovedVariables);
    }

    FString PinCategory;
    const UEdGraphSchema_K2* K2Schema = GetDefault<UEdGraphSchema_K2>();
    for (auto& Info : BPVariableHelper->NewVariables)
    {
        if (Info.Type == EBPVariableType::Object)
        {
            PinCategory = K2Schema->PC_Object.ToString();
        }
        else
        {
            continue;
        }

        FEdGraphPinType ObjectPinType(FName(*PinCategory), FName(), nullptr, EPinContainerType::None, false, FEdGraphTerminalType());
        FBlueprintEditorUtils::AddMemberVariable(BP, Info.Name, ObjectPinType);
        FBlueprintEditorUtils::SetBlueprintVariableCategory(BP, Info.Name, nullptr, FText::FromString(Info.Category));
    }

    for (auto& Info : BPVariableHelper->DupliactedInfos)
    {
        FName NewName = FBlueprintEditorUtils::DuplicateVariable(BP, nullptr, Info.SourceName);
        if (NewName.IsValid())
        {
            FBlueprintEditorUtils::RenameMemberVariable(BP, NewName, Info.NewName);
        }
    }

    for (auto& Info : BPVariableHelper->EditorOnlyInfos)
    {
        FBlueprintEditorUtils::SetBlueprintOnlyEditableFlag(BP, Info.Name, Info.bEditorOnly);
    }
}