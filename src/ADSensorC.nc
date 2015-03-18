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
#include "SenseTelosb.h"
#include "LPLSetting.h"
#include "Msp430Adc12.h"

module SenseC
{
  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli>  as TimerBattCheck;
    interface Timer<TMilli>  as TimerSample;
    interface Read<uint16_t> as ReadTemperature;
    interface Read<uint16_t> as ReadHumidity;
    interface Read<uint16_t> as ReadLight;
    interface Read<uint16_t> as ReadBattCheck;
    interface Read<uint16_t> as ReadBattSample;
  }

  uses{
    interface Resource;
    interface Msp430Adc12SingleChannel as Adc0;
  }

  provides interface AdcConfigure<const msp430adc12_channel_config_t*> as Config;

  uses interface SplitControl as RadioControl;
  uses interface CC2420Packet;
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;

  uses interface LowPowerListening as LPL;

}
implementation
{
  /***********************************************************************
   * Configure the Adc channel 0
   *
   **********************************************************************/
  const msp430adc12_channel_config_t config = {
    inch:         INPUT_CHANNEL_A0,
    sref:         REFERENCE_VREFplus_AVss,
    ref2_5v:      REFVOLT_LEVEL_1_5,
    adc12ssel:    SHT_SOURCE_ACLK,
    adc12div:     SHT_CLOCK_DIV_1,
    sht:          SAMPLE_HOLD_4_CYCLES,
    sampcon_ssel: SAMPCON_SOURCE_SMCLK,
    sampcon_id:   SAMPCON_CLOCK_DIV_1
  };



  message_t pkt;
  
  bool radio_busy = FALSE;

  uint16_t sequence = 0;
  uint16_t temperature = 0;
  uint16_t humidity = 0;
  uint16_t light = 0;
  uint16_t battery = 0;
  norace uint16_t adc0;

  uint8_t tx_power = TX_POWER_19;

  norace bool TEMP_OK  = FALSE;
  norace bool HUMID_OK = FALSE;
  norace bool LIGHT_OK = FALSE;
  norace bool BATT_OK  = FALSE;
  norace bool ADC0_OK  = FALSE;

  /***********************************************************************/
  task void sendMsg();

  task void getAdc0(){ call Resource.request(); }

  void startSense(){
      call ReadHumidity.read();
      call ReadTemperature.read();
      call ReadLight.read();
      call ReadBattSample.read();
      post getAdc0();
  }

  /***********************************************************************/

  event void Resource.granted() {
    if( call Adc0.configureSingle( &config ) == SUCCESS )
      call Adc0.getData();
  }
  async event error_t Adc0.singleDataReady( uint16_t data ){
    adc0 = data;
    call Resource.release();
    ADC0_OK = TRUE;

    if( TEMP_OK && HUMID_OK && LIGHT_OK && BATT_OK && ADC0_OK )
      post sendMsg();

    return FAIL;
  }

  async event uint16_t* Adc0.multipleDataReady( uint16_t* buff, uint16_t length ){
    return 0;
  }

 
  /***************************************************************************/
  event void Boot.booted() {
    call LPL.setLocalSleepInterval( LPL_INTERVAL );
    call RadioControl.start();
  }

  /*
   * Once the system is started successfully, it will check whether
   * the battery is enough to support the tasks.
   */
  event void RadioControl.startDone(error_t result ){
    if( result == SUCCESS )
      call TimerBattCheck.startPeriodic( BATT_CHECKING_PERIOD );
    else
      call RadioControl.start();
  }

  event void RadioControl.stopDone( error_t result){}

  event void TimerBattCheck.fired(){ call ReadBattCheck.read(); }

  event void ReadBattCheck.readDone( error_t err, uint16_t data ){
    if( err == SUCCESS ){
      if( data <= LOW_BATTERY ){
	call TimerSample.stop();
      }else{
	if( data >= UP_BATTERY )
	  call TimerSample.startPeriodic( SAMPLING_PERIOD );
	else{
	  call TimerSample.stop();
	}
      }

    }else{// handle the wrong battery readings
  
    }
  }


  event void TimerSample.fired() 
  {
    startSense();      
  }

 
  event void ReadHumidity.readDone(error_t err, uint16_t data ){
    if( err == SUCCESS ){
      humidity = data;
      HUMID_OK = TRUE;
      
      if( TEMP_OK && HUMID_OK && LIGHT_OK && BATT_OK && ADC0_OK )
	post sendMsg();
    }
    else
      humidity = 0xffff;
  }

  event void ReadTemperature.readDone( error_t err, uint16_t data ) {
    if( err == SUCCESS ) {
      temperature = data;
      TEMP_OK = TRUE;
      
      if( TEMP_OK && HUMID_OK && LIGHT_OK && BATT_OK && ADC0_OK  )
	post sendMsg();
    }
    else
      temperature = 0xffff;
  }

  event void ReadLight.readDone(error_t err, uint16_t data) 
  {
    if (err == SUCCESS ){
      light = data;
      LIGHT_OK = TRUE;
      
      if( TEMP_OK && HUMID_OK && LIGHT_OK && BATT_OK && ADC0_OK )
	post sendMsg();
    }
    else
      light = 0xffff;
  }
   
  event void ReadBattSample.readDone(error_t err, uint16_t data) 
  {
    if( err == SUCCESS ){
      battery = data;
      BATT_OK = TRUE;

      if( battery <= LOW_BATTERY ){
	call TimerBattCheck.startOneShot( BATT_CHECKING_PERIOD );
	BATT_OK = FALSE; // prevent radio from sending when energy is approaching to LOW_BATTERY
      }
      
      if( TEMP_OK && HUMID_OK && LIGHT_OK && BATT_OK && ADC0_OK  ){
	post sendMsg();
      }
    }else
      battery = 0xffff;
  }


  task void sendMsg() {

    if( !radio_busy ) {

      sense_telosb_msg_t* btrpkt=(sense_telosb_msg_t*)call Packet.getPayload(&pkt, sizeof(sense_telosb_msg_t));

      btrpkt->temperature = temperature;
      btrpkt->humidity    = humidity;
      btrpkt->light       = light;
      btrpkt->battery     = battery;
      btrpkt->sequence    = sequence++;
      btrpkt->node_id     = TOS_NODE_ID;
      btrpkt->adc0        = adc0;

      TEMP_OK = HUMID_OK  = LIGHT_OK = BATT_OK = ADC0_OK = FALSE;
 
      if( btrpkt == NULL) return;

      call LPL.setRxSleepInterval( &pkt, 0 );
      call CC2420Packet.setPower( &pkt, tx_power );

      if( call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(sense_telosb_msg_t))==SUCCESS ){
	radio_busy = TRUE;
      }
      
    }

  }


  event void AMSend.sendDone( message_t* msg, error_t err ){
    if( &pkt == msg && err == SUCCESS ){
      radio_busy = FALSE;

    }
    /*
    if( sequence == MAX_SEQUENCE ){
      call TimerSample.stop();
    }
    */

  }

  async command const msp430adc12_channel_config_t* Config.getConfiguration() {
    return &config;
  }
}
