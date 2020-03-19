#include "HomeChallenge1.h"

configuration HomeChallenge1AppC {}
implementation {
  components MainC, HomeChallenge1C, LedsC;
  components new AMSenderC(AM_RADIO_COUNT_MSG);
  components new AMReceiverC(AM_RADIO_COUNT_MSG);
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components new TimerMilliC() as Timer2;  
  components ActiveMessageC;
  
  HomeChallenge1C.Boot -> MainC.Boot;
  
  HomeChallenge1C.Receive -> AMReceiverC;
  HomeChallenge1C.AMSend -> AMSenderC;
  HomeChallenge1C.AMControl -> ActiveMessageC;
  HomeChallenge1C.Leds -> LedsC;
  HomeChallenge1C.Timer0 -> Timer0;
  HomeChallenge1C.Timer1 -> Timer1;
  HomeChallenge1C.Timer2 -> Timer2;  
  HomeChallenge1C.Packet -> AMSenderC;
}


