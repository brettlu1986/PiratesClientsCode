// Fill out your copyright notice in the Description page of Project Settings.

#include "Network/ProtobufMessageRef.h"
#include "Common.h"

UProtobufMessageRef::UProtobufMessageRef(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)    
    , Message(nullptr)
{
}