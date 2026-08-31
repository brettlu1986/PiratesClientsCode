#pragma once


struct FPiratesMovementUtil
{
    static constexpr float SMALL_LINEAR_DISTANCE = 0.015625f;
    static constexpr float SMALL_ANGULAR_DEGREE = 0.0001f;
    static constexpr float SMALL_MOVEMENT_TIME = 0.001953125f;
    static constexpr float SMALL_MOVEMENT_LERP_TIME = 0.001f;
    static constexpr float DegreesToRadiansFactor = PI / 180.f;
    
    static FORCEINLINE FVector ComputeMoveVector(float Yaw, float Distance)
    {
        float Radian = DegreesToRadiansFactor * Yaw;
        return FVector(FMath::Cos(Radian) * Distance, FMath::Sin(Radian) * Distance, 0.f);
    }

    static FORCEINLINE float BoundYaw(float Yaw)
    {
        while (Yaw > 180.f)
        {
            Yaw -= 360.f;
        }
        while (Yaw < -180.f)
        {
            Yaw += 360.f;
        }

        return Yaw;
    }

    static FORCEINLINE bool CheckFloatEqual(float A, float B, float Tolerance = KINDA_SMALL_NUMBER)
    {
        return (FMath::Abs(A - B) <= Tolerance);
    }

    static FORCEINLINE bool CheckFloatSameSign(float A, float B)
    {
        return A * B >= 0.f;
    }

    static FORCEINLINE bool CheckYawAreEqual(float YawA, float YawB, float Tolerance = SMALL_ANGULAR_DEGREE)
    {
        float YawDiff = BoundYaw(YawA - YawB);
        return (FMath::Abs(YawDiff) < Tolerance);
    }

    template< class T>
    static FORCEINLINE T Lerp(const T& Start, const T& End, float Alpha)
    {
        // Orign formula is (1 - Alpha) * Start + Alpha * End
        // Alpha should be in [0, 1]
        return (T)((End - Start) * Alpha + Start);
    }
    
    template< class T>
    static FORCEINLINE T QuadraticInLerp(const T& Start, const T& End, float Alpha)
    {
        return Lerp(Start, End, Alpha * Alpha);
    }

    template< class T>
    static FORCEINLINE T QuadraticOutLerp(const T& Start, const T& End, float Alpha)
    {
        T Middle = (Start + End) * 0.5;
        Alpha += Alpha;

        if (Alpha > 1.f)
        {
            return QuadraticInLerp(Middle, End, Alpha - 1.f);
        }
        else
        {
            return QuadraticInLerp(Start, Middle, Alpha);
        }
    }

    static FORCEINLINE float LerpYaw(float StartYaw, float EndYaw, float Alpha)
    {
        return BoundYaw(BoundYaw(EndYaw - StartYaw) * Alpha + StartYaw);
    }

    static FORCEINLINE bool GetBitField(uint32 BitFields, uint32 Field)
    {
        return (BitFields & Field) == Field;
    }

    static FORCEINLINE void SetBitField(uint32& BitFields, uint32 Field, bool bSet)
    {
        if (bSet)
        {
            BitFields |= Field;
        }
        else
        {
            BitFields &= ~Field;
        }
    }
};