#include <string>
#include <map>
#include <windows.h>
#include <math.h>
#include <Iphlpapi.h>

#include <winioctl.h>
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <ctype.h>
#include <malloc.h>
#include <winerror.h>
#include <winsock.h>
#include <ntddndis.h>
#include "nuiouser.h"

#ifndef NDIS_STATUS
#define NDIS_STATUS     ULONG
#endif

#ifndef MAC_ADDR_LEN
#define MAC_ADDR_LEN                    6
#endif

#define MAX_NDIS_DEVICE_NAME_LEN        256
#define NUM_DEVICES						4
#define DEVICE_LENGTH					47

typedef unsigned char	u8;
typedef u8				MAC_ADDR[6];
typedef UCHAR			NDIS_802_11_RATES[8];
typedef LONG			SIG_STRENGTH;

enum TYPE
{
	STATUS,
	CONNECTION,
	SSID,
	BANDWIDTH,
	STRENGTH,
	WEP,
	IP_ADDRESS,
	EXTERNAL_IP_ADDRESS,
};

typedef struct NDIS_DEVICE
{
	WCHAR *pDeviceName;
	WCHAR *pDeviceDescription;

} NDIS_DEVICE;

typedef struct AP_DATA
{
	MAC_ADDR mac_addr;
	SIG_STRENGTH Rssi;
} AP_DATA;

typedef struct DOT_11_STATS
{
    ULONG Length;
	LARGE_INTEGER TransmittedFragmentCount;
	LARGE_INTEGER MulticastTransmittedFrameCount;
	LARGE_INTEGER FailedCount;
	LARGE_INTEGER RetryCount;
	LARGE_INTEGER MultipleRetryCount;
	LARGE_INTEGER RTSSuccessCount;
	LARGE_INTEGER RTSFailureCount;
	LARGE_INTEGER ACKFailureCount;
	LARGE_INTEGER FrameDuplicateCount;
	LARGE_INTEGER ReceivedFragmentCount;
	LARGE_INTEGER MulticastReceivedFrameCount;
	LARGE_INTEGER FCSErrorCount;
} DOT_11_STATS, *PDOT_11_STATS;

typedef struct DOT_11_CONFIGURATION
{
	ULONG							Length;
	ULONG							BeaconPeriod;
	ULONG							ATIMWindow;
	ULONG							DSConfig;
	NDIS_802_11_CONFIGURATION_FH	FHConfig;
} DOT_11_CONFIGURATION, *PDOT_11_CONFIGURATION;

void DebugLog(const WCHAR* format, ... );
#define DEBUGP    DebugLog

class wirelessinfo//: public CWinApp
{
public:
	wirelessinfo();
	~wirelessinfo();

//	HRESULT EnumerateDevices(NDIS_DEVICE **ppDeviceList, long *plItems);
	HRESULT OpenNdisDevice(WCHAR * pwDeviceName);
	HRESULT GetAssociatedAP(MAC_ADDR mac_addr);
	HRESULT GetSSId(UCHAR *pSSId);
	HRESULT GetNetworkTypeInUse(int *pnNetType);
	HRESULT GetSignalStrength(LONG *plRssi);
	HRESULT GetDesiredRates(NDIS_802_11_RATES bit_rates);
	HRESULT GetNetworkMode(int *pnNetworkMode);
	HRESULT GetAuthMode(int *pnAuthMode);
	HRESULT GetStatus(ULONG *status);
	HRESULT GetSpeed(ULONG *speed);
	HRESULT GetWEP(ULONG *status);
	HRESULT wirelessinfo::GetAPList(AP_DATA **ppAP_data, long *plItems);

//member variables
private:

	HRESULT					m_hRes;
	DWORD					m_dwError;
	HANDLE					m_hFileHandle;
	WCHAR*					m_pNdisuioDevice;
	DWORD					m_dwBytesReturned;
	PNDISUIO_QUERY_BINDING	m_pQueryBinding;
	

//functions
private:	
	HRESULT ProcessBSSIObject();

public:
	HRESULT hRes;
	NDIS_DEVICE *pDeviceList;
	long Items;
	UINT   id;
	UINT   openflag;
	//virtual BOOL InitInstance();
	
	//DECLARE_MESSAGE_MAP()
};

