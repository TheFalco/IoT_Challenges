#ifndef HC5_H
#define HC5_H

typedef nx_struct radio_msg {
  nx_uint16_t value;
  nx_uint16_t topic;
} radio_msg_t;

enum {
  AM_RADIO_COUNT_MSG = 6,
};

#endif