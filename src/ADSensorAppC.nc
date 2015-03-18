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

/**
 * 
 * Sensing demo application. See README.txt file in this directory for usage
 * instructions and have a look at tinyos-2.x/doc/html/tutorial/lesson5.html
 * for a general tutorial on sensing in TinyOS.
 * 
 * @author Jan Hauer
 */

#include "Timer.h"
//#include "SenseTelosb.h"
//#include "SenseTelosb2.h"
#include "SenseTelosb3.h"
#include "TxPower.h"


configuration SenseAppC 
{ 
} 
implementation { 
  
  components SenseC, MainC, LedsC;
  components new TimerMilliC() as Timer1;
  components new TimerMilliC() as Timer2;

  components new SensirionSht11C()    as TempHumiSensor; // the sensor built in telosb mote
  components new HamamatsuS1087ParC() as LightSensor;
  components new VoltageC()           as BattSample; // the batter voltage level
  components new VoltageC()           as BattCheck;

  components new Msp430Adc12ClientC() as Adc;

  components ActiveMessageC; 
  components CC2420ActiveMessageC;
  components new AMSenderC(AM_SENSETELOSBMSG);

  SenseC.Boot -> MainC;
  SenseC.Leds -> LedsC;
  SenseC.TimerBattCheck -> Timer1;
  SenseC.TimerSample -> Timer2;

  SenseC.ReadTemperature -> TempHumiSensor.Temperature;
  SenseC.ReadHumidity -> TempHumiSensor.Humidity;
  SenseC.ReadLight -> LightSensor;
  SenseC.ReadBattSample -> BattSample;
  SenseC.ReadBattCheck -> BattCheck;

  SenseC.Resource -> Adc;
  SenseC.Adc0 -> Adc.Msp430Adc12SingleChannel;


  SenseC.RadioControl -> ActiveMessageC;
  SenseC.AMPacket -> AMSenderC;
  SenseC.AMSend -> AMSenderC;
  SenseC.Packet -> AMSenderC;
  SenseC.CC2420Packet -> CC2420ActiveMessageC;

#if defined(PLATFORM_TELOSB) || defined(PLATFORM_TMOTE) || defined(PLATFORM_MICAZ)
  components CC2420ActiveMessageC as LPLProvider;
  SenseC.LPL -> LPLProvider;
#endif

#if defined(PLATFORM_MICA2)
  components CC1000CsmaRadioC as LPLProvider;
  SenseC.LPL -> LPLProvider;
#endif

#if defined(PLATFORM_IRIS)
  components RF230ActiveMessageC as LPLProvider;
  SenseC.LPL -> LPLProvider;
#endif

}
