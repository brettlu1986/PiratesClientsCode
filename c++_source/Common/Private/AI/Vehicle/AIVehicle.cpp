#include "AI/Vehicle/AIVehicle.h"

void FAIVehicleCell::Add(FAIVehicle* Vehicle)
{
    if (Vehicle)
    {
        Vehicle->Unlink();
        Vehicle->LinkAfter(&VehicleHead);
    }
}

