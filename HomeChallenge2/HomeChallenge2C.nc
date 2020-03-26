#include "HomeChallenge2.h"
#include "Timer.h"

module HomeChallenge2C {

  uses {
  /****** INTERFACES *****/
	interface Boot; 
	
    //interfaces for communication
	interface SplitControl;
	interface Packet;
  	interface AMSend;
  	interface Receive;

	//interface for timer
 	interface Timer<TMilli> as Timer0;	

    //other interfaces, if needed
	interface PacketAcknowledgements;
	
	//interface used to perform sensor reading (to get the value from a sensor)
	interface Read<uint16_t>;
  }

} implementation {

  uint8_t counter = 0;
  uint8_t rec_id;
  message_t packet;

  void sendReq();
  void sendResp();
  
  
  //***************** Send request function ********************//
  void sendReq() {
  	my_msg_t* rcm = (my_msg_t*)call Packet.getPayload(&packet, sizeof(my_msg_t));
	dbg("radio_send", "Creating the message.\n");
	// Creating the msg
    if (rcm == NULL) {
		return;
    }
	rcm->msg_type = REQ;
	rcm->msg_counter = counter;
	rcm->value = 0;
	dbg("radio_send", "Sending the request. Counter = %d.\n", rcm->msg_counter);
	// Set the ACK flag for the message using the PacketAcknowledgements interface
	if (call PacketAcknowledgements.requestAck(&packet) == SUCCESS) {
		dbg("radio_send", "ACK enabled.\n");
	}
	else {
    	dbgerror("radio_send", "Error with ACK request! for counter = %d\n", rcm->msg_counter);
	}
	// Send an UNICAST message to the correct node
	if(call AMSend.send(2, &packet,sizeof(my_msg_t)) == SUCCESS){
	    dbg("radio_send", "Packet passed to lower layer successfully!\n");
	    dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength(&packet));
	    dbg_clear("radio_pack","\t Payload Sent\n");
		dbg_clear("radio_pack", "\t\t type: %hhu (1: REQ, 2:RESP)\n", rcm->msg_type);
		dbg_clear("radio_pack", "\t\t counter: %hhu \n", rcm->msg_counter);
		dbg_clear("radio_pack", "\t\t (value: %hhu)\n", rcm->value);	 
  	}
 }        

  //****************** Task send response *****************//
  void sendResp() {
	dbg("radio_send", "Reading from the sensor...\n");
	call Read.read();
  }

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted. Current Node: %d\n", TOS_NODE_ID);
	call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
	if ( err == SUCCESS) {
		dbg("radio", "Radio successfully on.\n");
		if (TOS_NODE_ID == 1) {
			dbg("radio", "Node %d: starting timer.\n", TOS_NODE_ID);
			call Timer0.startPeriodic(1000);
		}
	}
  }
  
  event void SplitControl.stopDone(error_t err){
    /* Fill it ... */
	dbg("role", "Shutting down motes... \n");
	dbg("role", "End of communication. \n");
  }

  //***************** MilliTimer interface ********************//
  event void Timer0.fired() {
	dbg("boot", "Timer Fired!\n");
	sendReq();
  }
  

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {
	my_msg_t* rcm = (my_msg_t*)call Packet.getPayload(&packet, sizeof(my_msg_t));
	// Check if the packet is sent
	if (&packet == buf && err == SUCCESS) {
      	dbg("radio_send", "Packet sent...");
    	dbg_clear("radio_send", " at time %s \n", sim_time_string());
		counter++;
		if(rcm->msg_type == REQ){
			dbg("radio_send", "Counter increased, new value = %d\n", counter);
		}
    }
    else{
      	dbgerror("radio_send", "Send done error!");
    }
	// Check if the ACK is received
	if (call PacketAcknowledgements.wasAcked(&packet)) {
      	dbg_clear("radio_ack", "Ack received at time %s.\n", sim_time_string());
 	  	dbg_clear("radio_ack", "\t\t counter: %hhu \n", rcm->msg_counter);
		// Stop the timer
		if(rcm->msg_type == RESP){
			call SplitControl.stop();
		}
		else{
			dbg("radio", "Timer stopped.\n");
			call Timer0.stop();
		}
    }
    else{
      	dbgerror("radio_ack", "Ack not received!\n");
    }
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	if (len != sizeof(my_msg_t)) {

      	dbgerror("radio_rec", "Receiving error \n");
		return buf;
	}
    else {
    	my_msg_t* rcm = (my_msg_t*)payload;
		// Read the content of the message
    	dbg("radio_rec", "Received packet at time %s\n", sim_time_string());
    	dbg("radio_pack"," Payload length %hhu \n", call Packet.payloadLength( buf ));
    	dbg("radio_pack", ">>>Pack \n");
    	dbg_clear("radio_pack","\t\t Payload Received\n" );
    	dbg_clear("radio_pack", "\t\t type: %hhu (1: REQ, 2:RESP)\n ", rcm->msg_type);
		dbg_clear("radio_pack", "\t\t counter: %hhu \n", rcm->msg_counter);
		dbg_clear("radio_pack", "\t\t value: %hhu \n", rcm->value);

		// Check if the type is request (REQ)
		if (rcm->msg_type == REQ) {
			dbg("radio_rec", "Request received, sending the response...\n");
			// Saving the counter value
			rec_id = rcm->msg_counter;
			// Send the response
			sendResp();
		} else {
			//Received a response (RESP)
			dbg("radio_rec", "Response received. Value of the sensor = %hhu\n", rcm->value);
		}

      	return buf;
    }
  }
  
  //************************* Read interface **********************//
  event void Read.readDone(error_t result, uint16_t data) {
	// Prepare the response (RESP)
	my_msg_t* rcm = (my_msg_t*)call Packet.getPayload(&packet, sizeof(my_msg_t));
	dbg("role","Sensor's read value: %hhu\n", data);
	if (rcm == NULL) {
		return;
    }
	rcm->msg_type = RESP;
	rcm->msg_counter = rec_id;
	rcm->value = data;
	dbg("radio_send", "Sending the response.\n");
	// Set the ACK flag for the message using the PacketAcknowledgements interface
	if (call PacketAcknowledgements.requestAck(&packet) == SUCCESS) {
		dbg("radio_send", "ACK enabled.\n");
	}
	else {
    	dbgerror("radio_send", "Error with ACK request! for counter = %d\n", rcm->msg_counter);
	}

	// Send an UNICAST message to the correct node
	if(call AMSend.send(1, &packet,sizeof(my_msg_t)) == SUCCESS){
	    dbg("radio_send", "Packet passed to lower layer successfully!\n");
	    dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength(&packet));
	    dbg_clear("radio_pack","\t Payload Sent\n");
		dbg_clear("radio_pack", "\t\t type: %hhu (1: REQ, 2:RESP)\n", rcm->msg_type);
		dbg_clear("radio_pack", "\t\t counter: %hhu \n", rcm->msg_counter);
		dbg_clear("radio_pack", "\t\t value: %hhu\n", rcm->value); 
  	}
  	}
}
