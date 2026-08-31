// Fill out your copyright notice in the Description page of Project Settings.

#include "KMJsonExportComponent.h"
#include "EngineExt.h"
#include "Json.h"
#include "KMJsonExportInterface.h"

DEFINE_LOG_CATEGORY_STATIC(UKMJsonExportComponentLog, Log, All)

UKMJsonExportComponent::UKMJsonExportComponent(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
    , Canceled(false)
{
    bIsEditorOnly = true;
}

UKMJsonExportComponent::FKMJsonNode* UKMJsonExportComponent::NewNode(const FString& JsonKeyName, int ParentIndex)
{
    if (ParentIndex < 0 || ParentIndex > TempNodes.Num())
    {
        UE_LOG(UKMJsonExportComponentLog, Error, TEXT("NewNode failed,json key [%s] the parent node [%d] is null!!!"), *JsonKeyName, ParentIndex);
        return nullptr;
    }

    TempNodes.AddDefaulted();
    FKMJsonNode& Node = TempNodes.Last();
    Node.JsonKeyName = JsonKeyName;
    Node.SelfIndex = TempNodes.Num() - 1;
    Node.ParentIndex = ParentIndex;
    TempNodes[ParentIndex].ChlidIndices.Add(Node.SelfIndex);
    return &Node;
}

bool UKMJsonExportComponent::ExportToJsonString(FString& Out)
{
    Canceled = false;
    TSharedPtr<FJsonObject> RootObjectPtr = MakeShareable(new FJsonObject());
    if (!ExportToJsonObject(RootObjectPtr))
    {
        UE_LOG(UKMJsonExportComponentLog, Error, TEXT("ExportToJsonObject failed."));
        return false;
    }

    TSharedRef<FJsonObject> RootObjectRef = RootObjectPtr.ToSharedRef();
    TSharedRef<TJsonWriter<> > JsonWriter = TJsonWriterFactory<>::Create(&Out, 0);
    if (!FJsonSerializer::Serialize(RootObjectRef, JsonWriter))
    {
        UE_LOG(UKMJsonExportComponentLog, Error, TEXT("FJsonSerializer::Serialize failed."));
        return false;
    }
    return true;
}

int UKMJsonExportComponent::AddNode(int ParentNodeIndex, const FString& JsonKeyName)
{
    FKMJsonNode* Node = NewNode(JsonKeyName, ParentNodeIndex);
    Node->JsonObject = MakeShareable(new FJsonObject());
    return Node->SelfIndex;
}

int UKMJsonExportComponent::AddArrayNode(int ParentNodeIndex, const FString& JsonKeyName)
{
    FKMJsonNode* Node = NewNode(JsonKeyName, ParentNodeIndex);
    Node->JsonValueArray = new TArray<TSharedPtr<FJsonValue>>();
    return Node->SelfIndex;
}

void UKMJsonExportComponent::AddPropertyValue(UObject* Object, int ParentNodeIndex, const FString& PropertyName, const FString& JsonKeyName, bool bExcludeFromOtherProperties)
{
    if (!Object)
    {
        UE_LOG(UKMJsonExportComponentLog, Error, TEXT("Object is nullptr, property %s!!!"), *PropertyName);
        return;
    }
    UClass* Class = Object->GetClass();
    FProperty* Property = Class->FindPropertyByName(*PropertyName);
    if (!Property)
    {
        UE_LOG(UKMJsonExportComponentLog, Error, TEXT("Can not find property %s!!!"), *PropertyName);
        return;
    }

    FString JsonExportName = JsonKeyName;
    if (JsonExportName.Len() == 0)
    {
        JsonExportName = PropertyName;
    }

    if (!AddPropertyValueImp(Object, ParentNodeIndex, Property, JsonExportName))
    {
        UE_LOG(UKMJsonExportComponentLog, Error, TEXT("Create json value failed %s!!!"), *PropertyName);
        return;
    }

    if (bExcludeFromOtherProperties)
    {
        MarkPropertyNotExport(PropertyName);
    }
}

bool UKMJsonExportComponent::AddPropertyValueImp(UObject* Object, int ParentNodeIndex, FProperty* Property, const FString& JsonKeyName)
{
    if (!Property || JsonKeyName.Len() == 0)
    {
        return false;
    }

    TSharedPtr<FJsonValue> JsonValue;
    if (!CreateJsonValue(Object, Property, JsonValue))
    {
        return false;
    }

    FKMJsonNode* Node = NewNode(JsonKeyName, ParentNodeIndex);
    if (!Node)
    {
        return false;
    }
    Node->JsonValue = JsonValue;
    return true;
}

void UKMJsonExportComponent::AddAllPropertyValuesOfSelfComponent(int ParentNodeIndex)
{
    FString StopClassName = UKMJsonExportComponent::StaticClass()->GetName();
    AddAllPropertyValuesOfObject(this, ParentNodeIndex, StopClassName);
}

void UKMJsonExportComponent::AddAllPropertyValuesOfObject(UObject* Object, int ParentNodeIndex, const FString& StopClassName)
{
#if WITH_EDITOR
    UClass* ThisClass = Object->GetClass();
    while (ThisClass)
    {
        for (TFieldIterator<FProperty> itrProperty(ThisClass, EFieldIteratorFlags::ExcludeSuper, EFieldIteratorFlags::ExcludeDeprecated); itrProperty; ++itrProperty)
        {
            FProperty* Property = *itrProperty;
            FString PropertyName = Property->GetFName().ToString();
            if (PropertiesNotExported.Contains(PropertyName))
            {
                continue;
            }
            if (Property->GetMetaData("KMJsonNotExport").Len() > 0)
            {
                continue;
            }
            AddPropertyValueImp(Object, ParentNodeIndex, Property, PropertyName);
        }
        if (StopClassName.Len() > 0 && ThisClass->GetName() == StopClassName)
        {
            break;
        }
        ThisClass = ThisClass->GetSuperClass();
    }
#endif
}

void UKMJsonExportComponent::MarkPropertyNotExport(const FString& PropertyName)
{
    if (!PropertiesNotExported.Contains(PropertyName))
    {
        PropertiesNotExported.Add(PropertyName);
    }
}

void UKMJsonExportComponent::AddStringValue(int NodeIndex, const FString& Key, const FString& Value)
{
    FKMJsonNode* Node = NewNode(Key, NodeIndex);
    Node->JsonValue = MakeShareable(new FJsonValueString(Value));
}

void UKMJsonExportComponent::AddIntValue(int NodeIndex, const FString& Key, int Value)
{
    FKMJsonNode* Node = NewNode(Key, NodeIndex);
    Node->JsonValue = MakeShareable(new FJsonValueNumber(Value));
}

void UKMJsonExportComponent::AddBoolValue(int NodeIndex, const FString& Key, bool Value)
{
    FKMJsonNode* Node = NewNode(Key, NodeIndex);
    Node->JsonValue = MakeShareable(new FJsonValueBoolean(Value));
}

void UKMJsonExportComponent::AddFloatValue(int NodeIndex, const FString& Key, float Value)
{
    FKMJsonNode* Node = NewNode(Key, NodeIndex);
    Node->JsonValue = MakeShareable(new FJsonValueNumber(Value));
}

void UKMJsonExportComponent::Cancel()
{
    Canceled = true;
}

bool UKMJsonExportComponent::CreateJsonValue(const void* Object, FProperty* Property, TSharedPtr<FJsonValue>& OutJsonValue)
{
    if (auto *StrProperty = CastField<FStrProperty>(Property))
    {
        FString Value = StrProperty->GetPropertyValue_InContainer(Object);
        OutJsonValue = MakeShareable(new FJsonValueString(Value));
    }
    else if (auto *IntProperty = CastField<FIntProperty>(Property))
    {
        int32 Value = IntProperty->GetPropertyValue_InContainer(Object);
        OutJsonValue = MakeShareable(new FJsonValueNumber(Value));
    }
    else if (auto *BoolProperty = CastField<FBoolProperty>(Property))
    {
        bool Value = BoolProperty->GetPropertyValue_InContainer(Object);
        OutJsonValue = MakeShareable(new FJsonValueBoolean(Value));
    }
    else if (auto *FloatProperty = CastField<FFloatProperty>(Property))
    {
        float Value = FloatProperty->GetPropertyValue_InContainer(Object);
        OutJsonValue = MakeShareable(new FJsonValueNumber(Value));
    }
    else if (auto *ArrayProperty = CastField<FArrayProperty>(Property))
    {
        FScriptArrayHelper_InContainer ArrayHelper(ArrayProperty, Object);
        auto ArrayCount = ArrayHelper.Num();
        auto *InnerProperty = ArrayProperty->Inner;
        TArray< TSharedPtr<FJsonValue> > InnerJsonIntArray;
        for (int i = 0; i < ArrayCount; ++i)
        {
            auto *InnerBuffer = ArrayHelper.GetRawPtr(i);
            TSharedPtr<FJsonValue> InnerJsonValuePtr;
            auto bCreateSuccess = CreateJsonValue(InnerBuffer, InnerProperty, InnerJsonValuePtr);
            if (bCreateSuccess == false)
            {
                continue;
            }
            InnerJsonIntArray.Add(InnerJsonValuePtr);
        }
        OutJsonValue = MakeShareable(new FJsonValueArray(InnerJsonIntArray));
    }
    else
    {
        return false;
    }
    return true;
}

bool UKMJsonExportComponent::ConstructJsonTree(TSharedPtr<FJsonObject>& OutObject)
{
    TFunction<void(TArray<FKMJsonNode>&, int, TArray<FKMJsonNode*>&)> CollectChildrenFunc
        = [&](TArray<FKMJsonNode>& Nodes, int NodeIndex, TArray<FKMJsonNode*> &Out)
    {
        FKMJsonNode& Node = Nodes[NodeIndex];
        for (int ii=0; ii<Node.ChlidIndices.Num(); ++ii)
        {
            CollectChildrenFunc(Nodes, Node.ChlidIndices[ii], Out);
        }
        Out.Add(&Nodes[NodeIndex]);
    };

    int NodeCount = TempNodes.Num();
    TArray<FKMJsonNode*> AllNodes;
    AllNodes.Reserve(NodeCount);
    CollectChildrenFunc(TempNodes, 0, AllNodes);

    for (int ii = 0; ii < NodeCount-1; ++ii)
    {
        FKMJsonNode& Node = *AllNodes[ii];
        if (Node.ParentIndex < 0)
        {
            UE_LOG(UKMJsonExportComponentLog, Error, TEXT("Add json failed, node[%s] parent index is not valid!!!"), *Node.JsonKeyName);
            return false;
        }
        FKMJsonNode& ParentNode = TempNodes[Node.ParentIndex];
        TSharedPtr<FJsonValue> Value;

        if (Node.JsonValue.IsValid())
        {
            Value = Node.JsonValue;
        }
        else if(Node.JsonObject.IsValid())
        {
            Value = MakeShareable(new FJsonValueObject(Node.JsonObject));
        }
        else if (Node.JsonValueArray)
        {
            Value = MakeShareable(new FJsonValueArray(*Node.JsonValueArray));
        }
        else
        {
            UE_LOG(UKMJsonExportComponentLog, Error, TEXT("Add json failed, node[%s] value is not valid!!!"), *Node.JsonKeyName);
            return false;
        }

        if (ParentNode.JsonValueArray)
        {
            ParentNode.JsonValueArray->Add(Value);
        }
        else if (ParentNode.JsonObject.IsValid())
        {
            ParentNode.JsonObject->Values.Add(Node.JsonKeyName, Value);
        }
        else
        {
            UE_LOG(UKMJsonExportComponentLog, Error, TEXT("Add json failed, parent of node[%s] is not a json object or array!!!"), *Node.JsonKeyName);
            return false;
        }
    }
    OutObject = TempNodes[0].JsonObject;
    return true;
}

bool UKMJsonExportComponent::ExportToJsonObject(TSharedPtr<FJsonObject>& OutObject)
{
    //TempNodes.Reserve(32);
    TempNodes.AddDefaulted();
    FKMJsonNode& RootNode = TempNodes.Last();
    RootNode.SelfIndex = 0;
    RootNode.JsonObject = MakeShareable(new FJsonObject());

    AActor* Actor = GetOwner();
    if (Actor->GetClass()->ImplementsInterface(UKMJsonExportInterface::StaticClass()))
    {
        UFunction* Function = Actor->FindFunction(TEXT("OnConstructNodeTree"));
        if (Function)
        {
            FIntProperty* RootNodeIndexProperty = CastField<FIntProperty>(Function->PropertyLink);
            if (RootNodeIndexProperty)
            {
                uint8* Parms = (uint8*)FMemory_Alloca(Function->ParmsSize);
                FMemory::Memzero(Parms, Function->ParmsSize);

                RootNodeIndexProperty->SetPropertyValue_InContainer(Parms, RootNode.SelfIndex);
                Actor->ProcessEvent(Function, Parms);
                RootNodeIndexProperty->DestroyValue_InContainer(Parms);
            }
        }
    }
    else
    {
        OnConstructNodeTree(RootNode.SelfIndex);
    }
    bool bRet = ConstructJsonTree(OutObject);
    TempNodes.Reset();
    return bRet;
}