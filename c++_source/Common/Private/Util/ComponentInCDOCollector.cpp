#include "Util/ComponentInCDOCollector.h"
#include "Common.h"
#include "Engine/InheritableComponentHandler.h"

#if WITH_EDITOR
FComponentInCDOCollector::FComponentInCDOCollector(UClass* InActorClass)
    : ActorClass(InActorClass)
{
    ConstructTree(InActorClass);
}

const FComponentTreeNodeInCDO& FComponentInCDOCollector::GetNode(int Index) const
{
    return Allocator[Index];
}

const FComponentTreeNodeInCDO& FComponentInCDOCollector::GetRoot() const
{
    check(Allocator.Num() > 0);
    return Allocator[0];
}

const FComponentTreeNodeInCDO* FComponentInCDOCollector::FindNode(const FName& NodeName) const
{
    const FComponentTreeNodeInCDO* Node = nullptr;
    for (int ii = 0; ii < Allocator.Num(); ii++)
    {
        Node = &Allocator[ii];
        if (Node->VariableName == NodeName)
        {
            return Node;
        }
    }
    return nullptr;
}

void FComponentInCDOCollector::GetComponentsOfClass(UClass* ComponentClass, TArray<UActorComponent *>& Components)
{
    if (!ComponentClass)
        return;
    Components.Empty();
    const FComponentTreeNodeInCDO* Node = nullptr;
    for (int ii = 0; ii < Allocator.Num(); ii++)
    {
        Node = &Allocator[ii];
        if (!ComponentClass || (Node->Component && Node->Component->GetClass()->IsChildOf(ComponentClass)))
        {
            Components.Add(Node->Component);
        }
    }
}

const FComponentTreeNodeInCDO* FComponentInCDOCollector::FindNodeWithComponent(const UActorComponent* Component) const
{
    const FComponentTreeNodeInCDO* Node = nullptr;
    for (int ii = 0; ii < Allocator.Num(); ii++)
    {
        Node = &Allocator[ii];
        if (Node->Component == Component)
        {
            return Node;
        }
    }
    return nullptr;
}

UActorComponent* FComponentInCDOCollector::GetComponent(const FComponentTreeNodeInCDO& Node,
    bool bFindOverridenComponent, bool bCreateOverridenComponentIfNotFind) const
{
    UActorComponent* Ret = Allocator[Node.SelfIndex].Component;
    if (bFindOverridenComponent)
    {
        UBlueprintGeneratedClass* BPClass = Cast<UBlueprintGeneratedClass>(ActorClass);
        if (BPClass)
        {
            auto InheritableComponentHandler = BPClass->GetInheritableComponentHandler(false);
            if (InheritableComponentHandler)
            {
                auto ComponentKey = InheritableComponentHandler->FindKey(Node.VariableName);
                if (ComponentKey.IsValid())
                {
                    Ret = InheritableComponentHandler->GetOverridenComponentTemplate(ComponentKey);
                }
                else if (bCreateOverridenComponentIfNotFind)
                {
// 					UBlueprintGeneratedClass* ComponentBPClass = Cast<UBlueprintGeneratedClass>(Ret);
// 					if (ComponentBPClass)
// 					{
						Ret = InheritableComponentHandler->CreateOverridenComponentTemplate(FComponentKey(Node.SCSNode));
//					}
                }
            }
        }
    }
    return Ret;
}

FComponentTreeNodeInCDO& FComponentInCDOCollector::GetNodeImp(int Index)
{
	return Allocator[Index];
}

FComponentTreeNodeInCDO& FComponentInCDOCollector::GetRootImp()
{
	check(Allocator.Num() > 0);
	return Allocator[0];
}

FComponentTreeNodeInCDO& FComponentInCDOCollector::NewTree()
{
	Allocator.Empty();
	Allocator.Add(FComponentTreeNodeInCDO(NAME_None, NULL, 0, -1));
	return Allocator[0];
}

FComponentTreeNodeInCDO& FComponentInCDOCollector::NewNode(const FName& Name, UActorComponent* Component, int ParentIndex)
{
	Allocator.Add(FComponentTreeNodeInCDO(Name, Component, Allocator.Num(), ParentIndex));
	FComponentTreeNodeInCDO& Ret = GetNodeImp(Allocator.Num() - 1);
	if (ParentIndex >= 0)
	{
		GetNodeImp(ParentIndex).ChildIndices.Add(Ret.SelfIndex);
	}
	return Ret;
}

FComponentTreeNodeInCDO& FComponentInCDOCollector::NewNode(USCS_Node* Node, UActorComponent* Component, int ParentIndex)
{
    Allocator.Add(FComponentTreeNodeInCDO(Node, Component, Allocator.Num(), ParentIndex));
    FComponentTreeNodeInCDO& Ret = GetNodeImp(Allocator.Num() - 1);
    if (ParentIndex >= 0)
    {
        GetNodeImp(ParentIndex).ChildIndices.Add(Ret.SelfIndex);
    }
    return Ret;
}

FComponentTreeNodeInCDO* FComponentInCDOCollector::FindNodeImp(const FName& NodeName)
{
	FComponentTreeNodeInCDO* Node = nullptr;
	for (int ii=0; ii<Allocator.Num(); ii++)
	{
		Node = &Allocator[ii];
		if (Node->VariableName == NodeName)
		{
			return Node;
		}
	}
	return nullptr;
}

FComponentTreeNodeInCDO* FComponentInCDOCollector::FindNodeWithComponentImp(const UActorComponent* Component)
{
	FComponentTreeNodeInCDO* Node = nullptr;
	for (int ii = 0; ii < Allocator.Num(); ii++)
	{
		Node = &Allocator[ii];
		if (Node->Component == Component)
		{
			return Node;
		}
	}
	return nullptr;
}

void FComponentInCDOCollector::FindChildren(const FComponentTreeNodeInCDO& Node, TArray<const FComponentTreeNodeInCDO*>& OutNodes) const
{
	const FComponentTreeNodeInCDO* ChildNode = nullptr;
	for (int ii=0; ii<Node.ChildIndices.Num(); ii++)
	{
		ChildNode = &GetNode(Node.ChildIndices[ii]);
		OutNodes.Add(ChildNode);
        FindChildren(*ChildNode, OutNodes);
	}
}

void FComponentInCDOCollector::ConstructSCSNodeTree(UBlueprintGeneratedClass* BPClass, USCS_Node* Node, int ParentIndex)
{
	if (!Node)
	{
		return;
	}

	if (Node->ParentComponentOrVariableName != NAME_None)
	{
		USceneComponent* ParentComponent = Node->GetParentComponentTemplate(UBlueprint::GetBlueprintFromClass(BPClass));
		if (ParentComponent)
		{
			FComponentTreeNodeInCDO* ParentNode = FindNodeWithComponentImp(ParentComponent);
			ParentIndex = ParentNode ? ParentNode->SelfIndex : ParentIndex;
		}
	}

	FComponentTreeNodeInCDO& TreeNode = NewNode(Node, Node->GetActualComponentTemplate(BPClass), ParentIndex);
	int SelfIndex = TreeNode.SelfIndex;
	for (int ii = 0; ii < Node->ChildNodes.Num(); ii++)
	{
		ConstructSCSNodeTree(BPClass, Node->ChildNodes[ii], SelfIndex);
	}
}

const FName FComponentInCDOCollector::FindVariableNameGivenComponentInstance(const UActorComponent* ComponentInstance) const
{
	check(ComponentInstance != nullptr);

	// First see if the name just works
	if (AActor* OwnerActor = ComponentInstance->GetOwner())
	{
		UClass* OwnerActorClass = OwnerActor->GetClass();
		FName ComponentName = ComponentInstance->GetFName();
		for (TFieldIterator<FObjectProperty> PropIt(OwnerActorClass, EFieldIteratorFlags::IncludeSuper); PropIt; ++PropIt)
		{
			FObjectProperty* TestProperty = *PropIt;
			if (TestProperty->GetFName() == ComponentName && ComponentInstance->GetClass()->IsChildOf(TestProperty->PropertyClass))
			{
				return ComponentName;
			}
		}
	}

	// Name mismatch, try finding a differently named variable pointing to the the component (the mismatch should only be possible for native components)
	if (UActorComponent* Archetype = Cast<UActorComponent>(ComponentInstance->GetArchetype()))
	{
		if (AActor* OwnerActor = Archetype->GetOwner())
		{
			UClass* OwnerClass = OwnerActor->GetClass();
			AActor* OwnerCDO = CastChecked<AActor>(OwnerClass->GetDefaultObject());
			check(OwnerCDO->HasAnyFlags(RF_ClassDefaultObject));

			for (TFieldIterator<FObjectProperty> PropIt(OwnerClass, EFieldIteratorFlags::IncludeSuper); PropIt; ++PropIt)
			{
				FObjectProperty* TestProperty = *PropIt;
				if (Archetype->GetClass()->IsChildOf(TestProperty->PropertyClass))
				{
					void* TestPropertyInstanceAddress = TestProperty->ContainerPtrToValuePtr<void>(OwnerCDO);
					UObject* ObjectPointedToByProperty = TestProperty->GetObjectPropertyValue(TestPropertyInstanceAddress);
					if (ObjectPointedToByProperty == Archetype)
					{
						// This property points to the component archetype, so it's an anchor even if it was named wrong
						return TestProperty->GetFName();
					}
				}
			}

			for (TFieldIterator<FArrayProperty> PropIt(OwnerClass, EFieldIteratorFlags::IncludeSuper); PropIt; ++PropIt)
			{
				FArrayProperty* TestProperty = *PropIt;
				void* ArrayPropInstAddress = TestProperty->ContainerPtrToValuePtr<void>(OwnerCDO);

				FObjectProperty* ArrayEntryProp = CastField<FObjectProperty>(TestProperty->Inner);
				if ((ArrayEntryProp == nullptr) || !ArrayEntryProp->PropertyClass->IsChildOf<UActorComponent>())
				{
					continue;
				}

				FScriptArrayHelper ArrayHelper(TestProperty, ArrayPropInstAddress);
				for (int32 ComponentIndex = 0; ComponentIndex < ArrayHelper.Num(); ++ComponentIndex)
				{
					UObject* ArrayElement = ArrayEntryProp->GetObjectPropertyValue(ArrayHelper.GetRawPtr(ComponentIndex));
					if (ArrayElement == Archetype)
					{
						return TestProperty->GetFName();
					}
				}
			}
		}
	}

	return NAME_None;
}

void FComponentInCDOCollector::ConstructTree(UClass* InActorClass)
{
	if (!InActorClass)
	{
		return;
	}

	NewTree();

	FName TempName;
	int RootNodeIndex = 0;
	AActor* CDO = InActorClass->GetDefaultObject<AActor>();
	if (CDO)
	{
		TInlineComponentArray<UActorComponent*> Components;
		CDO->GetComponents(Components);

		USceneComponent* RootComponent = CDO->GetRootComponent();
		if (RootComponent != nullptr)
		{
			TempName = FindVariableNameGivenComponentInstance(RootComponent);
			Components.Remove(RootComponent);
			NewNode(TempName, RootComponent, RootNodeIndex);
		}

		for (UActorComponent* Component : Components)
		{
			TempName = FindVariableNameGivenComponentInstance(Component);
			if (USceneComponent* SceneComp = Cast<USceneComponent>(Component))
			{
				if (SceneComp->GetAttachParent())
				{
					FComponentTreeNodeInCDO* ParentNode = FindNodeWithComponentImp(SceneComp->GetAttachParent());
					NewNode(TempName, Component, ParentNode ? ParentNode->SelfIndex : RootNodeIndex);
				}
				else
				{
					NewNode(TempName, Component, RootNodeIndex);
				}
			}
			else
			{
				NewNode(TempName, Component, RootNodeIndex);
			}
		}
	}

	UBlueprintGeneratedClass* BPClass = Cast<UBlueprintGeneratedClass>(InActorClass);
	if (!BPClass)
	{
		return;
	}

	TArray<UBlueprint*> ParentBPStack;
	UBlueprint::GetBlueprintHierarchyFromClass(BPClass, ParentBPStack);

	for (int32 StackIndex = ParentBPStack.Num() - 1; StackIndex >= 0; --StackIndex)
	{
		if (ParentBPStack[StackIndex]->SimpleConstructionScript != nullptr)
		{
			const TArray<USCS_Node*>& SCS_RootNodes = ParentBPStack[StackIndex]->SimpleConstructionScript->GetRootNodes();
			for (int32 NodeIndex = 0; NodeIndex < SCS_RootNodes.Num(); ++NodeIndex)
			{
				USCS_Node* SCS_Node = SCS_RootNodes[NodeIndex];
				check(SCS_Node != nullptr);

				ConstructSCSNodeTree(BPClass, SCS_Node, RootNodeIndex);
			} // end for (int32 NodeIndex = 0; NodeIndex < SCS_RootNodes.Num(); ++NodeIndex)
		} // end if (ParentBPStack[StackIndex]->SimpleConstructionScript != nullptr)
	} // end for
}

#endif
