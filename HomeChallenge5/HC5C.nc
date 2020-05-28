#include "printf.h"
#include "Timer.h"
#include "HC5.h"

module HC5C {
  uses {
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
    interface Random;
  }
}

implementation {
  message_t packet;
  bool locked;
 
  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (TOS_NODE_ID != 1) {
      call MilliTimer.startPeriodic(5000);	
    } 
  }

  event void MilliTimer.fired() {
    if (locked) {
      return;
    }
    else {
      radio_msg_t* rcm = (radio_msg_t*)call Packet.getPayload(&packet, sizeof(radio_msg_t));
      if (rcm == NULL) {
        return;
      }
      rcm->value = call Random.rand16();
      //The message should be between 0 and 100
      if (rcm->value >= 100) {
        rcm->value = rcm->value%100;
      }
      rcm->topic = TOS_NODE_ID;
      //Send message to node 1
      if (call AMSend.send(1, &packet, sizeof(radio_msg_t)) == SUCCESS) {
        locked = TRUE;
      }
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    if (len != sizeof(radio_msg_t)) {
      return bufPtr;
    }
    else {
      radio_msg_t* rcm = (radio_msg_t*)payload;
      printf("%u,%u\n", rcm->value, rcm->topic);
      return bufPtr;
    }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
}
