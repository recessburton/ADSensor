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
#include "printf.h"

module ADSensorC {
  provides {
    interface AdcConfigure<const msp430adc12_channel_config_t*> as HumidConfigure;
  }
  uses {
    interface Boot;
    interface Read<uint16_t> as HumidRead;
    interface Leds;

		interface Timer<TMilli> as Timer;
  }
}
implementation {
	uint16_t count;

  const msp430adc12_channel_config_t config = {
  	/*详细配置可用的取值见Msp430Adc12.h头文件*/
      inch: INPUT_CHANNEL_A0,		
       // inch: SUPPLY_VOLTAGE_HALF_CHANNEL,					
      /*输入通道。在电压采集的测试中，无论A0，A1，A2，A3等，
       * 均能得到900左右的电压值。不知为何？这个通道的选择难道并不对应着10pin针脚处的通道么？？
       */
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
	
	call Timer.startPeriodic(512);
	count = 0;
  }

	event void Timer.fired()
	{
    call HumidRead.read();
		call Leds.led2Toggle();
	}

  event void HumidRead.readDone( error_t result, uint16_t val )
  {
    if (result == SUCCESS){
			adc_msg_t* adc =(adc_msg_t*) malloc(sizeof(adc_msg_t));
			adc->humid = val;
			adc->counter = count++;
			
			//可以通过java net.tinyos.tools.PrintfClient -comm serial@/dev/ttyUSB0:tmote 来接收消息
			printf("counter:%u, Humid:%u\n",adc->counter,adc->humid);
			printfflush();

			call Leds.led0Toggle();
		}
  }

  async command const msp430adc12_channel_config_t* HumidConfigure.getConfiguration()
  {
    return &config; // must not be changed
  }
}

