#ifndef HOME_CHALLENGE_1_H
#define HOME_CHALLENGE_1_H

typedef nx_struct radio_message {
  nx_uint16_t counter;
  nx_uint16_t moteID;

} radio_message;

enum {
  AM_RADIO_COUNT_MSG = 6,
};

#endif
