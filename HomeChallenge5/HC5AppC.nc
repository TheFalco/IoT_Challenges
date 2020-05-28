 
// Note: You can also add this define in your makefile to supress the 
//       warning about the new printf semanics.  Just all the following line:
//       CFLAGS += -DNEW_PRINTF_SEMANTICS
#define NEW_PRINTF_SEMANTICS
#include "printf.h"
#include "HC5.h"

configuration HC5AppC{
}
implementation {
  components MainC, HC5C as App;
  components new TimerMilliC();
  components PrintfC;
  components SerialStartC;
  components new AMSenderC(AM_RADIO_COUNT_MSG);
  components new AMReceiverC(AM_RADIO_COUNT_MSG);
  components ActiveMessageC;
  components RandomC;

  App.Boot -> MainC.Boot;
  App.MilliTimer -> TimerMilliC;
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.Packet -> AMSenderC;
  App.Random -> RandomC;
}
