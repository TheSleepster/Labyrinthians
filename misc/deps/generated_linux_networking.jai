//
// This file was auto-generated using the following command:
//
// jai modules/Socket/generate.jai - -x64
//



PF_UNSPEC :: 0;
PF_LOCAL :: 1;
PF_UNIX :: PF_LOCAL;
PF_FILE :: PF_LOCAL;
PF_INET :: 2;
PF_AX25 :: 3;
PF_IPX :: 4;
PF_APPLETALK :: 5;
PF_NETROM :: 6;
PF_BRIDGE :: 7;
PF_ATMPVC :: 8;
PF_X25 :: 9;
PF_INET6 :: 10;
PF_ROSE :: 11;
PF_DECnet :: 12;
PF_NETBEUI :: 13;
PF_SECURITY :: 14;
PF_KEY :: 15;
PF_NETLINK :: 16;
PF_ROUTE :: PF_NETLINK;
PF_PACKET :: 17;
PF_ASH :: 18;
PF_ECONET :: 19;
PF_ATMSVC :: 20;
PF_RDS :: 21;
PF_SNA :: 22;
PF_IRDA :: 23;
PF_PPPOX :: 24;
PF_WANPIPE :: 25;
PF_LLC :: 26;
PF_IB :: 27;
PF_MPLS :: 28;
PF_CAN :: 29;
PF_TIPC :: 30;
PF_BLUETOOTH :: 31;
PF_IUCV :: 32;
PF_RXRPC :: 33;
PF_ISDN :: 34;
PF_PHONET :: 35;
PF_IEEE802154 :: 36;
PF_CAIF :: 37;
PF_ALG :: 38;
PF_NFC :: 39;
PF_VSOCK :: 40;
PF_KCM :: 41;
PF_QIPCRTR :: 42;
PF_SMC :: 43;
PF_MAX :: 44;

AF_UNSPEC :: PF_UNSPEC;
AF_LOCAL :: PF_LOCAL;
AF_UNIX :: PF_UNIX;
AF_FILE :: PF_FILE;
AF_INET :: PF_INET;
AF_AX25 :: PF_AX25;
AF_IPX :: PF_IPX;
AF_APPLETALK :: PF_APPLETALK;
AF_NETROM :: PF_NETROM;
AF_BRIDGE :: PF_BRIDGE;
AF_ATMPVC :: PF_ATMPVC;
AF_X25 :: PF_X25;
AF_INET6 :: PF_INET6;
AF_ROSE :: PF_ROSE;
AF_DECnet :: PF_DECnet;
AF_NETBEUI :: PF_NETBEUI;
AF_SECURITY :: PF_SECURITY;
AF_KEY :: PF_KEY;
AF_NETLINK :: PF_NETLINK;
AF_ROUTE :: PF_ROUTE;
AF_PACKET :: PF_PACKET;
AF_ASH :: PF_ASH;
AF_ECONET :: PF_ECONET;
AF_ATMSVC :: PF_ATMSVC;
AF_RDS :: PF_RDS;
AF_SNA :: PF_SNA;
AF_IRDA :: PF_IRDA;
AF_PPPOX :: PF_PPPOX;
AF_WANPIPE :: PF_WANPIPE;
AF_LLC :: PF_LLC;
AF_IB :: PF_IB;
AF_MPLS :: PF_MPLS;
AF_CAN :: PF_CAN;
AF_TIPC :: PF_TIPC;
AF_BLUETOOTH :: PF_BLUETOOTH;
AF_IUCV :: PF_IUCV;
AF_RXRPC :: PF_RXRPC;
AF_ISDN :: PF_ISDN;
AF_PHONET :: PF_PHONET;
AF_IEEE802154 :: PF_IEEE802154;
AF_CAIF :: PF_CAIF;
AF_ALG :: PF_ALG;
AF_NFC :: PF_NFC;
AF_VSOCK :: PF_VSOCK;
AF_KCM :: PF_KCM;
AF_QIPCRTR :: PF_QIPCRTR;
AF_SMC :: PF_SMC;
AF_MAX :: PF_MAX;

SOL_RAW :: 255;
SOL_DECNET :: 261;
SOL_X25 :: 262;
SOL_PACKET :: 263;
SOL_ATM :: 264;
SOL_AAL :: 265;
SOL_IRDA :: 266;
SOL_NETBEUI :: 267;
SOL_LLC :: 268;
SOL_DCCP :: 269;
SOL_NETLINK :: 270;
SOL_TIPC :: 271;
SOL_RXRPC :: 272;
SOL_PPPOL2TP :: 273;
SOL_BLUETOOTH :: 274;
SOL_PNPIPE :: 275;
SOL_RDS :: 276;
SOL_IUCV :: 277;
SOL_CAIF :: 278;
SOL_ALG :: 279;
SOL_NFC :: 280;
SOL_KCM :: 281;
SOL_TLS :: 282;

SOMAXCONN :: 128;

SOL_SOCKET :: 1;

SO_DEBUG :: 1;
SO_REUSEADDR :: 2;
SO_TYPE :: 3;
SO_ERROR :: 4;
SO_DONTROUTE :: 5;
SO_BROADCAST :: 6;
SO_SNDBUF :: 7;
SO_RCVBUF :: 8;
SO_SNDBUFFORCE :: 32;
SO_RCVBUFFORCE :: 33;
SO_KEEPALIVE :: 9;
SO_OOBINLINE :: 10;
SO_NO_CHECK :: 11;
SO_PRIORITY :: 12;
SO_LINGER :: 13;
SO_BSDCOMPAT :: 14;
SO_REUSEPORT :: 15;

SO_PASSCRED :: 16;
SO_PEERCRED :: 17;
SO_RCVLOWAT :: 18;
SO_SNDLOWAT :: 19;
SO_RCVTIMEO :: 20;
SO_SNDTIMEO :: 21;

SO_SECURITY_AUTHENTICATION :: 22;
SO_SECURITY_ENCRYPTION_TRANSPORT :: 23;
SO_SECURITY_ENCRYPTION_NETWORK :: 24;

SO_BINDTODEVICE :: 25;

SO_ATTACH_FILTER :: 26;
SO_DETACH_FILTER :: 27;
SO_GET_FILTER :: SO_ATTACH_FILTER;

SO_PEERNAME :: 28;
SO_TIMESTAMP :: 29;

SO_ACCEPTCONN :: 30;

SO_PEERSEC :: 31;
SO_PASSSEC :: 34;
SO_TIMESTAMPNS :: 35;

SO_MARK :: 36;

SO_TIMESTAMPING :: 37;

SO_PROTOCOL :: 38;
SO_DOMAIN :: 39;

SO_RXQ_OVFL :: 40;

SO_WIFI_STATUS :: 41;

SO_PEEK_OFF :: 42;

SO_NOFCS :: 43;

SO_LOCK_FILTER :: 44;

SO_SELECT_ERR_QUEUE :: 45;

SO_BUSY_POLL :: 46;

SO_MAX_PACING_RATE :: 47;

SO_BPF_EXTENSIONS :: 48;

SO_INCOMING_CPU :: 49;

SO_ATTACH_BPF :: 50;
SO_DETACH_BPF :: SO_DETACH_FILTER;

SO_ATTACH_REUSEPORT_CBPF :: 51;
SO_ATTACH_REUSEPORT_EBPF :: 52;

SO_CNX_ADVICE :: 53;

SO_MEMINFO :: 55;

SO_INCOMING_NAPI_ID :: 56;

SO_COOKIE :: 57;

SO_PEERGROUPS :: 59;

SO_ZEROCOPY :: 60;

__USE_KERNEL_IPV6_DEFS :: 0;

IP_OPTIONS :: 4;
IP_HDRINCL :: 3;
IP_TOS :: 1;
IP_TTL :: 2;
IP_RECVOPTS :: 6;

IP_RECVRETOPTS :: IP_RETOPTS;
IP_RETOPTS :: 7;
IP_MULTICAST_IF :: 32;
IP_MULTICAST_TTL :: 33;
IP_MULTICAST_LOOP :: 34;
IP_ADD_MEMBERSHIP :: 35;
IP_DROP_MEMBERSHIP :: 36;
IP_UNBLOCK_SOURCE :: 37;
IP_BLOCK_SOURCE :: 38;
IP_ADD_SOURCE_MEMBERSHIP :: 39;
IP_DROP_SOURCE_MEMBERSHIP :: 40;
IP_MSFILTER :: 41;

MCAST_JOIN_GROUP :: 42;
MCAST_BLOCK_SOURCE :: 43;
MCAST_UNBLOCK_SOURCE :: 44;
MCAST_LEAVE_GROUP :: 45;
MCAST_JOIN_SOURCE_GROUP :: 46;
MCAST_LEAVE_SOURCE_GROUP :: 47;
MCAST_MSFILTER :: 48;
IP_MULTICAST_ALL :: 49;
IP_UNICAST_IF :: 50;

MCAST_EXCLUDE :: 0;
MCAST_INCLUDE :: 1;

IP_ROUTER_ALERT :: 5;
IP_PKTINFO :: 8;
IP_PKTOPTIONS :: 9;
IP_PMTUDISC :: 10;
IP_MTU_DISCOVER :: 10;
IP_RECVERR :: 11;
IP_RECVTTL :: 12;
IP_RECVTOS :: 13;
IP_MTU :: 14;
IP_FREEBIND :: 15;
IP_IPSEC_POLICY :: 16;
IP_XFRM_POLICY :: 17;
IP_PASSSEC :: 18;
IP_TRANSPARENT :: 19;

IP_ORIGDSTADDR :: 20;
IP_RECVORIGDSTADDR :: IP_ORIGDSTADDR;

IP_MINTTL :: 21;
IP_NODEFRAG :: 22;
IP_CHECKSUM :: 23;
IP_BIND_ADDRESS_NO_PORT :: 24;
IP_RECVFRAGSIZE :: 25;

IP_PMTUDISC_DONT :: 0;
IP_PMTUDISC_WANT :: 1;
IP_PMTUDISC_DO :: 2;
IP_PMTUDISC_PROBE :: 3;

IP_PMTUDISC_INTERFACE :: 4;

IP_PMTUDISC_OMIT :: 5;

SOL_IP :: 0;

IP_DEFAULT_MULTICAST_TTL :: 1;
IP_DEFAULT_MULTICAST_LOOP :: 1;
IP_MAX_MEMBERSHIPS :: 20;

IPV6_ADDRFORM :: 1;
IPV6_2292PKTINFO :: 2;
IPV6_2292HOPOPTS :: 3;
IPV6_2292DSTOPTS :: 4;
IPV6_2292RTHDR :: 5;
IPV6_2292PKTOPTIONS :: 6;
IPV6_CHECKSUM :: 7;
IPV6_2292HOPLIMIT :: 8;

IPV6_NEXTHOP :: 9;
IPV6_AUTHHDR :: 10;
IPV6_UNICAST_HOPS :: 16;
IPV6_MULTICAST_IF :: 17;
IPV6_MULTICAST_HOPS :: 18;
IPV6_MULTICAST_LOOP :: 19;
IPV6_JOIN_GROUP :: 20;
IPV6_LEAVE_GROUP :: 21;
IPV6_ROUTER_ALERT :: 22;
IPV6_MTU_DISCOVER :: 23;
IPV6_MTU :: 24;
IPV6_RECVERR :: 25;
IPV6_V6ONLY :: 26;
IPV6_JOIN_ANYCAST :: 27;
IPV6_LEAVE_ANYCAST :: 28;
IPV6_IPSEC_POLICY :: 34;
IPV6_XFRM_POLICY :: 35;
IPV6_HDRINCL :: 36;

IPV6_RECVPKTINFO :: 49;
IPV6_PKTINFO :: 50;
IPV6_RECVHOPLIMIT :: 51;
IPV6_HOPLIMIT :: 52;
IPV6_RECVHOPOPTS :: 53;
IPV6_HOPOPTS :: 54;
IPV6_RTHDRDSTOPTS :: 55;
IPV6_RECVRTHDR :: 56;
IPV6_RTHDR :: 57;
IPV6_RECVDSTOPTS :: 58;
IPV6_DSTOPTS :: 59;
IPV6_RECVPATHMTU :: 60;
IPV6_PATHMTU :: 61;
IPV6_DONTFRAG :: 62;

IPV6_RECVTCLASS :: 66;
IPV6_TCLASS :: 67;

IPV6_AUTOFLOWLABEL :: 70;

IPV6_ADDR_PREFERENCES :: 72;

IPV6_MINHOPCOUNT :: 73;

IPV6_ORIGDSTADDR :: 74;
IPV6_RECVORIGDSTADDR :: IPV6_ORIGDSTADDR;
IPV6_TRANSPARENT :: 75;
IPV6_UNICAST_IF :: 76;
IPV6_RECVFRAGSIZE :: 77;

IPV6_ADD_MEMBERSHIP :: IPV6_JOIN_GROUP;
IPV6_DROP_MEMBERSHIP :: IPV6_LEAVE_GROUP;

IPV6_RXHOPOPTS :: IPV6_HOPOPTS;
IPV6_RXDSTOPTS :: IPV6_DSTOPTS;

IPV6_PMTUDISC_DONT :: 0;
IPV6_PMTUDISC_WANT :: 1;
IPV6_PMTUDISC_DO :: 2;
IPV6_PMTUDISC_PROBE :: 3;
IPV6_PMTUDISC_INTERFACE :: 4;
IPV6_PMTUDISC_OMIT :: 5;

SOL_IPV6 :: 41;
SOL_ICMPV6 :: 58;

IPV6_RTHDR_LOOSE :: 0;
IPV6_RTHDR_STRICT :: 1;

IPV6_RTHDR_TYPE_0 :: 0;

IN_CLASSA_NET :: 0xff000000;
IN_CLASSA_NSHIFT :: 24;
IN_CLASSA_HOST :: 0xffffffff & ~IN_CLASSA_NET;
IN_CLASSA_MAX :: 128;

IN_CLASSB_NET :: 0xffff0000;
IN_CLASSB_NSHIFT :: 16;
IN_CLASSB_HOST :: 0xffffffff & ~IN_CLASSB_NET;
IN_CLASSB_MAX :: 65536;

IN_CLASSC_NET :: 0xffffff00;
IN_CLASSC_NSHIFT :: 8;
IN_CLASSC_HOST :: 0xffffffff & ~IN_CLASSC_NET;

INADDR_ANY :: cast(in_addr_t) 0x00000000;

INADDR_BROADCAST :: cast(in_addr_t) 0xffffffff;

INADDR_NONE :: cast(in_addr_t) 0xffffffff;

IN_LOOPBACKNET :: 127;

INADDR_LOOPBACK :: cast(in_addr_t) 0x7f000001;

INADDR_UNSPEC_GROUP :: cast(in_addr_t) 0xe0000000;
INADDR_ALLHOSTS_GROUP :: cast(in_addr_t) 0xe0000001;
INADDR_ALLRTRS_GROUP :: cast(in_addr_t) 0xe0000002;
INADDR_MAX_LOCAL_GROUP :: cast(in_addr_t) 0xe00000ff;

INET_ADDRSTRLEN :: 16;
INET6_ADDRSTRLEN :: 46;

TCP_NODELAY :: 1;
TCP_MAXSEG :: 2;
TCP_CORK :: 3;
TCP_KEEPIDLE :: 4;
TCP_KEEPINTVL :: 5;
TCP_KEEPCNT :: 6;
TCP_SYNCNT :: 7;
TCP_LINGER2 :: 8;
TCP_DEFER_ACCEPT :: 9;
TCP_WINDOW_CLAMP :: 10;
TCP_INFO :: 11;
TCP_QUICKACK :: 12;
TCP_CONGESTION :: 13;
TCP_MD5SIG :: 14;
TCP_COOKIE_TRANSACTIONS :: 15;
TCP_THIN_LINEAR_TIMEOUTS :: 16;
TCP_THIN_DUPACK :: 17;
TCP_USER_TIMEOUT :: 18;
TCP_REPAIR :: 19;
TCP_REPAIR_QUEUE :: 20;
TCP_QUEUE_SEQ :: 21;
TCP_REPAIR_OPTIONS :: 22;
TCP_FASTOPEN :: 23;
TCP_TIMESTAMP :: 24;
TCP_NOTSENT_LOWAT :: 25;

TCP_CC_INFO :: 26;

TCP_SAVE_SYN :: 27;

TCP_SAVED_SYN :: 28;

TCP_REPAIR_WINDOW :: 29;
TCP_FASTOPEN_CONNECT :: 30;
TCP_ULP :: 31;
TCP_MD5SIG_EXT :: 32;

TH_FIN :: 0x01;
TH_SYN :: 0x02;
TH_RST :: 0x04;
TH_PUSH :: 0x08;
TH_ACK :: 0x10;
TH_URG :: 0x20;

TCPOPT_EOL :: 0;
TCPOPT_NOP :: 1;
TCPOPT_MAXSEG :: 2;
TCPOLEN_MAXSEG :: 4;
TCPOPT_WINDOW :: 3;
TCPOLEN_WINDOW :: 3;
TCPOPT_SACK_PERMITTED :: 4;
TCPOLEN_SACK_PERMITTED :: 2;
TCPOPT_SACK :: 5;
TCPOPT_TIMESTAMP :: 8;
TCPOLEN_TIMESTAMP :: 10;
TCPOLEN_TSTAMP_APPA :: TCPOLEN_TIMESTAMP+2;

TCPOPT_TSTAMP_HDR :: TCPOPT_NOP<<24|TCPOPT_NOP<<16|TCPOPT_TIMESTAMP<<8|TCPOLEN_TIMESTAMP;

TCP_MSS :: 512;

TCP_MAXWIN :: 65535;

TCP_MAX_WINSHIFT :: 14;

SOL_TCP :: 6;

TCPI_OPT_TIMESTAMPS :: 1;
TCPI_OPT_SACK :: 2;
TCPI_OPT_WSCALE :: 4;
TCPI_OPT_ECN :: 8;
TCPI_OPT_ECN_SEEN :: 16;
TCPI_OPT_SYN_DATA :: 32;

TCP_MD5SIG_MAXKEYLEN :: 80;

TCP_MD5SIG_FLAG_PREFIX :: 1;

TCP_COOKIE_MIN :: 8;
TCP_COOKIE_MAX :: 16;
TCP_COOKIE_PAIR_SIZE :: 2*TCP_COOKIE_MAX;

TCP_COOKIE_IN_ALWAYS :: 1 << 0;
TCP_COOKIE_OUT_NEVER :: 1 << 1;

TCP_S_DATA_IN :: 1 << 2;
TCP_S_DATA_OUT :: 1 << 3;

TCP_MSS_DEFAULT :: 536;
TCP_MSS_DESIRED :: 1220;

_PATH_HEQUIV :: "/etc/hosts.equiv";
_PATH_HOSTS :: "/etc/hosts";
_PATH_NETWORKS :: "/etc/networks";
_PATH_NSSWITCH_CONF :: "/etc/nsswitch.conf";
_PATH_PROTOCOLS :: "/etc/protocols";
_PATH_SERVICES :: "/etc/services";

HOST_NOT_FOUND :: 1;
TRY_AGAIN :: 2;

NO_RECOVERY :: 3;

NO_DATA :: 4;

NETDB_INTERNAL :: -1;
NETDB_SUCCESS :: 0;
NO_ADDRESS :: NO_DATA;

IPPORT_RESERVED :: 1024;

GAI_WAIT :: 0;
GAI_NOWAIT :: 1;

AI :: enum_flags u32 {
    PASSIVE                  :: 0x0001;
    CANONNAME                :: 0x0002;
    NUMERICHOST              :: 0x0004;
    V4MAPPED                 :: 0x0008;
    ALL                      :: 0x0010;
    ADDRCONFIG               :: 0x0020;
    IDN                      :: 0x0040;
    CANONIDN                 :: 0x0080;
    IDN_ALLOW_UNASSIGNED     :: 0x0100;
    IDN_USE_STD3_ASCII_RULES :: 0x0200;
    NUMERICSERV              :: 0x0400;

    AI_PASSIVE                  :: PASSIVE;
    AI_CANONNAME                :: CANONNAME;
    AI_NUMERICHOST              :: NUMERICHOST;
    AI_V4MAPPED                 :: V4MAPPED;
    AI_ALL                      :: ALL;
    AI_ADDRCONFIG               :: ADDRCONFIG;
    AI_IDN                      :: IDN;
    AI_CANONIDN                 :: CANONIDN;
    AI_IDN_ALLOW_UNASSIGNED     :: IDN_ALLOW_UNASSIGNED;
    AI_IDN_USE_STD3_ASCII_RULES :: IDN_USE_STD3_ASCII_RULES;
    AI_NUMERICSERV              :: NUMERICSERV;
}

EAI_BADFLAGS :: -1;
EAI_NONAME :: -2;
EAI_AGAIN :: -3;
EAI_FAIL :: -4;
EAI_FAMILY :: -6;
EAI_SOCKTYPE :: -7;
EAI_SERVICE :: -8;
EAI_MEMORY :: -10;
EAI_SYSTEM :: -11;
EAI_OVERFLOW :: -12;

EAI_NODATA :: -5;
EAI_ADDRFAMILY :: -9;
EAI_INPROGRESS :: -100;
EAI_CANCELED :: -101;
EAI_NOTCANCELED :: -102;
EAI_ALLDONE :: -103;
EAI_INTR :: -104;
EAI_IDN_ENCODE :: -105;

NI_MAXHOST :: 1025;
NI_MAXSERV :: 32;

NI_NUMERICHOST :: 1;
NI_NUMERICSERV :: 2;
NI_NOFQDN :: 4;
NI_NAMEREQD :: 8;
NI_DGRAM :: 16;

NI_IDN :: 32;
NI_IDN_ALLOW_UNASSIGNED :: 64;

NI_IDN_USE_STD3_ASCII_RULES :: 128;

IF_NAMESIZE :: 16;

IFHWADDRLEN :: 6;
IFNAMSIZ :: IF_NAMESIZE;

__fd_mask :: s64;

fd_set :: struct {
    fds_bits: [16] __fd_mask;
}

fd_mask :: __fd_mask;

select :: (__nfds: s32, __readfds: *fd_set, __writefds: *fd_set, __exceptfds: *fd_set, __timeout: *timeval) -> s32 #foreign libc;

pselect :: (__nfds: s32, __readfds: *fd_set, __writefds: *fd_set, __exceptfds: *fd_set, __timeout: *timespec, __sigmask: *__sigset_t) -> s32 #foreign libc;

socklen_t :: u32;

SOCK :: enum u32 {
    STREAM    :: 1;
    DGRAM     :: 2;
    RAW       :: 3;
    RDM       :: 4;
    SEQPACKET :: 5;
    DCCP      :: 6;
    PACKET    :: 10;
    CLOEXEC   :: 524288;
    NONBLOCK  :: 2048;

    SOCK_STREAM    :: STREAM;
    SOCK_DGRAM     :: DGRAM;
    SOCK_RAW       :: RAW;
    SOCK_RDM       :: RDM;
    SOCK_SEQPACKET :: SEQPACKET;
    SOCK_DCCP      :: DCCP;
    SOCK_PACKET    :: PACKET;
    SOCK_CLOEXEC   :: CLOEXEC;
    SOCK_NONBLOCK  :: NONBLOCK;
}

sa_family_t :: u16;

sockaddr :: struct {
    sa_family: sa_family_t;
    sa_data:   [14] u8;
}

sockaddr_storage :: struct {
    ss_family:    sa_family_t;
    __ss_padding: [118] u8;
    __ss_align:   u64;
}

MSG :: enum_flags s32 {
    OOB          :: 0x1;

    PEEK         :: 0x2;

    DONTROUTE    :: 0x4;

    TRYHARD      :: 0x4;

    CTRUNC       :: 0x8;

    PROXY        :: 0x10;

    TRUNC        :: 0x20;

    DONTWAIT     :: 0x40;

    EOR          :: 0x80;

    WAITALL      :: 0x100;

    FIN          :: 0x200;

    SYN          :: 0x400;

    CONFIRM      :: 0x800;

    RST          :: 0x1000;

    ERRQUEUE     :: 0x2000;

    NOSIGNAL     :: 0x4000;

    MORE         :: 0x8000;

    WAITFORONE   :: 0x10000;

    BATCH        :: 0x40000;

    ZEROCOPY     :: 0x4000000;

    FASTOPEN     :: 0x20000000;

    CMSG_CLOEXEC :: 0x40000000;

    MSG_OOB          :: OOB;

    MSG_PEEK         :: PEEK;

    MSG_DONTROUTE    :: DONTROUTE;

    MSG_TRYHARD      :: TRYHARD;

    MSG_CTRUNC       :: CTRUNC;

    MSG_PROXY        :: PROXY;

    MSG_TRUNC        :: TRUNC;

    MSG_DONTWAIT     :: DONTWAIT;

    MSG_EOR          :: EOR;

    MSG_WAITALL      :: WAITALL;

    MSG_FIN          :: FIN;

    MSG_SYN          :: SYN;

    MSG_CONFIRM      :: CONFIRM;

    MSG_RST          :: RST;

    MSG_ERRQUEUE     :: ERRQUEUE;

    MSG_NOSIGNAL     :: NOSIGNAL;

    MSG_MORE         :: MORE;

    MSG_WAITFORONE   :: WAITFORONE;

    MSG_BATCH        :: BATCH;

    MSG_ZEROCOPY     :: ZEROCOPY;

    MSG_FASTOPEN     :: FASTOPEN;

    MSG_CMSG_CLOEXEC :: CMSG_CLOEXEC;
}

msghdr :: struct {
    msg_name:       *void;
    msg_namelen:    socklen_t;

    msg_iov:        *iovec;
    msg_iovlen:     u64;

    msg_control:    *void;
    msg_controllen: u64;

    msg_flags:      s32;
}

cmsghdr :: struct {
    cmsg_len:    u64;

    cmsg_level:  s32;
    cmsg_type:   s32;

//     __cmsg_data: *u8;// Incomplete array in C (zero-sized)
}

__cmsg_nxthdr :: (__mhdr: *msghdr, __cmsg: *cmsghdr) -> *cmsghdr #foreign libc;

SCM :: enum u32 {
    RIGHTS                     :: 1;

    CREDENTIALS                :: 2;

    SCM_TIMESTAMP              :: SO_TIMESTAMP;

    SCM_TIMESTAMPNS            :: SO_TIMESTAMPNS;

    SCM_TIMESTAMPING           :: SO_TIMESTAMPING;

    SCM_WIFI_STATUS            :: SO_WIFI_STATUS;

    SCM_TIMESTAMPING_OPT_STATS :: 54;

    SCM_TIMESTAMPING_PKTINFO   :: 58;

    SCM_RIGHTS      :: RIGHTS;

    SCM_CREDENTIALS :: CREDENTIALS;
}

ucred :: struct {
    pid: pid_t;
    uid: uid_t;
    gid: gid_t;
}

linger :: struct {
    l_onoff:  s32;
    l_linger: s32;
}

/* The following constants should be used for the second parameter of
`shutdown'.  */
SHUT :: enum u32 {
    RD   :: 0;

    WR   :: 1;

    RDWR :: 2;

    SHUT_RD   :: RD;

    SHUT_WR   :: WR;

    SHUT_RDWR :: RDWR;
}

/* For `recvmmsg' and `sendmmsg'.  */
mmsghdr :: struct {
    msg_hdr: msghdr; /* Actual message header.  */
    /* Number of received or sent bytes for the
    entry.  */
    msg_len: u32;
}

/* Create a new socket of type TYPE in domain DOMAIN, using
protocol PROTOCOL.  If PROTOCOL is zero, one is chosen automatically.
Returns a file descriptor for the new socket, or -1 for errors.  */
socket :: (__domain: s32, __type: SOCK, __protocol: IPPROTO) -> s32 #foreign libc;

/* Create two new sockets, of type TYPE in domain DOMAIN and using
protocol PROTOCOL, which are connected to each other, and put file
descriptors for them in FDS[0] and FDS[1].  If PROTOCOL is zero,
one will be chosen automatically.  Returns 0 on success, -1 for errors.  */
socketpair :: (__domain: s32, __type: SOCK, __protocol: IPPROTO, __fds: *[2] s32) -> s32 #foreign libc;

/* Give the socket FD the local address ADDR (which is LEN bytes long).  */
bind :: (__fd: s32, __addr: *sockaddr, __len: socklen_t) -> s32 #foreign libc;

/* Put the local address of FD into *ADDR and its length in *LEN.  */
getsockname :: (__fd: s32, __addr: *sockaddr, __len: *socklen_t) -> s32 #foreign libc;

/* Open a connection on socket FD to peer at ADDR (which LEN bytes long).
For connectionless socket types, just set the default address to send to
and the only address from which to accept transmissions.
Return 0 on success, -1 for errors.

This function is a cancellation point and therefore not marked with
__THROW.  */
connect :: (__fd: s32, __addr: *sockaddr, __len: socklen_t) -> s32 #foreign libc;

/* Put the address of the peer connected to socket FD into *ADDR
(which is *LEN bytes long), and its actual length into *LEN.  */
getpeername :: (__fd: s32, __addr: *sockaddr, __len: *socklen_t) -> s32 #foreign libc;

/* Send N bytes of BUF to socket FD.  Returns the number sent or -1.

This function is a cancellation point and therefore not marked with
__THROW.  */
send :: (__fd: s32, __buf: *void, __n: u64, __flags: MSG) -> s64 #foreign libc;

/* Read N bytes into BUF from socket FD.
Returns the number read or -1 for errors.

This function is a cancellation point and therefore not marked with
__THROW.  */
recv :: (__fd: s32, __buf: *void, __n: u64, __flags: MSG) -> s64 #foreign libc;

/* Send N bytes of BUF on socket FD to peer at address ADDR (which is
ADDR_LEN bytes long).  Returns the number sent, or -1 for errors.

This function is a cancellation point and therefore not marked with
__THROW.  */
sendto :: (__fd: s32, __buf: *void, __n: u64, __flags: MSG, __addr: *sockaddr, __addr_len: socklen_t) -> s64 #foreign libc;

/* Read N bytes into BUF through socket FD.
If ADDR is not NULL, fill in *ADDR_LEN bytes of it with tha address of
the sender, and store the actual size of the address in *ADDR_LEN.
Returns the number of bytes read or -1 for errors.

This function is a cancellation point and therefore not marked with
__THROW.  */
recvfrom :: (__fd: s32, __buf: *void, __n: u64, __flags: MSG, __addr: *sockaddr, __addr_len: *socklen_t) -> s64 #foreign libc;

/* Send a message described MESSAGE on socket FD.
Returns the number of bytes sent, or -1 for errors.

This function is a cancellation point and therefore not marked with
__THROW.  */
sendmsg :: (__fd: s32, __message: *msghdr, __flags: MSG) -> s64 #foreign libc;

/* Send a VLEN messages as described by VMESSAGES to socket FD.
Returns the number of datagrams successfully written or -1 for errors.

This function is a cancellation point and therefore not marked with
__THROW.  */
sendmmsg :: (__fd: s32, __vmessages: *mmsghdr, __vlen: u32, __flags: MSG) -> s32 #foreign libc;

/* Receive a message as described by MESSAGE from socket FD.
Returns the number of bytes read or -1 for errors.

This function is a cancellation point and therefore not marked with
__THROW.  */
recvmsg :: (__fd: s32, __message: *msghdr, __flags: MSG) -> s64 #foreign libc;

/* Receive up to VLEN messages as described by VMESSAGES from socket FD.
Returns the number of messages received or -1 for errors.

This function is a cancellation point and therefore not marked with
__THROW.  */
recvmmsg :: (__fd: s32, __vmessages: *mmsghdr, __vlen: u32, __flags: MSG, __tmo: *timespec) -> s32 #foreign libc;

/* Put the current value for socket FD's option OPTNAME at protocol level LEVEL
into OPTVAL (which is *OPTLEN bytes long), and set *OPTLEN to the value's
actual length.  Returns 0 on success, -1 for errors.  */
getsockopt :: (__fd: s32, __level: s32, __optname: s32, __optval: *void, __optlen: *socklen_t) -> s32 #foreign libc;

/* Set socket FD's option OPTNAME at protocol level LEVEL
to *OPTVAL (which is OPTLEN bytes long).
Returns 0 on success, -1 for errors.  */
setsockopt :: (__fd: s32, __level: s32, __optname: s32, __optval: *void, __optlen: socklen_t) -> s32 #foreign libc;

/* Prepare to accept connections on socket FD.
N connection requests will be queued before further requests are refused.
Returns 0 on success, -1 for errors.  */
listen :: (__fd: s32, __n: s32) -> s32 #foreign libc;

/* Await a connection on socket FD.
When a connection arrives, open a new socket to communicate with it,
set *ADDR (which is *ADDR_LEN bytes long) to the address of the connecting
peer and *ADDR_LEN to the address's actual length, and return the
new socket's descriptor, or -1 for errors.

This function is a cancellation point and therefore not marked with
__THROW.  */
accept :: (__fd: s32, __addr: *sockaddr, __addr_len: *socklen_t) -> s32 #foreign libc;

/* Similar to 'accept' but takes an additional parameter to specify flags.

This function is a cancellation point and therefore not marked with
__THROW.  */
accept4 :: (__fd: s32, __addr: *sockaddr, __addr_len: *socklen_t, __flags: SOCK) -> s32 #foreign libc;

/* Shut down all or part of the connection open on socket FD.
HOW determines what to shut down:
SHUT_RD   = No more receptions;
SHUT_WR   = No more transmissions;
SHUT_RDWR = No more receptions or transmissions.
Returns 0 on success, -1 for errors.  */
shutdown :: (__fd: s32, __how: SHUT) -> s32 #foreign libc;

/* Determine wheter socket is at a out-of-band mark.  */
sockatmark :: (__fd: s32) -> s32 #foreign libc;

/* FDTYPE is S_IFSOCK or another S_IF* macro defined in <sys/stat.h>;
returns 1 if FD is open on an object of the indicated type, 0 if not,
or -1 for errors (setting errno).  */
isfdtype :: (__fd: s32, __fdtype: s32) -> s32 #foreign libc;

/* Internet address.  */
in_addr_t :: u32;
in_addr :: struct {
    s_addr: in_addr_t;
}

ip_opts :: struct {
    ip_dst:  in_addr;
    ip_opts: [40] u8;
}

ip_mreqn :: struct {
    imr_multiaddr: in_addr;
    imr_address:   in_addr;
    imr_ifindex:   s32;
}

in_pktinfo :: struct {
    ipi_ifindex:  s32;
    ipi_spec_dst: in_addr;
    ipi_addr:     in_addr;
}

/* Standard well-defined IP protocols.  */
IPPROTO :: enum u32 {
    IP      :: 0;
    ICMP    :: 1;
    IGMP    :: 2;
    IPIP    :: 4;
    TCP     :: 6;
    EGP     :: 8;
    PUP     :: 12;
    UDP     :: 17;
    IDP     :: 22;
    TP      :: 29;
    DCCP    :: 33;
    IPV6    :: 41;
    RSVP    :: 46;
    GRE     :: 47;
    ESP     :: 50;
    AH      :: 51;
    MTP     :: 92;
    BEETPH  :: 94;
    ENCAP   :: 98;
    PIM     :: 103;
    COMP    :: 108;
    SCTP    :: 132;
    UDPLITE :: 136;
    MPLS    :: 137;
    RAW     :: 255;
    MAX     :: 256;

    IPPROTO_IP      :: IP;
    IPPROTO_ICMP    :: ICMP;
    IPPROTO_IGMP    :: IGMP;
    IPPROTO_IPIP    :: IPIP;
    IPPROTO_TCP     :: TCP;
    IPPROTO_EGP     :: EGP;
    IPPROTO_PUP     :: PUP;
    IPPROTO_UDP     :: UDP;
    IPPROTO_IDP     :: IDP;
    IPPROTO_TP      :: TP;
    IPPROTO_DCCP    :: DCCP;
    IPPROTO_IPV6    :: IPV6;
    IPPROTO_RSVP    :: RSVP;
    IPPROTO_GRE     :: GRE;
    IPPROTO_ESP     :: ESP;
    IPPROTO_AH      :: AH;
    IPPROTO_MTP     :: MTP;
    IPPROTO_BEETPH  :: BEETPH;
    IPPROTO_ENCAP   :: ENCAP;
    IPPROTO_PIM     :: PIM;
    IPPROTO_COMP    :: COMP;
    IPPROTO_SCTP    :: SCTP;
    IPPROTO_UDPLITE :: UDPLITE;
    IPPROTO_MPLS    :: MPLS;
    IPPROTO_RAW     :: RAW;
    IPPROTO_MAX     :: MAX;
}

IPPROTO_1 :: enum u32 {
    HOPOPTS  :: 0;

    ROUTING  :: 43;

    FRAGMENT :: 44;

    ICMPV6   :: 58;

    NONE     :: 59;

    DSTOPTS  :: 60;

    MH       :: 135;

    IPPROTO_HOPOPTS  :: HOPOPTS;

    IPPROTO_ROUTING  :: ROUTING;

    IPPROTO_FRAGMENT :: FRAGMENT;

    IPPROTO_ICMPV6   :: ICMPV6;

    IPPROTO_NONE     :: NONE;

    IPPROTO_DSTOPTS  :: DSTOPTS;

    IPPROTO_MH       :: MH;
}

/* Type to represent a port.  */
in_port_t :: u16;

/* Standard well-known ports.  */
IPPORT :: enum u32 {
    ECHO         :: 7;
    DISCARD      :: 9;
    SYSTAT       :: 11;
    DAYTIME      :: 13;
    NETSTAT      :: 15;
    FTP          :: 21;
    TELNET       :: 23;
    SMTP         :: 25;
    TIMESERVER   :: 37;
    NAMESERVER   :: 42;
    WHOIS        :: 43;
    MTP          :: 57;

    TFTP         :: 69;
    RJE          :: 77;
    FINGER       :: 79;
    TTYLINK      :: 87;
    SUPDUP       :: 95;

    EXECSERVER   :: 512;
    LOGINSERVER  :: 513;
    CMDSERVER    :: 514;
    EFSSERVER    :: 520;

    BIFFUDP      :: 512;
    WHOSERVER    :: 513;
    ROUTESERVER  :: 520;

    RESERVED     :: 1024;

    USERRESERVED :: 5000;

    IPPORT_ECHO         :: ECHO;
    IPPORT_DISCARD      :: DISCARD;
    IPPORT_SYSTAT       :: SYSTAT;
    IPPORT_DAYTIME      :: DAYTIME;
    IPPORT_NETSTAT      :: NETSTAT;
    IPPORT_FTP          :: FTP;
    IPPORT_TELNET       :: TELNET;
    IPPORT_SMTP         :: SMTP;
    IPPORT_TIMESERVER   :: TIMESERVER;
    IPPORT_NAMESERVER   :: NAMESERVER;
    IPPORT_WHOIS        :: WHOIS;
    IPPORT_MTP          :: MTP;

    IPPORT_TFTP         :: TFTP;
    IPPORT_RJE          :: RJE;
    IPPORT_FINGER       :: FINGER;
    IPPORT_TTYLINK      :: TTYLINK;
    IPPORT_SUPDUP       :: SUPDUP;

    IPPORT_EXECSERVER   :: EXECSERVER;
    IPPORT_LOGINSERVER  :: LOGINSERVER;
    IPPORT_CMDSERVER    :: CMDSERVER;
    IPPORT_EFSSERVER    :: EFSSERVER;

    IPPORT_BIFFUDP      :: BIFFUDP;
    IPPORT_WHOSERVER    :: WHOSERVER;
    IPPORT_ROUTESERVER  :: ROUTESERVER;

    IPPORT_RESERVED     :: RESERVED;

    IPPORT_USERRESERVED :: USERRESERVED;
}

/* IPv6 address */
in6_addr :: struct {
    __in6_u: union {
        __u6_addr8:  [16] u8;
        __u6_addr16: [8] u16;
        __u6_addr32: [4] u32;
    };
}

in6addr_any: in6_addr; /* :: */
in6addr_loopback: in6_addr; /* ::1 */

/* Structure describing an Internet socket address.  */
sockaddr_in :: struct {
    sin_family: sa_family_t;
    sin_port:   in_port_t; /* Port number.  */
    sin_addr:   in_addr; /* Internet address.  */

    /* Pad to size of `struct sockaddr'.  */
    sin_zero:   [8] u8;
}

/* Ditto, for IPv6.  */
sockaddr_in6 :: struct {
    sin6_family:   sa_family_t;
    sin6_port:     in_port_t; /* Transport layer port # */
    sin6_flowinfo: u32; /* IPv6 flow information */
    sin6_addr:     in6_addr; /* IPv6 address */
    sin6_scope_id: u32; /* IPv6 scope-id */
}

/* IPv4 multicast request.  */
ip_mreq :: struct {
    /* IP multicast address of group.  */
    imr_multiaddr: in_addr;

    /* Local IP address of interface.  */
    imr_interface: in_addr;
}

ip_mreq_source :: struct {
    /* IP multicast address of group.  */
    imr_multiaddr:  in_addr;

    /* IP address of interface.  */
    imr_interface:  in_addr;

    /* IP address of source.  */
    imr_sourceaddr: in_addr;
}

/* Likewise, for IPv6.  */
ipv6_mreq :: struct {
    /* IPv6 multicast address of group */
    ipv6mr_multiaddr: in6_addr;

    /* local interface */
    ipv6mr_interface: u32;
}

/* Multicast group request.  */
group_req :: struct {
    /* Interface index.  */
    gr_interface: u32;

    /* Group address.  */
    gr_group:     sockaddr_storage;
}

group_source_req :: struct {
    /* Interface index.  */
    gsr_interface: u32;

    /* Group address.  */
    gsr_group:     sockaddr_storage;

    /* Source address.  */
    gsr_source:    sockaddr_storage;
}

/* Full-state filter operations.  */
ip_msfilter :: struct {
    /* IP multicast address of group.  */
    imsf_multiaddr: in_addr;

    /* Local IP address of interface.  */
    imsf_interface: in_addr;

    /* Filter mode.  */
    imsf_fmode:     u32;

    /* Number of source addresses.  */
    imsf_numsrc:    u32;

    /* Source addresses.  */
    imsf_slist:     [1] in_addr;
}

group_filter :: struct {
    /* Interface index.  */
    gf_interface: u32;

    /* Group address.  */
    gf_group:     sockaddr_storage;

    /* Filter mode.  */
    gf_fmode:     u32;

    /* Number of source addresses.  */
    gf_numsrc:    u32;

    /* Source addresses.  */
    gf_slist:     [1] sockaddr_storage;
}

/* Functions to convert between host and network byte order.

Please note that these functions normally take `unsigned long int' or
`unsigned short int' values as arguments and also return them.  But
this was a short-sighted decision since on different systems the types
may have different representations but the values are always the same.  */
ntohl :: (__netlong: u32) -> u32 #foreign libc;
ntohs :: (__netshort: u16) -> u16 #foreign libc;

htonl :: (__hostlong: u32) -> u32 #foreign libc;

htons :: (__hostshort: u16) -> u16 #foreign libc;

/* Bind socket to a privileged IP port.  */
bindresvport :: (__sockfd: s32, __sock_in: *sockaddr_in) -> s32 #foreign libc;

/* IPv6 packet information.  */
in6_pktinfo :: struct {
    ipi6_addr:    in6_addr; /* src/dst IPv6 address */
    ipi6_ifindex: u32; /* send/recv interface index */
}

/* IPv6 MTU information.  */
ip6_mtuinfo :: struct {
    ip6m_addr: sockaddr_in6; /* dst address including zone ID */
    ip6m_mtu:  u32; /* path MTU in host byte order */
}

/* Obsolete hop-by-hop and Destination Options Processing (RFC 2292).  */
inet6_option_space :: (__nbytes: s32) -> s32 #foreign libc;

inet6_option_init :: (__bp: *void, __cmsgp: **cmsghdr, __type: s32) -> s32 #foreign libc;

inet6_option_append :: (__cmsg: *cmsghdr, __typep: *u8, __multx: s32, __plusy: s32) -> s32 #foreign libc;

inet6_option_alloc :: (__cmsg: *cmsghdr, __datalen: s32, __multx: s32, __plusy: s32) -> *u8 #foreign libc;

inet6_option_next :: (__cmsg: *cmsghdr, __tptrp: **u8) -> s32 #foreign libc;

inet6_option_find :: (__cmsg: *cmsghdr, __tptrp: **u8, __type: s32) -> s32 #foreign libc;

/* Hop-by-Hop and Destination Options Processing (RFC 3542).  */
inet6_opt_init :: (__extbuf: *void, __extlen: socklen_t) -> s32 #foreign libc;
inet6_opt_append :: (__extbuf: *void, __extlen: socklen_t, __offset: s32, __type: u8, __len: socklen_t, __align: u8, __databufp: **void) -> s32 #foreign libc;

inet6_opt_finish :: (__extbuf: *void, __extlen: socklen_t, __offset: s32) -> s32 #foreign libc;

inet6_opt_set_val :: (__databuf: *void, __offset: s32, __val: *void, __vallen: socklen_t) -> s32 #foreign libc;

inet6_opt_next :: (__extbuf: *void, __extlen: socklen_t, __offset: s32, __typep: *u8, __lenp: *socklen_t, __databufp: **void) -> s32 #foreign libc;

inet6_opt_find :: (__extbuf: *void, __extlen: socklen_t, __offset: s32, __type: u8, __lenp: *socklen_t, __databufp: **void) -> s32 #foreign libc;

inet6_opt_get_val :: (__databuf: *void, __offset: s32, __val: *void, __vallen: socklen_t) -> s32 #foreign libc;

/* Routing Header Option (RFC 3542).  */
inet6_rth_space :: (__type: s32, __segments: s32) -> socklen_t #foreign libc;
inet6_rth_init :: (__bp: *void, __bp_len: socklen_t, __type: s32, __segments: s32) -> *void #foreign libc;

inet6_rth_add :: (__bp: *void, __addr: *in6_addr) -> s32 #foreign libc;
inet6_rth_reverse :: (__in: *void, __out: *void) -> s32 #foreign libc;
inet6_rth_segments :: (__bp: *void) -> s32 #foreign libc;
inet6_rth_getaddr :: (__bp: *void, __index: s32) -> *in6_addr #foreign libc;

/* Get IPv4 source filter.  */
getipv4sourcefilter :: (__s: s32, __interface_addr: in_addr, __group: in_addr, __fmode: *u32, __numsrc: *u32, __slist: *in_addr) -> s32 #foreign libc;

/* Set IPv4 source filter.  */
setipv4sourcefilter :: (__s: s32, __interface_addr: in_addr, __group: in_addr, __fmode: u32, __numsrc: u32, __slist: *in_addr) -> s32 #foreign libc;

/* Get source filter.  */
getsourcefilter :: (__s: s32, __interface_addr: u32, __group: *sockaddr, __grouplen: socklen_t, __fmode: *u32, __numsrc: *u32, __slist: *sockaddr_storage) -> s32 #foreign libc;

/* Set source filter.  */
setsourcefilter :: (__s: s32, __interface_addr: u32, __group: *sockaddr, __grouplen: socklen_t, __fmode: u32, __numsrc: u32, __slist: *sockaddr_storage) -> s32 #foreign libc;

tcp_seq :: u32;

/*
* TCP header.
* Per RFC 793, September, 1981.
*/
tcphdr :: struct {
    union {
        struct {
            th_sport:   u16; /* source port */
            th_dport:   u16; /* destination port */
            th_seq:     tcp_seq; /* sequence number */
            th_ack:     tcp_seq; /* acknowledgement number */

            __bitfield: u8;
            /* 
                th_x2: u8; /* 4 bits */ /* (unused) */
                th_off: u8; /* 4 bits */ /* data offset */;
            */

            th_flags:   u8;

            th_win:     u16; /* window */
            th_sum:     u16; /* checksum */
            th_urp:     u16; /* urgent pointer */
        }

        struct {
            source:       u16;
            dest:         u16;
            seq:          u32;
            ack_seq:      u32;

            __bitfield_1: u16;
            /* 
                res1: u16; /* 4 bits */
                doff: u16; /* 4 bits */
                fin: u16; /* 1 bits */
                syn: u16; /* 1 bits */
                rst: u16; /* 1 bits */
                psh: u16; /* 1 bits */
                ack: u16; /* 1 bits */
                urg: u16; /* 1 bits */
                res2: u16; /* 2 bits */;
            */

            window:       u16;
            check:        u16;
            urg_ptr:      u16;
        }
    }
}

TCP :: enum u32 {
    ESTABLISHED :: 1;
    SYN_SENT    :: 2;
    SYN_RECV    :: 3;
    FIN_WAIT1   :: 4;
    FIN_WAIT2   :: 5;
    TIME_WAIT   :: 6;
    CLOSE       :: 7;
    CLOSE_WAIT  :: 8;
    LAST_ACK    :: 9;
    LISTEN      :: 10;
    CLOSING     :: 11;

    TCP_ESTABLISHED :: ESTABLISHED;
    TCP_SYN_SENT    :: SYN_SENT;
    TCP_SYN_RECV    :: SYN_RECV;
    TCP_FIN_WAIT1   :: FIN_WAIT1;
    TCP_FIN_WAIT2   :: FIN_WAIT2;
    TCP_TIME_WAIT   :: TIME_WAIT;
    TCP_CLOSE       :: CLOSE;
    TCP_CLOSE_WAIT  :: CLOSE_WAIT;
    TCP_LAST_ACK    :: LAST_ACK;
    TCP_LISTEN      :: LISTEN;
    TCP_CLOSING     :: CLOSING;
}

/* Values for tcpi_state.  */
tcp_ca_state :: enum u32 {
    Open     :: 0;
    Disorder :: 1;
    CWR      :: 2;
    Recovery :: 3;
    Loss     :: 4;

    TCP_CA_Open     :: Open;
    TCP_CA_Disorder :: Disorder;
    TCP_CA_CWR      :: CWR;
    TCP_CA_Recovery :: Recovery;
    TCP_CA_Loss     :: Loss;
}

tcp_info :: struct {
    tcpi_state:          u8;
    tcpi_ca_state:       u8;
    tcpi_retransmits:    u8;
    tcpi_probes:         u8;
    tcpi_backoff:        u8;
    tcpi_options:        u8;
    __bitfield:          u8;
    /* 
        tcpi_snd_wscale: u8; /* 4 bits */
        tcpi_rcv_wscale: u8; /* 4 bits */;
    */

    tcpi_rto:            u32;
    tcpi_ato:            u32;
    tcpi_snd_mss:        u32;
    tcpi_rcv_mss:        u32;

    tcpi_unacked:        u32;
    tcpi_sacked:         u32;
    tcpi_lost:           u32;
    tcpi_retrans:        u32;
    tcpi_fackets:        u32;

    /* Times. */
    tcpi_last_data_sent: u32;
    tcpi_last_ack_sent:  u32; /* Not remembered, sorry.  */
    tcpi_last_data_recv: u32;
    tcpi_last_ack_recv:  u32;

    /* Metrics. */
    tcpi_pmtu:           u32;
    tcpi_rcv_ssthresh:   u32;
    tcpi_rtt:            u32;
    tcpi_rttvar:         u32;
    tcpi_snd_ssthresh:   u32;
    tcpi_snd_cwnd:       u32;
    tcpi_advmss:         u32;
    tcpi_reordering:     u32;

    tcpi_rcv_rtt:        u32;
    tcpi_rcv_space:      u32;

    tcpi_total_retrans:  u32;
}

tcp_md5sig :: struct {
    tcpm_addr:      sockaddr_storage; /* Address associated.  */
    tcpm_flags:     u8; /* Extension flags.  */
    tcpm_prefixlen: u8; /* Address prefix.  */
    tcpm_keylen:    u16; /* Key length.  */
    __tcpm_pad:     u32; /* Zero.  */
    tcpm_key:       [80] u8; /* Key (binary).  */
}

/* For socket repair options.  */
tcp_repair_opt :: struct {
    opt_code: u32;
    opt_val:  u32;
}

/* Queue to repair, for TCP_REPAIR_QUEUE.  */
TCP_1 :: enum u32 {
    NO_QUEUE   :: 0;
    RECV_QUEUE :: 1;
    SEND_QUEUE :: 2;
    QUEUES_NR  :: 3;

    TCP_NO_QUEUE   :: NO_QUEUE;
    TCP_RECV_QUEUE :: RECV_QUEUE;
    TCP_SEND_QUEUE :: SEND_QUEUE;
    TCP_QUEUES_NR  :: QUEUES_NR;
}

tcp_cookie_transactions :: struct {
    tcpct_flags:          u16;
    __tcpct_pad1:         u8;
    tcpct_cookie_desired: u8;
    tcpct_s_data_desired: u16;
    tcpct_used:           u16;
    tcpct_value:          [536] u8;
}

/* For use with TCP_REPAIR_WINDOW.  */
tcp_repair_window :: struct {
    snd_wl1:    u32;
    snd_wnd:    u32;
    max_window: u32;
    rcv_wnd:    u32;
    rcv_wup:    u32;
}

netent :: struct {
    n_name:     *u8;
    n_aliases:  **u8;
    n_addrtype: s32;
    n_net:      u32;
}

/* Function to get address of global `h_errno' variable.  */
__h_errno_location :: () -> *s32 #foreign libc;

/* Print error indicated by `h_errno' variable on standard error.  STR
if non-null is printed before the error string.  */
herror :: (__str: *u8) -> void #foreign libc;

/* Return string associated with error ERR_NUM.  */
hstrerror :: (__err_num: s32) -> *u8 #foreign libc;

/* Description of data base entry for a single host.  */
hostent :: struct {
    h_name:      *u8; /* Official name of host.  */
    h_aliases:   **u8; /* Alias list.  */
    h_addrtype:  s32; /* Host address type.  */
    h_length:    s32; /* Length of address.  */
    h_addr_list: **u8; /* List of addresses from name server.  */
}

/* Open host data base files and mark them as staying open even after
a later search if STAY_OPEN is non-zero.

This function is a possible cancellation point and therefore not
marked with __THROW.  */
sethostent :: (__stay_open: s32) -> void #foreign libc;

/* Close host data base files and clear `stay open' flag.

This function is a possible cancellation point and therefore not
marked with __THROW.  */
endhostent :: () -> void #foreign libc;

/* Get next entry from host data base file.  Open data base if
necessary.

This function is a possible cancellation point and therefore not
marked with __THROW.  */
gethostent :: () -> *hostent #foreign libc;

/* Return entry from host data base which address match ADDR with
length LEN and type TYPE.

This function is a possible cancellation point and therefore not
marked with __THROW.  */
gethostbyaddr :: (__addr: *void, __len: u32, __type: s32) -> *hostent #foreign libc;

/* Return entry from host data base for host with NAME.

This function is a possible cancellation point and therefore not
marked with __THROW.  */
gethostbyname :: (__name: *u8) -> *hostent #foreign libc;

/* Return entry from host data base for host with NAME.  AF must be
set to the address type which is `AF_INET' for IPv4 or `AF_INET6'
for IPv6.

This function is not part of POSIX and therefore no official
cancellation point.  But due to similarity with an POSIX interface
or due to the implementation it is a cancellation point and
therefore not marked with __THROW.  */
gethostbyname2 :: (__name: *u8, __af: s32) -> *hostent #foreign libc;

/* Reentrant versions of the functions above.  The additional
arguments specify a buffer of BUFLEN starting at BUF.  The last
argument is a pointer to a variable which gets the value which
would be stored in the global variable `herrno' by the
non-reentrant functions.

These functions are not part of POSIX and therefore no official
cancellation point.  But due to similarity with an POSIX interface
or due to the implementation they are cancellation points and
therefore not marked with __THROW.  */
gethostent_r :: (__result_buf: *hostent, __buf: *u8, __buflen: u64, __result: **hostent, __h_errnop: *s32) -> s32 #foreign libc;

gethostbyaddr_r :: (__addr: *void, __len: u32, __type: s32, __result_buf: *hostent, __buf: *u8, __buflen: u64, __result: **hostent, __h_errnop: *s32) -> s32 #foreign libc;

gethostbyname_r :: (__name: *u8, __result_buf: *hostent, __buf: *u8, __buflen: u64, __result: **hostent, __h_errnop: *s32) -> s32 #foreign libc;

gethostbyname2_r :: (__name: *u8, __af: s32, __result_buf: *hostent, __buf: *u8, __buflen: u64, __result: **hostent, __h_errnop: *s32) -> s32 #foreign libc;

/* Open network data base files and mark them as staying open even
after a later search if STAY_OPEN is non-zero.

This function is a possible cancellation point and therefore not
marked with __THROW.  */
setnetent :: (__stay_open: s32) -> void #foreign libc;

/* Close network data base files and clear `stay open' flag.

This function is a possible cancellation point and therefore not
marked with __THROW.  */
endnetent :: () -> void #foreign libc;

/* Get next entry from network data base file.  Open data base if
necessary.

This function is a possible cancellation point and therefore not
marked with __THROW.  */
getnetent :: () -> *netent #foreign libc;

/* Return entry from network data base which address match NET and
type TYPE.

This function is a possible cancellation point and therefore not
marked with __THROW.  */
getnetbyaddr :: (__net: u32, __type: s32) -> *netent #foreign libc;

/* Return entry from network data base for network with NAME.

This function is a possible cancellation point and therefore not
marked with __THROW.  */
getnetbyname :: (__name: *u8) -> *netent #foreign libc;

/* Reentrant versions of the functions above.  The additional
arguments specify a buffer of BUFLEN starting at BUF.  The last
argument is a pointer to a variable which gets the value which
would be stored in the global variable `herrno' by the
non-reentrant functions.

These functions are not part of POSIX and therefore no official
cancellation point.  But due to similarity with an POSIX interface
or due to the implementation they are cancellation points and
therefore not marked with __THROW.  */
getnetent_r :: (__result_buf: *netent, __buf: *u8, __buflen: u64, __result: **netent, __h_errnop: *s32) -> s32 #foreign libc;

getnetbyaddr_r :: (__net: u32, __type: s32, __result_buf: *netent, __buf: *u8, __buflen: u64, __result: **netent, __h_errnop: *s32) -> s32 #foreign libc;

getnetbyname_r :: (__name: *u8, __result_buf: *netent, __buf: *u8, __buflen: u64, __result: **netent, __h_errnop: *s32) -> s32 #foreign libc;

/* Description of data base entry for a single service.  */
servent :: struct {
    s_name:    *u8; /* Official service name.  */
    s_aliases: **u8; /* Alias list.  */
    s_port:    s32; /* Port number.  */
    s_proto:   *u8; /* Protocol to use.  */
}

/* Open service data base files and mark them as staying open even
after a later search if STAY_OPEN is non-zero.

This function is a possible cancellation point and therefore not
marked with __THROW.  */
setservent :: (__stay_open: s32) -> void #foreign libc;

/* Close service data base files and clear `stay open' flag.

This function is a possible cancellation point and therefore not
marked with __THROW.  */
endservent :: () -> void #foreign libc;

/* Get next entry from service data base file.  Open data base if
necessary.

This function is a possible cancellation point and therefore not
marked with __THROW.  */
getservent :: () -> *servent #foreign libc;

/* Return entry from network data base for network with NAME and
protocol PROTO.

This function is a possible cancellation point and therefore not
marked with __THROW.  */
getservbyname :: (__name: *u8, __proto: *u8) -> *servent #foreign libc;

/* Return entry from service data base which matches port PORT and
protocol PROTO.

This function is a possible cancellation point and therefore not
marked with __THROW.  */
getservbyport :: (__port: s32, __proto: *u8) -> *servent #foreign libc;

/* Reentrant versions of the functions above.  The additional
arguments specify a buffer of BUFLEN starting at BUF.

These functions are not part of POSIX and therefore no official
cancellation point.  But due to similarity with an POSIX interface
or due to the implementation they are cancellation points and
therefore not marked with __THROW.  */
getservent_r :: (__result_buf: *servent, __buf: *u8, __buflen: u64, __result: **servent) -> s32 #foreign libc;

getservbyname_r :: (__name: *u8, __proto: *u8, __result_buf: *servent, __buf: *u8, __buflen: u64, __result: **servent) -> s32 #foreign libc;

getservbyport_r :: (__port: s32, __proto: *u8, __result_buf: *servent, __buf: *u8, __buflen: u64, __result: **servent) -> s32 #foreign libc;

/* Description of data base entry for a single service.  */
protoent :: struct {
    p_name:    *u8; /* Official protocol name.  */
    p_aliases: **u8; /* Alias list.  */
    p_proto:   s32; /* Protocol number.  */
}

/* Open protocol data base files and mark them as staying open even
after a later search if STAY_OPEN is non-zero.

This function is a possible cancellation point and therefore not
marked with __THROW.  */
setprotoent :: (__stay_open: s32) -> void #foreign libc;

/* Close protocol data base files and clear `stay open' flag.

This function is a possible cancellation point and therefore not
marked with __THROW.  */
endprotoent :: () -> void #foreign libc;

/* Get next entry from protocol data base file.  Open data base if
necessary.

This function is a possible cancellation point and therefore not
marked with __THROW.  */
getprotoent :: () -> *protoent #foreign libc;

/* Return entry from protocol data base for network with NAME.

This function is a possible cancellation point and therefore not
marked with __THROW.  */
getprotobyname :: (__name: *u8) -> *protoent #foreign libc;

/* Return entry from protocol data base which number is PROTO.

This function is a possible cancellation point and therefore not
marked with __THROW.  */
getprotobynumber :: (__proto: s32) -> *protoent #foreign libc;

/* Reentrant versions of the functions above.  The additional
arguments specify a buffer of BUFLEN starting at BUF.

These functions are not part of POSIX and therefore no official
cancellation point.  But due to similarity with an POSIX interface
or due to the implementation they are cancellation points and
therefore not marked with __THROW.  */
getprotoent_r :: (__result_buf: *protoent, __buf: *u8, __buflen: u64, __result: **protoent) -> s32 #foreign libc;

getprotobyname_r :: (__name: *u8, __result_buf: *protoent, __buf: *u8, __buflen: u64, __result: **protoent) -> s32 #foreign libc;

getprotobynumber_r :: (__proto: s32, __result_buf: *protoent, __buf: *u8, __buflen: u64, __result: **protoent) -> s32 #foreign libc;

/* Establish network group NETGROUP for enumeration.

This function is not part of POSIX and therefore no official
cancellation point.  But due to similarity with an POSIX interface
or due to the implementation it is a cancellation point and
therefore not marked with __THROW.  */
setnetgrent :: (__netgroup: *u8) -> s32 #foreign libc;

/* Free all space allocated by previous `setnetgrent' call.

This function is not part of POSIX and therefore no official
cancellation point.  But due to similarity with an POSIX interface
or due to the implementation it is a cancellation point and
therefore not marked with __THROW.  */
endnetgrent :: () -> void #foreign libc;

/* Get next member of netgroup established by last `setnetgrent' call
and return pointers to elements in HOSTP, USERP, and DOMAINP.

This function is not part of POSIX and therefore no official
cancellation point.  But due to similarity with an POSIX interface
or due to the implementation it is a cancellation point and
therefore not marked with __THROW.  */
getnetgrent :: (__hostp: **u8, __userp: **u8, __domainp: **u8) -> s32 #foreign libc;

/* Test whether NETGROUP contains the triple (HOST,USER,DOMAIN).

This function is not part of POSIX and therefore no official
cancellation point.  But due to similarity with an POSIX interface
or due to the implementation it is a cancellation point and
therefore not marked with __THROW.  */
innetgr :: (__netgroup: *u8, __host: *u8, __user: *u8, __domain: *u8) -> s32 #foreign libc;

/* Reentrant version of `getnetgrent' where result is placed in BUFFER.

This function is not part of POSIX and therefore no official
cancellation point.  But due to similarity with an POSIX interface
or due to the implementation it is a cancellation point and
therefore not marked with __THROW.  */
getnetgrent_r :: (__hostp: **u8, __userp: **u8, __domainp: **u8, __buffer: *u8, __buflen: u64) -> s32 #foreign libc;

/* Call `rshd' at port RPORT on remote machine *AHOST to execute CMD.
The local user is LOCUSER, on the remote machine the command is
executed as REMUSER.  In *FD2P the descriptor to the socket for the
connection is returned.  The caller must have the right to use a
reserved port.  When the function returns *AHOST contains the
official host name.

This function is not part of POSIX and therefore no official
cancellation point.  But due to similarity with an POSIX interface
or due to the implementation it is a cancellation point and
therefore not marked with __THROW.  */
rcmd :: (__ahost: **u8, __rport: u16, __locuser: *u8, __remuser: *u8, __cmd: *u8, __fd2p: *s32) -> s32 #foreign libc;

/* This is the equivalent function where the protocol can be selected
and which therefore can be used for IPv6.

This function is not part of POSIX and therefore no official
cancellation point.  But due to similarity with an POSIX interface
or due to the implementation it is a cancellation point and
therefore not marked with __THROW.  */
rcmd_af :: (__ahost: **u8, __rport: u16, __locuser: *u8, __remuser: *u8, __cmd: *u8, __fd2p: *s32, __af: sa_family_t) -> s32 #foreign libc;

/* Call `rexecd' at port RPORT on remote machine *AHOST to execute
CMD.  The process runs at the remote machine using the ID of user
NAME whose cleartext password is PASSWD.  In *FD2P the descriptor
to the socket for the connection is returned.  When the function
returns *AHOST contains the official host name.

This function is not part of POSIX and therefore no official
cancellation point.  But due to similarity with an POSIX interface
or due to the implementation it is a cancellation point and
therefore not marked with __THROW.  */
rexec :: (__ahost: **u8, __rport: s32, __name: *u8, __pass: *u8, __cmd: *u8, __fd2p: *s32) -> s32 #foreign libc;

/* This is the equivalent function where the protocol can be selected
and which therefore can be used for IPv6.

This function is not part of POSIX and therefore no official
cancellation point.  But due to similarity with an POSIX interface
or due to the implementation it is a cancellation point and
therefore not marked with __THROW.  */
rexec_af :: (__ahost: **u8, __rport: s32, __name: *u8, __pass: *u8, __cmd: *u8, __fd2p: *s32, __af: sa_family_t) -> s32 #foreign libc;

/* Check whether user REMUSER on system RHOST is allowed to login as LOCUSER.
If SUSER is not zero the user tries to become superuser.  Return 0 if
it is possible.

This function is not part of POSIX and therefore no official
cancellation point.  But due to similarity with an POSIX interface
or due to the implementation it is a cancellation point and
therefore not marked with __THROW.  */
ruserok :: (__rhost: *u8, __suser: s32, __remuser: *u8, __locuser: *u8) -> s32 #foreign libc;

/* This is the equivalent function where the protocol can be selected
and which therefore can be used for IPv6.

This function is not part of POSIX and therefore no official
cancellation point.  But due to similarity with an POSIX interface
or due to the implementation it is a cancellation point and
therefore not marked with __THROW.  */
ruserok_af :: (__rhost: *u8, __suser: s32, __remuser: *u8, __locuser: *u8, __af: sa_family_t) -> s32 #foreign libc;

/* Check whether user REMUSER on system indicated by IPv4 address
RADDR is allowed to login as LOCUSER.  Non-IPv4 (e.g., IPv6) are
not supported.  If SUSER is not zero the user tries to become
superuser.  Return 0 if it is possible.

This function is not part of POSIX and therefore no official
cancellation point.  But due to similarity with an POSIX interface
or due to the implementation it is a cancellation point and
therefore not marked with __THROW.  */
iruserok :: (__raddr: u32, __suser: s32, __remuser: *u8, __locuser: *u8) -> s32 #foreign libc;

/* This is the equivalent function where the pfamiliy if the address
pointed to by RADDR is determined by the value of AF.  It therefore
can be used for IPv6

This function is not part of POSIX and therefore no official
cancellation point.  But due to similarity with an POSIX interface
or due to the implementation it is a cancellation point and
therefore not marked with __THROW.  */
iruserok_af :: (__raddr: *void, __suser: s32, __remuser: *u8, __locuser: *u8, __af: sa_family_t) -> s32 #foreign libc;

/* Try to allocate reserved port, returning a descriptor for a socket opened
at this port or -1 if unsuccessful.  The search for an available port
will start at ALPORT and continues with lower numbers.

This function is not part of POSIX and therefore no official
cancellation point.  But due to similarity with an POSIX interface
or due to the implementation it is a cancellation point and
therefore not marked with __THROW.  */
rresvport :: (__alport: *s32) -> s32 #foreign libc;

/* This is the equivalent function where the protocol can be selected
and which therefore can be used for IPv6.

This function is not part of POSIX and therefore no official
cancellation point.  But due to similarity with an POSIX interface
or due to the implementation it is a cancellation point and
therefore not marked with __THROW.  */
rresvport_af :: (__alport: *s32, __af: sa_family_t) -> s32 #foreign libc;

/* Structure to contain information about address of a service provider.  */
addrinfo :: struct {
    ai_flags:     AI; /* Input flags.  */
    ai_family:    s32; /* Protocol family for socket.  */
    ai_socktype:  SOCK; /* Socket type.  */
    ai_protocol:  IPPROTO; /* Protocol for socket.  */
    ai_addrlen:   socklen_t; /* Length of socket address.  */
    ai_addr:      *sockaddr; /* Socket address for socket.  */
    ai_canonname: *u8; /* Canonical name for service location.  */
    ai_next:      *addrinfo; /* Pointer to next in list.  */
}

/* Structure used as control block for asynchronous lookup.  */
gaicb :: struct {
    ar_name:          *u8; /* Name to look up.  */
    ar_service:       *u8; /* Service name.  */
    ar_request:       *addrinfo; /* Additional request specification.  */
    ar_result:        *addrinfo; /* Pointer to result.  */

    /* The following are internal elements.  */
    __return:         s32;
    __glibc_reserved: [5] s32;
}

/* Translate name of a service location and/or a service name to set of
socket addresses.

This function is a possible cancellation point and therefore not
marked with __THROW.  */
getaddrinfo :: (__name: *u8, __service: *u8, __req: *addrinfo, __pai: **addrinfo) -> s32 #foreign libc;

/* Free `addrinfo' structure AI including associated storage.  */
freeaddrinfo :: (__ai: *addrinfo) -> void #foreign libc;

/* Convert error return from getaddrinfo() to a string.  */
gai_strerror :: (__ecode: s32) -> *u8 #foreign libc;

/* Translate a socket address to a location and service name.

This function is a possible cancellation point and therefore not
marked with __THROW.  */
getnameinfo :: (__sa: *sockaddr, __salen: socklen_t, __host: *u8, __hostlen: socklen_t, __serv: *u8, __servlen: socklen_t, __flags: s32) -> s32 #foreign libc;

/* Convert Internet host address from numbers-and-dots notation in CP
into binary data in network byte order.  */
inet_addr :: (__cp: *u8) -> in_addr_t #foreign libc;

/* Return the local host address part of the Internet address in IN.  */
inet_lnaof :: (__in: in_addr) -> in_addr_t #foreign libc;

/* Make Internet host address in network byte order by combining the
network number NET with the local address HOST.  */
inet_makeaddr :: (__net: in_addr_t, __host: in_addr_t) -> in_addr #foreign libc;

/* Return network number part of the Internet address IN.  */
inet_netof :: (__in: in_addr) -> in_addr_t #foreign libc;

/* Extract the network number in network byte order from the address
in numbers-and-dots natation starting at CP.  */
inet_network :: (__cp: *u8) -> in_addr_t #foreign libc;

/* Convert Internet number in IN to ASCII representation.  The return value
is a pointer to an internal array containing the string.  */
inet_ntoa :: (__in: in_addr) -> *u8 #foreign libc;

/* Convert from presentation format of an Internet number in buffer
starting at CP to the binary network format and store result for
interface type AF in buffer starting at BUF.  */
inet_pton :: (__af: s32, __cp: *u8, __buf: *void) -> s32 #foreign libc;

/* Convert a Internet address in binary network format for interface
type AF in buffer starting at CP to presentation form and place
result in buffer of length LEN astarting at BUF.  */
inet_ntop :: (__af: s32, __cp: *void, __buf: *u8, __len: socklen_t) -> *u8 #foreign libc;

/* Convert Internet host address from numbers-and-dots notation in CP
into binary data and store the result in the structure INP.  */
inet_aton :: (__cp: *u8, __inp: *in_addr) -> s32 #foreign libc;

/* Convert ASCII representation in hexadecimal form of the Internet
address to binary form and place result in buffer of length LEN
starting at BUF.  */
inet_nsap_addr :: (__cp: *u8, __buf: *u8, __len: s32) -> u32 #foreign libc;

/* Convert internet address in binary form in LEN bytes starting at CP
a presentation form and place result in BUF.  */
inet_nsap_ntoa :: (__len: s32, __cp: *u8, __buf: *u8) -> *u8 #foreign libc;

if_nameindex :: struct {
    if_index: u32; /* 1, 2, ... */
    if_name:  *u8; /* null terminated name: "eth0", ... */
}

/* Standard interface flags. */
IFF :: enum u32 {
    UP          :: 1;

    BROADCAST   :: 2;

    DEBUG       :: 4;

    LOOPBACK    :: 8;

    POINTOPOINT :: 16;

    NOTRAILERS  :: 32;

    RUNNING     :: 64;

    NOARP       :: 128;

    PROMISC     :: 256;

    ALLMULTI    :: 512;

    MASTER      :: 1024;

    SLAVE       :: 2048;

    MULTICAST   :: 4096;

    PORTSEL     :: 8192;

    AUTOMEDIA   :: 16384;

    DYNAMIC     :: 32768;

    IFF_UP          :: UP;

    IFF_BROADCAST   :: BROADCAST;

    IFF_DEBUG       :: DEBUG;

    IFF_LOOPBACK    :: LOOPBACK;

    IFF_POINTOPOINT :: POINTOPOINT;

    IFF_NOTRAILERS  :: NOTRAILERS;

    IFF_RUNNING     :: RUNNING;

    IFF_NOARP       :: NOARP;

    IFF_PROMISC     :: PROMISC;

    IFF_ALLMULTI    :: ALLMULTI;

    IFF_MASTER      :: MASTER;

    IFF_SLAVE       :: SLAVE;

    IFF_MULTICAST   :: MULTICAST;

    IFF_PORTSEL     :: PORTSEL;

    IFF_AUTOMEDIA   :: AUTOMEDIA;

    IFF_DYNAMIC     :: DYNAMIC;
}

/* The ifaddr structure contains information about one address of an
interface.  They are maintained by the different address families,
are allocated and attached when an address is set, and are linked
together so all addresses for an interface can be located.  */
ifaddr :: struct {
    ifa_addr: sockaddr; /* Address of interface.  */
    ifa_ifu:  union {
        ifu_broadaddr: sockaddr;
        ifu_dstaddr:   sockaddr;
    };

    iface :: struct {}
    ifa_ifp:  *iface; /* Back-pointer to interface.  */
    ifa_next: *ifaddr; /* Next address for interface.  */
}

/* Device mapping structure. I'd just gone off and designed a
beautiful scheme using only loadable modules with arguments for
driver options and along come the PCMCIA people 8)

Ah well. The get() side of this is good for WDSETUP, and it'll be
handy for debugging things. The set side is fine for now and being
very small might be worth keeping for clean configuration.  */
ifmap :: struct {
    mem_start: u64;
    mem_end:   u64;
    base_addr: u16;
    irq:       u8;
    dma:       u8;
    port:      u8;
}

/* Interface request structure used for socket ioctl's.  All interface
ioctl's must have parameter definitions which begin with ifr_name.
The remainder may be interface specific.  */
ifreq :: struct {
    ifr_ifrn: union {
        ifrn_name: [16] u8; /* Interface name, e.g. "en0".  */
    };

    ifr_ifru: union {
        ifru_addr:      sockaddr;
        ifru_dstaddr:   sockaddr;
        ifru_broadaddr: sockaddr;
        ifru_netmask:   sockaddr;
        ifru_hwaddr:    sockaddr;
        ifru_flags:     s16;
        ifru_ivalue:    s32;
        ifru_mtu:       s32;
        ifru_map:       ifmap;
        ifru_slave:     [16] u8; /* Just fits the size */
        ifru_newname:   [16] u8;
        ifru_data:      *u8;
    };
}

/* Structure used in SIOCGIFCONF request.  Used to retrieve interface
configuration for machine (useful for programs which must know all
networks accessible).  */
ifconf :: struct {
    ifc_len:  s32; /* Size of buffer.  */
    ifc_ifcu: union {
        ifcu_buf: *u8;
        ifcu_req: *ifreq;
    };
}

/* Convert an interface name to an index, and vice versa.  */
if_nametoindex :: (__ifname: *u8) -> u32 #foreign libc;
if_indextoname :: (__ifindex: u32, __ifname: *u8) -> *u8 #foreign libc;

/* Return a list of all interfaces and their indices.  */
if_nameindex_ :: () -> *if_nameindex #foreign libc "if_nameindex";

/* Free the data returned from if_nameindex.  */
if_freenameindex :: (__ptr: *if_nameindex) -> void #foreign libc;

/* The `getifaddrs' function generates a linked list of these structures.
Each element of the list describes one network interface.  */
ifaddrs :: struct {
    ifa_next:    *ifaddrs; /* Pointer to the next structure.  */

    ifa_name:    *u8; /* Name of this network interface.  */
    ifa_flags:   u32; /* Flags as from SIOCGIFFLAGS ioctl.  */

    ifa_addr:    *sockaddr; /* Network address of this interface.  */
    ifa_netmask: *sockaddr; /* Netmask of this interface.  */
    ifa_ifu:     union {
        ifu_broadaddr: *sockaddr; /* Broadcast address of this interface. */
        ifu_dstaddr:   *sockaddr; /* Point-to-point destination address.  */
    };

    ifa_data:    *void; /* Address-specific data (may be unused).  */
}

/* Create a linked list of `struct ifaddrs' structures, one for each
network interface on the host machine.  If successful, store the
list in *IFAP and return 0.  On errors, return -1 and set `errno'.

The storage returned in *IFAP is allocated dynamically and can
only be properly freed by passing it to `freeifaddrs'.  */
getifaddrs :: (__ifap: **ifaddrs) -> s32 #foreign libc;

/* Reclaim the storage allocated by a previous `getifaddrs' call.  */
freeifaddrs :: (__ifa: *ifaddrs) -> void #foreign libc;

#scope_file

libc :: #library,system "libc";
