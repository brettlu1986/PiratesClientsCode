// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include <google/protobuf/message.h>
#include "ProtobufMessageRef.generated.h"

UCLASS()
class UProtobufMessageRef : public UObject
{
    GENERATED_UCLASS_BODY()

public:
    const google::protobuf::Message* Message;
};
