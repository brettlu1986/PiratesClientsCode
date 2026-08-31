// Fill out your copyright notice in the Description page of Project Settings.

#include "PiratesDPICustomScalingRule.h"
#include "Common.h"

const float DEFAULT_WIDTH = 1920.f;
const float DEFAULT_HEIGHT = 1080.f;
const float DEFAULT_ASPECT = DEFAULT_WIDTH / DEFAULT_HEIGHT;

float UPiratesDPICustomScalingRule::GetDPIScaleBasedOnSize(FIntPoint Size) const
{
	if (Size.Y > 0.f)
	{
		if (Size.X / (Size.Y * 1.f) < DEFAULT_ASPECT)
		{
			return Size.X / DEFAULT_WIDTH;
		}
		else
		{
			return Size.Y / DEFAULT_HEIGHT;
		}
	}
	return 1.f;
}