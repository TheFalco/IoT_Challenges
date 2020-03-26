#include "sendAck.h"

configuration sendAckAppC {}

implementation {


/****** COMPONENTS *****/
  components MainC, sendAckC as App;
  components new TimerMilliC() as Timer0;
  components new FakeSensorC();
  //Dobbiamo usare anche fakesensorP?  
  components ActiveMessageC;
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);

/****** INTERFACES *****/
  //Boot interface
  App.Boot -> MainC.Boot;

  /****** Wire the other interfaces down here *****/
  //Send and Receive interfaces
  App.AMSend -> AMSenderC;
  App.Packet -> AMSenderC;
  App.Receive -> AMReceiverC;
  //Radio Control
  App.SplitControl -> ActiveMessageC;
  //Interfaces to access package fields
  App.PacketAcknowledgements -> AMSenderC.Acks;
  //Timer interface
  App.Timer0 -> Timer0;
  //Fake Sensor read
  App.Read -> FakeSensorC;

}

