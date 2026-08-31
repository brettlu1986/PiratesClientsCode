// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

class ENGINEEXT_API FWorldObjectMap : public FGCObject
{	
public:
    class UObject* GetObject(const UObject* WorldContextObject);
    void AddObject(const UObject* WorldContextObject, UObject* GameObject);
    bool RemoveObject(const UObject* WorldContextObject);

    virtual void AddReferencedObjects(FReferenceCollector& Collector) override;

private:
    const UGameInstance* GetGameInstanceFromContextObject(const UObject* WorldContextObject);

    TMap<const UObject*, UObject*> GameMap;
};
