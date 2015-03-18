#ifndef AD_SENSOR__
#define AD_SENSOR__

#define AM_SERIAL_ADC 1

#include "AM.h"

typedef nx_struct adc_msg{
	nx_uint16_t counter;
	nx_uint16_t voltage;
}adc_msg_t;

#endif