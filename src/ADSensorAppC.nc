/*
 * Copyright (C)  ytc recessburton@gmail.com 2015-3-18
 *

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 * ========================================================================
 */

#include "ADSensor.h"

#define NEW_PRINTF_SEMANTICS

configuration ADSensorAppC {
}
implementation {
  components MainC, ADSensorC, new AdcReadClientC(), LedsC;
  
	components PrintfC;
	components SerialStartC;

  MainC.Boot <- ADSensorC;
  ADSensorC.VoltageRead -> AdcReadClientC;
  AdcReadClientC.AdcConfigure -> ADSensorC.VoltageConfigure;
  ADSensorC.Leds -> LedsC;

	components new TimerMilliC() as  TimerC;
	ADSensorC.Timer -> TimerC;
}

