#pragma once

#if WITH_EDITOR
struct COMMON_API FComponentTreeNodeInCDO
{
    FName VariableName;
    UActorComponent* Component;
    int SelfIndex;
    int ParentIndex;
    TArray<int> ChildIndices;
    USCS_Node* SCSNode;

    FComponentTreeNodeInCDO(const FName& Name, UActorComponent* TempComponent, int SIndex, int Parent)
        : VariableName(Name)
        , Component(TempComponent)
        , SelfIndex(SIndex)
        , ParentIndex(Parent)
        , SCSNode(nullptr)
    {
    }

    FComponentTreeNodeInCDO(USCS_Node* Node, UActorComponent* TempComponent, int SIndex, int Parent)
        : VariableName(Node->GetVariableName())
        , Component(TempComponent)
        , SelfIndex(SIndex)
        , ParentIndex(Parent)
        , SCSNode(Node)
    {
    }
};

class COMMON_API FComponentInCDOCollector
{
public:
    FComponentInCDOCollector(UClass* InActorClass);
    UActorComponent* GetComponent(const FComponentTreeNodeInCDO& Node, 
        bool bFindOverridenComponent, bool bCreateOverridenComponentIfNotFind) const;
    const FComponentTreeNodeInCDO& GetNode(int Index) const;
    const FComponentTreeNodeInCDO& GetRoot() const;
    const FComponentTreeNodeInCDO* FindNode(const FName& NodeName) const;
    const FComponentTreeNodeInCDO* FindNodeWithComponent(const UActorComponent* Component) const;
    void FindChildren(const FComponentTreeNodeInCDO& Node, TArray<const FComponentTreeNodeInCDO*>& OutNodes) const;
    const FName FindVariableNameGivenComponentInstance(const UActorComponent* ComponentInstance) const;
    const int GetNodeCount() const { return Allocator.Num(); }
    void GetComponentsOfClass(UClass* ComponentClass, TArray<UActorComponent*>& Components);

private:
    FComponentTreeNodeInCDO& GetNodeImp(int Index);
    FComponentTreeNodeInCDO& GetRootImp();
    FComponentTreeNodeInCDO* FindNodeImp(const FName& NodeName);
    FComponentTreeNodeInCDO* FindNodeWithComponentImp(const UActorComponent* Component);

    FComponentTreeNodeInCDO& NewTree();
    FComponentTreeNodeInCDO& NewNode(const FName& Name, UActorComponent* Component, int ParentIndex);
    FComponentTreeNodeInCDO& NewNode(USCS_Node* Node, UActorComponent* Component, int ParentIndex);
    void ConstructSCSNodeTree(UBlueprintGeneratedClass* BPClass, USCS_Node* Node, int ParentIndex);
    void ConstructTree(UClass* InActorClass);

private:
    UClass* ActorClass;
    TArray<FComponentTreeNodeInCDO> Allocator;
};

#endif