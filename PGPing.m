//
//  PGPing.m
//  pinger
//
//  Created by lk on 16/5/4.
//  Copyright © 2016年 lk. All rights reserved.
//

#import "PGPing.h"
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/time.h>
#include <stdio.h>
#include <netdb.h>

typedef struct {
    uint8_t     versionAndHeaderLength;
    uint8_t     differentiatedServices;
    uint16_t    totalLength;
    uint16_t    identification;
    uint16_t    flagsAndFragmentOffset;
    uint8_t     timeToLive;
    uint8_t     protocol;
    uint16_t    headerChecksum;
    uint8_t     sourceAddress[4];
    uint8_t     destinationAddress[4];
    // options...
    // data...
} IP_PACKET;


// header
//Bits	160-167	168-175	176-183	184-191
//160     Type	Code	校验码（checksum）
//192         ID	序号（sequence）
typedef struct
{
    //header
    uint8_t type;
    uint8_t code;
    uint16_t checksum;
    uint16_t id;
    uint16_t seq;
    //linux style, total 64B
    char fills[56];
}
ICMP_PACKET;

uint16_t in_cksum(const void *buffer, size_t bufferLen)
// This is the standard BSD checksum code, modified to use modern types.
{
    /*
     将数据以字（16位）为单位累加到一个双字中
     如果数据长度为奇数，最后一个字节将被扩展到字，累加的结果是一个双字，
     最后将这个双字的高16位和低16位相加后取反
     */
    size_t              bytesLeft;
    int32_t             sum;
    const uint16_t *    cursor;
    union {
        uint16_t        us;
        uint8_t         uc[2];
    } last;
    uint16_t            answer;
    
    bytesLeft = bufferLen;
    sum = 0;
    cursor = (uint16_t*)buffer;
    
    while (bytesLeft > 1) {
        sum += *cursor;
        cursor += 1;
        bytesLeft -= 2;
    }
    
    /* mop up an odd byte, if necessary */
    if (bytesLeft == 1) {
        last.uc[0] = * (const uint8_t *) cursor;
        last.uc[1] = 0;
        sum += last.us;
    }
    
    /* add back carry outs from top 16 bits to low 16 bits */
    sum = (sum >> 16) + (sum & 0xffff);	/* add hi 16 to low 16 */
    sum += (sum >> 16);			/* add carry */
    answer = (uint16_t) ~sum;   /* truncate to 16 bits */
    
    return answer;
}

@implementation PGPing

+(int)sendtoHost:(NSString *)hostAddress {
    int client = socket(PF_INET,SOCK_DGRAM,IPPROTO_ICMP);
    struct timeval tv;
    tv.tv_sec = 1;
    tv.tv_usec = 0;// 1 sec timeout
    if (setsockopt(client, SOL_SOCKET, SO_RCVTIMEO,&tv,sizeof(tv)) < 0) {
        NSLog(@"error setting timeout");
    }
    struct sockaddr_in remote_addr;
    memset(&remote_addr,0,sizeof(remote_addr)); //init
    remote_addr.sin_family=AF_INET;
    char *raw = hostAddress.UTF8String;
    // resolve domain
    struct hostent *he = gethostbyname(raw);
    struct in_addr **addrs = he->h_addr_list;
    in_addr_t inad = addrs[0]->s_addr;
    remote_addr.sin_addr.s_addr= inad;
    //icmp
    ICMP_PACKET packet;
    packet.type = 8; // echo request
    packet.code = 0;
    packet.checksum = 0;
    packet.id = rand();
    packet.seq = rand();
    memset(&packet.fills, 65, 56);
    packet.checksum = in_cksum(&packet, sizeof(ICMP_PACKET));
    size_t rt = sendto(client, &packet, sizeof(ICMP_PACKET) , 0 , (struct sockaddr*)&remote_addr, sizeof(struct sockaddr_in));
    struct timeval now;
    gettimeofday(&now, NULL);
    if (rt) {
        IP_PACKET reply_ip;
        ICMP_PACKET reply;
        char buf[1024];
        struct sockaddr_in recv_addr;
        socklen_t len;
        rt = recvfrom(client, &buf, 1024, 0, (struct sockaddr*)&recv_addr, &len);
        // 20B ip + 64B ICMP
        if (rt == 84) {
            memcpy(&reply_ip, &buf, sizeof(IP_PACKET));
            memcpy(&reply, &buf[sizeof(IP_PACKET)], sizeof(ICMP_PACKET));
            struct timeval after;
            gettimeofday(&after, NULL);
            // cal delta ms.
            long dt = (after.tv_sec*1000 + after.tv_usec/1000) - (now.tv_sec*1000 + now.tv_usec/1000);
            NSLog(@"%ld ms.",dt);
            if (reply.seq == packet.seq) {
                return dt;
            } else {
                return -1;
            }
        } else {
            NSLog(@"no response");
        }
    }
    return -1;
}

@end
