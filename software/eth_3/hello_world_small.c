#include "system.h"
#include <string.h>
#include <stdio.h>

#include "altera_avalon_sgdma_regs.h"
#include "altera_avalon_sgdma.h"

#include "altera_avalon_tse.h"
#include "altera_eth_tse_regs.h"

#include "altera_avalon_timer.h"
#include "altera_avalon_timer_regs.h"

#include "sys/alt_stdio.h"
#include "HAL/inc/sys/alt_irq.h"
#include "HAL/inc/sys/alt_cache.h"

#include "alt_types.h"
#include "IO.h"

/*********************** Constant ***********************/
// Definition of payload type transmit in RTP
const char RTP_PAYLOAD_TYPE = 26;

/******************* Declare Structure *******************/
// Structure of ETH header - piece of ETH frame
struct eth_hdr
{
	alt_u8 mac_dest[6];				// MAC-address destination
	alt_u8 mac_src[6];				// MAC-address source
};

// Structure of ARP packet (encapsulation in ETH frame)
struct arp_packet
{
	alt_u16 eth_type;				// Type of protocol encapsulation (ARP = 0x0806)
	alt_u16 hw_type;				// Type of Hardware (Ethernet = 1)
	alt_u16 proto_type;  			// Type of protocol (IPv4 = 0x0800)
	alt_u8 hw_len;       			// Length MAC-address (6)
	alt_u8 proto_len;    			// Length of IP-address (4)
	alt_u16 operation;      		// Operation (ARP-request = 1, ARP-reply = 2)
	alt_u8 sender_mac[6];  			// MAC-address sender
	alt_u8 sender_ip[4];   			// IP-address sender
	alt_u8 target_mac[6];  			// MAC-address target
	alt_u8 target_ip[4];   			// IP-address target
};

// Structure of IP header - piece of IP packet (encapsulation in ETH frame)
struct ip_hdr
{
	alt_u16 eth_type;				// Type of protocol encapsulation (IPv4 = 0x0800)
	alt_u8 ver_ihl;					// Version and IP Header Length
	alt_u8 tos;						// Type of Service
	alt_u16 len;					// Total Length IP (header with Data)
	alt_u16 id;						// Identification
	alt_u16 flags_offset;           // Flags and Fragment Offset
	alt_u8 ttl;						// Time-to-Live
	alt_u8 protocol;				// Type of protocol encapsulation
	alt_u16 checksum;				// Checksum of IP header
	alt_u8 ip_src[4];				// IP-address source
	alt_u8 ip_dest[4];				// IP-address destination
};

// Structure of ICMP packet - encapsulation in IP-packet
struct icmp_packet
{
	alt_u8 type;					// Type (Request = 8, Reply = 0)
	alt_u8 code;					// Code
	alt_u16 checksum;				// Checksum
	alt_u16 id;						// Identifier - uniq number
	alt_u16 sequence;				// Sequence number for Identificator
    alt_u8 *data;					// Random data, timestamp
};

// Structure of UDP header - encapsulation in IP-packet
struct udp_hdr
{
	alt_u16 port_src;				// Port source
	alt_u16 port_dest;				// Port destination
	alt_u16 len;					// Total Length UDP (header with Data)
	alt_u16 checksum;				// IP source + destination, 1 bytes = 0x00, protocol, Length UDP + UDP header with Data
};

/******************* Declare Function *******************/
void tse_init(void);
alt_u8 open_sgdma(void);
void timer_init(alt_u32 timer_period);

void timer_irq_handler(void *context);
void sgdma_rx_irq_handler(void *context);

void create_eth(struct eth_hdr* eth);

void create_arp(struct arp_packet *arp, alt_u16 operation);
void create_ip(struct ip_hdr* ip, alt_u8 protocol, alt_u32 data_len);

void create_icmp(struct icmp_packet *icmp, alt_u16 id, alt_u16 seq, alt_u8 *data);
void create_udp(struct udp_hdr* udp, alt_u16 dest_port, alt_u32 data_len);

alt_u16 calculate_checksum(alt_u8* data, alt_u32 length);

/******************* Declare Variables *******************/
alt_sgdma_dev *sgdma_tx_dev;
alt_sgdma_dev *sgdma_rx_dev;

alt_sgdma_descriptor tx_descriptor_header;
alt_sgdma_descriptor tx_descriptor_data;
alt_sgdma_descriptor tx_descriptor_end;

alt_sgdma_descriptor rx_descriptor;
alt_sgdma_descriptor rx_descriptor_end;

// Ethernet header - start frame
struct eth_hdr *eth = (struct eth_hdr *)HEADER_RAM_BASE;
// ARP packet
struct arp_packet *arp = (struct arp_packet*)(HEADER_RAM_BASE + sizeof(struct eth_hdr));
// IP header
struct ip_hdr *ip = (struct ip_hdr *)(HEADER_RAM_BASE + sizeof(struct eth_hdr));
// ICMP packet
struct icmp_packet *icmp = (struct icmp_packet *)(HEADER_RAM_BASE + sizeof(struct eth_hdr) + sizeof(struct ip_hdr));
// UDP header
struct udp_hdr *udp = (struct udp_hdr *)(HEADER_RAM_BASE + sizeof(struct eth_hdr) + sizeof(struct ip_hdr));


// Pointer to address start of TSE in RAM
volatile int *tse = (int *)TSE_BASE;

// Flag to set MAC-address of PC
alt_u8 fl_proto = 0;

/****************** Main block ******************/
int main(void)
{
	create_eth(eth);
	create_arp(arp, 0x0001);

	tse_init();

	alt_u8 sdgma_status = open_sgdma();
	if (sdgma_status == 1 || sdgma_status == 2) return(0);

	timer_init(125000000);

	while (1);

	return 0;
}


// Initialization of Triple-Speed Ethernet
void tse_init(void)
{
	// Specify the addresses of the PHY devices to be accessed through MDIO interface
	*(tse + 0x0F) = 0x00;

	// Disable read and write transfers and wait
	IOWR(tse, 0x02, 0x00800220);
	while ( IORD(tse, 0x02) !=  0x00800220 );

	// MAC FIFO Configuration
	IOWR(tse, 0x09, TSE_RECEIVE_FIFO_DEPTH-16);
	IOWR(tse, 0x0E, 3);
	IOWR(tse, 0x0D, 8);
	IOWR(tse, 0x07, TSE_RECEIVE_FIFO_DEPTH-16);
	IOWR(tse, 0x0C, 8);
	IOWR(tse, 0x0B, 8);
	IOWR(tse, 0x0A, 0);
	IOWR(tse, 0x08, 0);

	// Initialize the MAC address
	IOWR(tse, 0x03, 0xEFBEADDE);
	IOWR(tse, 0x04, 0x0000FECA);

	// MAC function configuration
	IOWR(tse, 0x05, 1280 + 54);
	IOWR(tse, 0x17, 12);
	IOWR(tse, 0x06, 0xFFFF);
	IOWR(tse, 0x02, 0x00800220);
	while (IORD(tse, 0x02 ) != 0x00800220);

	// Software reset the PHY chip and wait
	IOWR(tse, 0x02, (IORD(tse, 0x02) | 0x2000));
	while ((IORD(tse, 0x02) & 0x2000) != 0);
	*(tse + 0x02 ) = *(tse + 0x02 ) | 0x0080023B;
	while ( *(tse + 0x02 ) != ( *(tse + 0x02) | 0x0080023B ) );

	IOWR(tse, 0x3a, 0x0000);
}

// Initialization of timer
void timer_init(alt_u32 timer_period)
{
	// Disable timer before configuration
	IOWR_ALTERA_AVALON_TIMER_CONTROL(TIMER_0_BASE, 0);

	IOWR_ALTERA_AVALON_TIMER_PERIODL(TIMER_0_BASE, (timer_period & 0xFFFF));
	IOWR_ALTERA_AVALON_TIMER_PERIODH(TIMER_0_BASE, (timer_period >> 16) & 0xFFFF);

	// Register of interrupt
	alt_ic_isr_register(TIMER_0_IRQ_INTERRUPT_CONTROLLER_ID, TIMER_0_IRQ, timer_irq_handler, 0, 0);

	// Enable timer and resolve interrupt
	IOWR_ALTERA_AVALON_TIMER_CONTROL(TIMER_0_BASE, ALTERA_AVALON_TIMER_CONTROL_ITO_MSK |
													ALTERA_AVALON_TIMER_CONTROL_CONT_MSK |
													ALTERA_AVALON_TIMER_CONTROL_START_MSK);
}

// Handler of timer interrupt
void timer_irq_handler(void *context)
{
    // Clear flag of interrupt
    IOWR_ALTERA_AVALON_TIMER_STATUS(TIMER_0_BASE, 0);

    if (fl_proto == 1)
    {
    	alt_dcache_flush_all();
		alt_avalon_sgdma_construct_mem_to_stream_desc(&tx_descriptor_header, &tx_descriptor_data, (alt_u32 *)HEADER_RAM_BASE, 54, 0, 1, 0, 0);
		alt_avalon_sgdma_construct_mem_to_stream_desc(&tx_descriptor_data, &tx_descriptor_end, TX_DMA_M_READ_TX_BUFF_RAM_BASE, 1280, 0, 0, 1, 0);

		alt_avalon_sgdma_do_async_transfer(sgdma_tx_dev, &tx_descriptor_header);
		while (alt_avalon_sgdma_check_descriptor_status(&tx_descriptor_data) != 0);
    }
    else
    {
    	alt_dcache_flush_all();
		alt_avalon_sgdma_construct_mem_to_stream_desc(&tx_descriptor_header, &tx_descriptor_data, (alt_u32 *)HEADER_RAM_BASE, 42, 0, 1, 1, 0);
		alt_avalon_sgdma_do_async_transfer(sgdma_tx_dev, &tx_descriptor_header);
		while (alt_avalon_sgdma_check_descriptor_status(&tx_descriptor_header) != 0);
    }
}

// Open the SGDMA transmit/receive device
alt_u8 open_sgdma(void)
{
	// Transmit device
	sgdma_tx_dev = alt_avalon_sgdma_open ("/dev/tx_dma");
	if (sgdma_tx_dev == NULL) return(1);

	// Transmit device
	sgdma_rx_dev = alt_avalon_sgdma_open ("/dev/rx_dma");
	if (sgdma_rx_dev == NULL) return(2);

	// Register receive interrupt handler and allocate memory area
	alt_avalon_sgdma_register_callback(sgdma_rx_dev, (alt_avalon_sgdma_callback)sgdma_rx_irq_handler, 0x00000014, NULL);
	alt_avalon_sgdma_construct_stream_to_mem_desc(&rx_descriptor, &rx_descriptor_end, (alt_u32 *)(HEADER_RAM_BASE + 100), 0, 0);
	alt_avalon_sgdma_do_async_transfer(sgdma_rx_dev, &rx_descriptor);

	return(0);
}

// Handler of SGDMA Receive interrupt
void sgdma_rx_irq_handler(void *context)
{
	while (alt_avalon_sgdma_check_descriptor_status(&rx_descriptor) != 0);

	alt_u8 *frame_pc = (alt_u8 *)(HEADER_RAM_BASE + 100);
	if ((memcmp(frame_pc + 12, "\x08\x06", 2) == 0) && frame_pc[21] == 0x02)
	{
		fl_proto = 0;  // Заглушка

		memcpy(eth->mac_dest, (frame_pc + 22), 6);

//		create_ip(ip, 0x11, 1280 + sizeof(struct udp_hdr));				// 0x11 - protocol for UDP
//		create_udp(udp, 5004, 1280);
//
		// Copy MAC-address and IP-address of PC to frame
//		memcpy(ip->ip_dest, (frame_pc + 28), 4);
//
//		// Frequency of send UDP-packet (3900 - 32000 frame per second)
//		timer_init(3890);
	}
	// && (memcmp(frame_pc + 30, ip->ip_src, 4) == 0) && frame_pc[23] == 0x1 && frame_pc[34] == 0x8
	if ((memcmp(frame_pc, "\xDE\xAD\xBE\xEF\xCA\xFE", 6) == 0))
	{
		alt_u16 length_descriptor = frame_pc[17] << 8 | frame_pc[16];
		length_descriptor += 14;

		alt_u16 seq = 0;
		alt_u16 id = 0;
		alt_u8 *pointer_to_data = frame_pc + 42;

		seq = frame_pc[40] << 8 | frame_pc[41];
		id = frame_pc[38] << 8 | frame_pc[39];

		create_icmp(icmp, id, seq, pointer_to_data);

		create_ip(ip, 0x1, sizeof(icmp));

		alt_dcache_flush_all();
		alt_avalon_sgdma_construct_mem_to_stream_desc(&tx_descriptor_header, &tx_descriptor_data, (alt_u32 *)HEADER_RAM_BASE, length_descriptor, 0, 1, 1, 0);

		alt_avalon_sgdma_do_async_transfer(sgdma_tx_dev, &tx_descriptor_header);
		while (alt_avalon_sgdma_check_descriptor_status(&tx_descriptor_header) != 0);

//		timer_init(0);
	}

	alt_dcache_flush_all();
	alt_avalon_sgdma_construct_stream_to_mem_desc(&rx_descriptor, &rx_descriptor_end, (alt_u32 *)(HEADER_RAM_BASE + 100), 0, 0);
	alt_avalon_sgdma_do_async_transfer(sgdma_rx_dev, &rx_descriptor);

	memset(frame_pc, 0, 100);
}

// Create ETH header (struct eth, type - encapsulation protocol)
void create_eth(struct eth_hdr *eth)
{
	memcpy(eth->mac_dest, "\xFF\xFF\xFF\xFF\xFF\xFF", 6);
	memcpy(eth->mac_src, "\xDE\xAD\xBE\xEF\xCA\xFE", 6);
}

// Create ARP packet (struct arp, operation - request/reply)
void create_arp(struct arp_packet *arp, alt_u16 operation)
{
	arp->eth_type = __builtin_bswap16(0x0806);
	arp->hw_type = __builtin_bswap16(0x0001);
	arp->proto_type = __builtin_bswap16(0x0800);
	arp->hw_len = 6;
	arp->proto_len = 4;

	// Operation (ARP-request = 1, ARP-reply = 2)
	arp->operation = __builtin_bswap16(operation);

	memcpy(arp->sender_mac, "\xDE\xAD\xBE\xEF\xCA\xFE", 6);
	memcpy(arp->sender_ip, "\xC0\xA8\x01\x02", 4);
	memset(arp->target_mac, 0, 6);
	memcpy(arp->target_ip, "\xC0\xA8\x01\x05", 4);
}

// Create IP header (struct ip, protocol - encapsulation protocol, data_len - length of data after IP header)
void create_ip(struct ip_hdr *ip, alt_u8 protocol, alt_u32 data_len)
{
	ip->eth_type = __builtin_bswap16(0x0800);
	ip->ver_ihl = 0x45;
	ip->tos = 0x00;
	ip->len = __builtin_bswap16(sizeof(struct ip_hdr) + data_len);
	ip->id = 0;
	ip->flags_offset = 0;
	ip->ttl = 0x40;
	ip->protocol = protocol;
	ip->checksum = 0;
	memcpy(ip->ip_src, "\xC0\xA8\x01\x02", 4);
	memcpy(ip->ip_dest, "\xC0\xA8\x01\x05", 4);
}

// Create ICMP packet
void create_icmp(struct icmp_packet *icmp, alt_u16 id, alt_u16 seq, alt_u8 *data)
{
	icmp->type = 0;
	icmp->code = 0;
	icmp->checksum = 0;
	icmp->id = id;
	icmp->sequence = seq;
	icmp->data = data;
	icmp->checksum = calculate_checksum((alt_u8 *)icmp, sizeof(icmp));
}

// Create UDP header
void create_udp(struct udp_hdr *udp, alt_u16 dest_port, alt_u32 data_len)
{
	udp->port_src = __builtin_bswap16(5004);
	udp->port_dest = __builtin_bswap16(dest_port);
	udp->len = __builtin_bswap16(sizeof(struct udp_hdr) + data_len);
	udp->checksum = 0;
}

// Calculate checksum for IP/ICMP/UDP/TCP
alt_u16 calculate_checksum(alt_u8* data, alt_u32 length)
{
    alt_u16* buffer = (alt_u16 *)data;
    alt_u16 temp = 0;

    while (length > 1)
    {
        temp += *buffer++;
        length -= 2;
    }

    if (length == 1) temp += *(alt_u8 *)buffer << 8;
    while (temp >> 16) temp = (temp & 0xFFFF) + (temp >> 16);
    return ~((temp >> 8) | (temp << 8));
}
