#include "Timer.h"
#include "HomeChallenge1.h"

module HomeChallenge1C @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as Timer0;
    interface Timer<TMilli> as Timer1;
    interface Timer<TMilli> as Timer2;
    interface SplitControl as AMControl;
    interface Packet;
    }
}
implementation {

  message_t packet;

  bool locked;
  uint16_t counter = 0;	//Integer we define the size and they must be unsigned
  
  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {

		if (TOS_NODE_ID == 1) {    
		  call Timer0.startPeriodic(1000);
		}
		else if (TOS_NODE_ID == 2) {
		  call Timer1.startPeriodic(333);
		}
		else {
		  call Timer2.startPeriodic(200);
		}
	}
	else {
		call AMControl.start();
	}
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  
  // event for the first mote
  event void Timer0.fired() {
    
    if (locked) {
      return;
    }
    else {
      radio_message* rcm = (radio_message*)call Packet.getPayload(&packet, sizeof(radio_message));
      if (rcm == NULL) {
		return;
      }
      //Creating the message
      rcm->counter = counter;
      rcm->moteID  = TOS_NODE_ID;
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_message)) == SUCCESS) { //send message as broadcast
	    locked = TRUE;
      }
    }
  }

    // event for the second mote
    event void Timer1.fired() {
    
    if (locked) {
      return;
    }
    else {
      radio_message* rcm = (radio_message*)call Packet.getPayload(&packet, sizeof(radio_message));
      if (rcm == NULL) {
		return;
      }
      //Creating the message
      rcm->counter = counter;
      rcm->moteID  = TOS_NODE_ID;
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_message)) == SUCCESS) { //send message as broadcast
	    locked = TRUE;
      }
    }
  }

  // event for the third mote
  event void Timer2.fired() {
    
    if (locked) {
      return;
    }
    else {
      radio_message* rcm = (radio_message*)call Packet.getPayload(&packet, sizeof(radio_message));
      if (rcm == NULL) {
		return;
      }
      //Creating the message
      rcm->counter = counter;
      rcm->moteID  = TOS_NODE_ID;
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_message)) == SUCCESS) { //send message as broadcast
	    locked = TRUE;
      }
    }
  }
  
  //event for receving the message
  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    // we check the size of message
    radio_message* rcm;
    if (len != sizeof(radio_message)) {
    	return bufPtr;
    }
    else {
      counter++;
      rcm = (radio_message*)payload;
      if (rcm->moteID == 1) {
          call Leds.led0Toggle();
      }
      if (rcm->moteID == 2) {
          call Leds.led1Toggle();
      }
      if (rcm->moteID == 3) {
          call Leds.led2Toggle();
      }
      
      //Turning off all LEDs
      if ((rcm->counter) % 10 == 0) {
        call Leds.led0Off();
        call Leds.led1Off();
        call Leds.led2Off();
      }
      
      return bufPtr;
    }
  }

  // free the mote after ending the transmission
  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

}

