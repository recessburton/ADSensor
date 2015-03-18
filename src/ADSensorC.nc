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


#include "Msp430Adc12.h"
#include "ADSensor.h"

module ADSensorC {
  provides {
    interface AdcConfigure<const msp430adc12_channel_config_t*> as VoltageConfigure;
  }
  uses {
    interface Boot;
    interface Read<uint16_t> as VoltageRead;
    interface Leds;

		interface AMSend as SerialSend;
		interface SplitControl as SerialControl;
		interface Timer<TMilli> as Timer;
  }
}
implementation {

	message_t serialMsg;
	uint16_t count;

  const msp430adc12_channel_config_t config = {
      inch: INPUT_CHANNEL_A0,
     // inch: SUPPLY_VOLTAGE_HALF_CHANNEL,
      sref: REFERENCE_VREFplus_AVss,
      ref2_5v: REFVOLT_LEVEL_2_5,
      adc12ssel: SHT_SOURCE_ACLK,
      adc12div: SHT_CLOCK_DIV_1,
      sht: SAMPLE_HOLD_4_CYCLES,
      sampcon_ssel: SAMPCON_SOURCE_SMCLK,
      sampcon_id: SAMPCON_CLOCK_DIV_1
  };

  event void Boot.booted() 
  {
    call Leds.led0Off();
    call Leds.led1Off();
    call Leds.led2Off();

		call SerialControl.start();
		call Timer.startPeriodic(512);
		count = 0;
  }

	event void SerialControl.startDone(error_t error) {}
	event void SerialControl.stopDone(error_t error) {}
	event void SerialSend.sendDone(message_t* msg, error_t error)
	{
		call Leds.led1Toggle();
	}

	event void Timer.fired()
	{
    call VoltageRead.read();
		call Leds.led2Toggle();
	}

  event void VoltageRead.readDone( error_t result, uint16_t val )
  {
    if (result == SUCCESS){
			adc_msg_t* adc = (adc_msg_t*) call SerialSend.getPayload(&serialMsg, sizeof(adc_msg_t));
			adc->voltage = val;
			adc->counter = count++;
			call SerialSend.send(0xffff, &serialMsg, sizeof(adc_msg_t));

			call Leds.led0Toggle();
		}
  }

  async command const msp430adc12_channel_config_t* VoltageConfigure.getConfiguration()
  {
    return &config; // must not be changed
  }
}

