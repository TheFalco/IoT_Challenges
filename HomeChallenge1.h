#ifndef HOME_CHALLENGE_1_H
#define HOME_CHALLENGE_1_H

typedef nx_struct radio_count_msg {
  nx_uint16_t counter;
  nx_unit16_t moteID;

} radio_count_msg_t;

enum {
  AM_RADIO_COUNT_MSG = 6,
};

#endif