/*
Intial version 11/26/2003

*/
#pragma warning(disable: 4786)
#pragma warning(disable: 4996)

#include "wirelessinfo.h"
#include "..\..\Library\Export.h"	// Rainmeter's exported functions

/* The exported functions */
extern "C"
{
	__declspec( dllexport ) UINT Initialize(HMODULE instance, LPCTSTR iniFile, LPCTSTR section, UINT id);
	__declspec( dllexport ) LPCTSTR GetString(UINT id, UINT flags);
	__declspec( dllexport ) void Finalize(HMODULE instance, UINT id);
	__declspec( dllexport ) UINT Update(UINT ID);
	__declspec( dllexport ) UINT GetPluginVersion();
	__declspec( dllexport ) LPCTSTR GetPluginAuthor();
}

static std::map<UINT, TYPE> g_Types;
static std::map<UINT, UINT> g_Datas;
static std::map<UINT, UINT> g_Min;
static std::map<UINT, UINT> g_Max;

std::wstring ConvertToWide(LPCSTR str)
{
	std::wstring szWide;

	if (str && *str)
	{
		int strLen = (int)strlen(str) + 1;
		int bufLen = MultiByteToWideChar(CP_ACP, 0, str, strLen, NULL, 0);
		if (bufLen > 0)
		{
			WCHAR* wideSz = new WCHAR[bufLen];
			wideSz[0] = 0;
			MultiByteToWideChar(CP_ACP, 0, str, strLen, wideSz, bufLen);
			szWide = wideSz;
			delete [] wideSz;
		}
	}
	return szWide;
}

/* 
The following functions are modified from WRAPI in UCSD
http://ramp.ucsd.edu/pawn/wrapi/
*/
//BEGIN_MESSAGE_MAP(wirelessinfo, CWinApp)
//END_MESSAGE_MAP()

wirelessinfo::wirelessinfo()
{
	WCHAR	Buf[1024];
	DWORD	dwBytesWritten, i = 0;
	
	//WinExec("net start wirelessuio",SW_SHOW);
	m_hFileHandle = INVALID_HANDLE_VALUE;
	m_hRes = S_OK;
	m_dwBytesReturned =0;
	m_pNdisuioDevice = L"\\\\.\\\\Wirelessuio";
//	m_pNdisuioDevice = L"\\\\.\\\\ndisuio";
	pDeviceList=NULL;
	Items=0;
    id=0;
	openflag=0;
	m_hFileHandle = CreateFile(m_pNdisuioDevice,
		GENERIC_READ|GENERIC_WRITE,
		0,
		NULL,
		OPEN_EXISTING,
		FILE_ATTRIBUTE_NORMAL,
		(HANDLE) INVALID_HANDLE_VALUE);
	
	//Bind the file handle to the driver
	
	
	if (!DeviceIoControl(m_hFileHandle,
		IOCTL_NDISUIO_BIND_WAIT,
		NULL,
		0,
		NULL,
		0,
		&m_dwBytesReturned,
		NULL))
	{
		DEBUGP(L"IOCTL_NDISUIO_BIND_WAIT failed %02x", GetLastError());
		CloseHandle(m_hFileHandle);
		m_hFileHandle = INVALID_HANDLE_VALUE;
		return;
	}
	
	m_pQueryBinding = (PNDISUIO_QUERY_BINDING)Buf;
	pDeviceList = (NDIS_DEVICE *) malloc(NUM_DEVICES * sizeof(NDIS_DEVICE));
	
	for (m_pQueryBinding->BindingIndex = i;
	/* NOTHING */;
	m_pQueryBinding->BindingIndex = ++i)
	{
        if (DeviceIoControl(m_hFileHandle,
			IOCTL_NDISUIO_QUERY_BINDING,
			m_pQueryBinding,
			sizeof(NDISUIO_QUERY_BINDING),
			Buf,
			sizeof(Buf),
			&dwBytesWritten,
			NULL))
		{
			/* Get the device name in the list of bindings */
			
			pDeviceList[i].pDeviceName = (WCHAR *) malloc(m_pQueryBinding->DeviceNameLength);
			pDeviceList[i].pDeviceDescription = (WCHAR *) malloc(m_pQueryBinding->DeviceDescrLength);
			
			memcpy(pDeviceList[i].pDeviceName, (PUCHAR)m_pQueryBinding+m_pQueryBinding->DeviceNameOffset,
				m_pQueryBinding->DeviceNameLength);
			
			memcpy(pDeviceList[i].pDeviceDescription, (PUCHAR)m_pQueryBinding+m_pQueryBinding->DeviceDescrOffset,
				m_pQueryBinding->DeviceDescrLength);
			
			memset(Buf, 0, sizeof(Buf));
		}
		
		else
		{
			m_dwError = GetLastError();
			if (m_dwError != ERROR_NO_MORE_ITEMS)
			{
				DEBUGP(L"EnumerateDevices: terminated abnormally, error %d", m_dwError);
				hRes = E_FAIL;
			}
			break;
		}
	}
	
	Items = i + 1;
}


wirelessinfo::~wirelessinfo()
{
	if (m_hFileHandle)
	{
		CloseHandle(m_hFileHandle);
		m_hFileHandle = INVALID_HANDLE_VALUE;
	}
	
	if (pDeviceList!=NULL) 
	{
		for (int i = 0; i < Items; i++)
		{
			free(pDeviceList[i].pDeviceName);
			free(pDeviceList[i].pDeviceDescription);
		}
		
		free(pDeviceList);
	}
	
	//WinExec("net stop wirelessuio",SW_SHOW);
	
}


HRESULT wirelessinfo::OpenNdisDevice(WCHAR *pwDeviceName)
{
	WCHAR wNdisDeviceName[DEVICE_LENGTH] = {0};
	int wNameLength, i = 0;
	
	if (!pwDeviceName)
	{
		m_hRes = E_POINTER;
	}
	
	else
	{
		wNameLength = 0;
		
		for ( i = 0; i < DEVICE_LENGTH-1; i++ )
		{
			wNdisDeviceName[i] = pwDeviceName[i];
			wNameLength++;
		}
		
		wNdisDeviceName[i] = L'\0';
		
		if (!DeviceIoControl(m_hFileHandle,
			IOCTL_NDISUIO_OPEN_DEVICE,
			(LPVOID) &wNdisDeviceName[0],
			sizeof(WCHAR)*wNameLength,
			NULL,
			0,
			&m_dwBytesReturned,
			NULL))
		{
			m_dwError = GetLastError();
			DEBUGP(L"Could not open NDIS Device, error %d", m_dwError);
			m_hRes = E_FAIL;
		}
	}
	
	return m_hRes;
	
}

HRESULT wirelessinfo::GetSSId(UCHAR *pSSId)
{
	UCHAR						QueryBuffer[1024];
	PNDISUIO_QUERY_OID			pQueryOid;
	ULONG						lSSIdLength;
	
	if (!pSSId)
	{
		m_hRes = E_POINTER;
	}
	
	else
	{
		pQueryOid = (PNDISUIO_QUERY_OID) &QueryBuffer[0];
		pQueryOid->Oid = OID_802_11_SSID;
		
		if (DeviceIoControl(m_hFileHandle,
			IOCTL_NDISUIO_QUERY_OID_VALUE,
			(LPVOID) &QueryBuffer[0],
			sizeof(QueryBuffer),
			(LPVOID) &QueryBuffer[0],
			sizeof(QueryBuffer),
			&m_dwBytesReturned,
			NULL))
		{
//			DEBUGP(L"IOCTL SSID succeeded");
			lSSIdLength = ((PNDIS_802_11_SSID)(pQueryOid->Data))->SsidLength;
			memcpy(pSSId, ((PNDIS_802_11_SSID)(pQueryOid->Data))->Ssid, lSSIdLength);
		}
		
		else
		{
			DEBUGP(L"IOCTL SSID failed: %d", m_dwError);
			m_dwError = GetLastError();
		}
		
	}
	
	return m_hRes;
	
}

HRESULT wirelessinfo::GetAssociatedAP(MAC_ADDR mac_addr)
{
	UCHAR				QueryBuffer[1024];
	PNDISUIO_QUERY_OID	pQueryOid;
	int					i = 0;
	
	pQueryOid = (PNDISUIO_QUERY_OID) &QueryBuffer[0];
	pQueryOid->Oid = OID_802_11_BSSID;
	
	if (DeviceIoControl(m_hFileHandle,
		IOCTL_NDISUIO_QUERY_OID_VALUE,
		(LPVOID) &QueryBuffer[0],
		sizeof(QueryBuffer),
		(LPVOID) &QueryBuffer[0],
		sizeof(QueryBuffer),
		&m_dwBytesReturned,
		NULL))
	{
//		DEBUGP(L"IOCTL GET_BSSID succeeded");
		
		for ( i = 0; i < 6; i++ )
		{
			mac_addr[i] = pQueryOid->Data[i];
		}
	}
	
	else
	{
		m_dwError = GetLastError();
		DEBUGP(L"IOCTL GET_BSSID failed: %d", m_dwError);
		m_hRes = E_FAIL;
	}
	
	return m_hRes;
}

HRESULT wirelessinfo::GetNetworkTypeInUse(int *pnNetType)
{
	UCHAR					QueryBuffer[1024];
	PNDISUIO_QUERY_OID		pQueryOid;
	
	if (!pnNetType)
	{
		m_hRes = E_POINTER;
	}
	
	else
	{
		pQueryOid = (PNDISUIO_QUERY_OID)&QueryBuffer[0];
		pQueryOid->Oid = OID_802_11_NETWORK_TYPE_IN_USE;
		
		if (DeviceIoControl(m_hFileHandle,
			IOCTL_NDISUIO_QUERY_OID_VALUE,
			(LPVOID) &QueryBuffer[0],
			sizeof(QueryBuffer),
			(LPVOID) &QueryBuffer[0],
			sizeof(QueryBuffer),
			&m_dwBytesReturned,
			NULL))
		{
//			DEBUGP(L"IOCTL GET_NETWORK_TYPE_IN_USE succeeded");
			memcpy(pnNetType, &pQueryOid->Data[0], sizeof(NDIS_802_11_NETWORK_TYPE));
		}
		
		else
		{
			m_dwError = GetLastError();
			DEBUGP(L"IOCTL GET_NETWORK_TYPE_IN_USE failed: %d", m_dwError);
			m_hRes = E_FAIL;
		}
	}
	
	return m_hRes;
}

HRESULT wirelessinfo::GetSignalStrength(LONG * plRssi)
{
	UCHAR					QueryBuffer[1024];
	PNDISUIO_QUERY_OID		pQueryOid;
	
	if (!plRssi)
	{
		m_hRes = E_POINTER;
	}
	
	else
	{
		pQueryOid = (PNDISUIO_QUERY_OID)&QueryBuffer[0];
		pQueryOid->Oid = OID_802_11_RSSI;
		
		if (DeviceIoControl(m_hFileHandle,
			IOCTL_NDISUIO_QUERY_OID_VALUE,
			(LPVOID) &QueryBuffer[0],
			sizeof(QueryBuffer),
			(LPVOID) &QueryBuffer[0],
			sizeof(QueryBuffer),
			&m_dwBytesReturned,
			NULL))
		{
//			DEBUGP(L"IOCTL GET_RSSI succeeded");
			memcpy(plRssi, &pQueryOid->Data[0], sizeof(NDIS_802_11_RSSI));
		}
		
		else
		{
			m_dwError = GetLastError();
			DEBUGP(L"IOCTL GET_RSSI failed: %d", m_dwError);
			m_hRes = E_FAIL;
		}
	}
	
	return m_hRes;
}

HRESULT wirelessinfo::GetDesiredRates(NDIS_802_11_RATES bit_rates)
{
	UCHAR					QueryBuffer[1024];
	PNDISUIO_QUERY_OID		pQueryOid;
	int						i = 0;
	
	pQueryOid = (PNDISUIO_QUERY_OID)&QueryBuffer[0];
	pQueryOid->Oid = OID_802_11_DESIRED_RATES;
	
	if (DeviceIoControl(m_hFileHandle,
		IOCTL_NDISUIO_QUERY_OID_VALUE,
		(LPVOID) &QueryBuffer[0],
		sizeof(QueryBuffer),
		(LPVOID) &QueryBuffer[0],
		sizeof(QueryBuffer),
		&m_dwBytesReturned,
		NULL))
	{
//		DEBUGP(L"IOCTL GET_DESIRED_RATES succeeded");
		for ( i = 0; i < 8; i++ )
		{
			bit_rates[i] = pQueryOid->Data[i];
		}
	}
	
	else
	{
		m_dwError = GetLastError();
		DEBUGP(L"IOCTL GET_DESIRED_RATES failed: %d", m_dwError);
		m_hRes = E_FAIL;
	}
	
	return m_hRes;
}

HRESULT wirelessinfo::GetNetworkMode(int *pnNetworkMode)
{
	//infrestructure vs. ad-hoc mode
	
	UCHAR					QueryBuffer[1024];
	PNDISUIO_QUERY_OID		pQueryOid;
	
	if (!pnNetworkMode)
	{
		m_hRes = E_POINTER;
	}
	
	else
	{
		pQueryOid = (PNDISUIO_QUERY_OID) &QueryBuffer[0];
		pQueryOid->Oid = OID_802_11_INFRASTRUCTURE_MODE;
		
		if (DeviceIoControl(m_hFileHandle,
			IOCTL_NDISUIO_QUERY_OID_VALUE,
			(LPVOID) &QueryBuffer[0],
			sizeof(QueryBuffer),
			(LPVOID) &QueryBuffer[0],
			sizeof(QueryBuffer),
			&m_dwBytesReturned,
			NULL))
		{
			
//			DEBUGP(L"IOCTL GET_NETWORK_MODE succeeded");
			memcpy(pnNetworkMode, &pQueryOid->Data[0], sizeof(NDIS_802_11_NETWORK_INFRASTRUCTURE));
		}
		
		else
		{
			m_dwError = GetLastError();
			DEBUGP(L"IOCTL GET_NETWORK_MODE failed: %d", m_dwError);
			m_hRes = E_FAIL;
		}
	}
	
	return m_hRes;
}

HRESULT wirelessinfo::GetAuthMode(int *pnAuthMode)
{
	UCHAR					QueryBuffer[1024];
	PNDISUIO_QUERY_OID		pQueryOid;
	
	if (!pnAuthMode)
	{
		m_hRes = E_POINTER;
	}
	
	else
	{
		pQueryOid = (PNDISUIO_QUERY_OID) &QueryBuffer[0];
		pQueryOid->Oid = OID_802_11_AUTHENTICATION_MODE;
		
		if (DeviceIoControl(m_hFileHandle,
			IOCTL_NDISUIO_QUERY_OID_VALUE,
			(LPVOID) &QueryBuffer[0],
			sizeof(QueryBuffer),
			(LPVOID) &QueryBuffer[0],
			sizeof(QueryBuffer),
			&m_dwBytesReturned,
			NULL))
		{
			
//			DEBUGP(L"IOCTL GET_AUTH_MODE succeeded");
			memcpy(pnAuthMode, &pQueryOid->Data[0], sizeof(NDIS_802_11_AUTHENTICATION_MODE));
		}
		
		else
		{
			m_dwError = GetLastError();
			DEBUGP(L"IOCTL GET_AUTH_MODE failed: %d", m_dwError);
			m_hRes = E_FAIL;
		}
	}
	
	return m_hRes;
}

HRESULT wirelessinfo::GetAPList(AP_DATA **ppAP_data, long *plItems)
{
	UCHAR						QueryBuffer[1024];
	PNDISUIO_QUERY_OID			pQueryOid;
	PNDISUIO_SET_OID			pSetOid;
	PNDIS_802_11_BSSID_LIST		pBssid_List;
	ULONG						i = 0;
	int							j = 0;
	
	if (!ppAP_data)
	{
		m_hRes = E_POINTER;
	}
	
	else
	{
		pSetOid = (PNDISUIO_SET_OID) &QueryBuffer[0];
		pSetOid->Oid = OID_802_11_BSSID_LIST_SCAN;
		
		if (!DeviceIoControl(m_hFileHandle,
			IOCTL_NDISUIO_SET_OID_VALUE,
			(LPVOID) &QueryBuffer[0],
			sizeof(QueryBuffer),
			(LPVOID) &QueryBuffer[0],
			0,
			&m_dwBytesReturned,
			NULL))
		{
			m_dwError = GetLastError();
			DEBUGP(L"IOCTL SET BSSID_LIST_SCAN failed: %d", m_dwError);
		}
		
		pQueryOid = (PNDISUIO_QUERY_OID) &QueryBuffer[0];
		pQueryOid->Oid = OID_802_11_BSSID_LIST;
		
		if (DeviceIoControl(m_hFileHandle,
			IOCTL_NDISUIO_QUERY_OID_VALUE,
			(LPVOID) &QueryBuffer[0],
			sizeof(QueryBuffer),
			(LPVOID) &QueryBuffer[0],
			sizeof(QueryBuffer),
			&m_dwBytesReturned,
			NULL))
		{
//			DEBUGP(L"IOCTL BSSID_LIST succeeded");
			
			pBssid_List = (PNDIS_802_11_BSSID_LIST)pQueryOid->Data;
			*plItems = pBssid_List->NumberOfItems;
			
			*ppAP_data = (AP_DATA *) calloc(pBssid_List->NumberOfItems, sizeof(AP_DATA));
			
			for ( i = 0; i < pBssid_List->NumberOfItems; i++ )
			{
				for ( j = 0; j < 6; j++ )
				{
					(*ppAP_data)[i].mac_addr[j] = (pBssid_List->Bssid[i]).MacAddress[j];
				}
				
				(*ppAP_data)[i].Rssi = (pBssid_List->Bssid[i]).Rssi;
			}
		}
		
		else
		{
			m_dwError = GetLastError();
			DEBUGP(L"IOCTL BSSID_LIST failed: %d", m_dwError);
		}
	}
	
	return m_hRes;
}

/* 
The above functions are modified from WRAPI in UCSD
http://ramp.ucsd.edu/pawn/wrapi/
*/

HRESULT wirelessinfo::GetStatus(ULONG *status)
{
	UCHAR					QueryBuffer[1024];
	PNDISUIO_QUERY_OID		pQueryOid;
	
	if (!status)
	{
		m_hRes = E_POINTER;
	}
	
	else
	{
		pQueryOid = (PNDISUIO_QUERY_OID) &QueryBuffer[0];
		pQueryOid->Oid = OID_GEN_MEDIA_CONNECT_STATUS;
		//OID_802_11_AUTHENTICATION_MODE;
		
		if (DeviceIoControl(m_hFileHandle,
			IOCTL_NDISUIO_QUERY_OID_VALUE,
			(LPVOID) &QueryBuffer[0],
			sizeof(QueryBuffer),
			(LPVOID) &QueryBuffer[0],
			sizeof(QueryBuffer),
			&m_dwBytesReturned,
			NULL))
		{
			
//			DEBUGP(L"IOCTL GET_connect_status succeeded");
			memcpy(status, &pQueryOid->Data[0], sizeof(ULONG));
		}
		
		else
		{
			m_dwError = GetLastError();
			DEBUGP(L"IOCTL GET_connect_status failed: %d", m_dwError);
			m_hRes = E_FAIL;
		}
	}
	
	return m_hRes;
}

HRESULT wirelessinfo::GetWEP(ULONG *status)
{
	UCHAR					QueryBuffer[1024];
	PNDISUIO_QUERY_OID		pQueryOid;
	
	if (!status)
	{
		m_hRes = E_POINTER;
	}
	
	else
	{
		pQueryOid = (PNDISUIO_QUERY_OID) &QueryBuffer[0];
		pQueryOid->Oid = OID_802_11_WEP_STATUS;
		//OID_GEN_MEDIA_CONNECT_STATUS;
		//OID_802_11_AUTHENTICATION_MODE;
		
		if (DeviceIoControl(m_hFileHandle,
			IOCTL_NDISUIO_QUERY_OID_VALUE,
			(LPVOID) &QueryBuffer[0],
			sizeof(QueryBuffer),
			(LPVOID) &QueryBuffer[0],
			sizeof(QueryBuffer),
			&m_dwBytesReturned,
			NULL))
		{
			
//			DEBUGP(L"IOCTL GET_connect_status succeeded");
			memcpy(status, &pQueryOid->Data[0], sizeof(ULONG));
		}
		
		else
		{
			m_dwError = GetLastError();
			DEBUGP(L"IOCTL GET_connect_status failed: %d", m_dwError);
			m_hRes = E_FAIL;
		}
	}
	
	return m_hRes;
}

HRESULT wirelessinfo::GetSpeed(ULONG *speed)
{
	UCHAR					QueryBuffer[1024];
	PNDISUIO_QUERY_OID		pQueryOid;
	
	if (!speed)
	{
		m_hRes = E_POINTER;
	}
	
	else
	{
		pQueryOid = (PNDISUIO_QUERY_OID) &QueryBuffer[0];
		pQueryOid->Oid = OID_GEN_LINK_SPEED;
		//OID_802_11_AUTHENTICATION_MODE;
		
		if (DeviceIoControl(m_hFileHandle,
			IOCTL_NDISUIO_QUERY_OID_VALUE,
			(LPVOID) &QueryBuffer[0],
			sizeof(QueryBuffer),
			(LPVOID) &QueryBuffer[0],
			sizeof(QueryBuffer),
			&m_dwBytesReturned,
			NULL))
		{
			
//			DEBUGP(L"IOCTL GET_connect_speed succeeded");
			memcpy(speed, &pQueryOid->Data[0], sizeof(ULONG));
		}
		
		else
		{
			m_dwError = GetLastError();
			DEBUGP(L"IOCTL GET_connect_speed failed: %d", m_dwError);
			m_hRes = E_FAIL;
		}
	}
	
	return m_hRes;
}


wirelessinfo *myinfo;

//initialization function

UINT Initialize(HMODULE instance, LPCTSTR iniFile, LPCTSTR section, UINT id)
{
	/* Read our own settings from the ini-file */
	LPCTSTR type = ReadConfigString(section, L"WirelessInfoType", L"");
	int ret = 1;
	
	if (type)
	{
		if (_wcsicmp(L"STATUS", type) == 0)
		{
			g_Types[id] = STATUS;
		} 
		else if (_wcsicmp(L"CONNECTION", type) == 0)
		{
			g_Types[id] = CONNECTION;
		} 
		else if (_wcsicmp(L"SSID", type) == 0)
		{
			g_Types[id] = SSID;
			ret = 0;
		} 
		else if (_wcsicmp(L"BANDWIDTH", type) == 0)
		{
			g_Types[id] = BANDWIDTH;
			ret = 0;
		} 
		else if (_wcsicmp(L"STRENGTH", type) == 0)
		{
			g_Types[id] = STRENGTH;
			ret = 100;
		} 
		else if (_wcsicmp(L"WEP",type)==0)
		{
			g_Types[id] = WEP;
		}
		else if (_wcsicmp(L"IP_ADDRESS", type) == 0)
		{
			g_Types[id] = IP_ADDRESS;
		} 
		else if (_wcsicmp(L"EXTERNAL_IP_ADDRESS", type) == 0)
		{
			g_Types[id] = EXTERNAL_IP_ADDRESS;
		} 
		else
		{
			std::wstring error = L"WirelessInfoType=";
			error += type;
			error += L" is not valid in measure [";
			error += section;
			error += L"].";
			MessageBox(NULL, error.c_str(), L"Rainmeter", MB_OK | MB_TOPMOST | MB_ICONEXCLAMATION);
		}
	}
	
	LPCTSTR data = ReadConfigString(section, L"WirelessInfoData", L"0");
	if (data)
	{
		g_Datas[id] = _wtoi(data);
	}
	
	data = ReadConfigString(section, L"WirelessMin", L"200");
	if (data)
	{
		g_Min[id] = _wtoi(data);
	}
	
	data = ReadConfigString(section, L"WirelessMax", L"20");
	if (data)
	{
		g_Max[id] = _wtoi(data);
	}
	
	return ret;
}

void getwirelessinfo(UINT id, UINT type, WCHAR *buf,UINT Min, UINT Max)
{
	//	NDIS_DEVICE		*pDeviceList = NULL;
	HRESULT				hRes;	
	long				lItems = 0;
	long				lNumItems = 0;
	UCHAR				Ssid[32] = {0};
	ULONG				lRTSThresh = 0; 
	ULONG               status=0;
	ULONG               speed=0;
	MAC_ADDR			addr = {0};
	int                 networkmode;
	long                rssi;
    AP_DATA				*pAP_list = NULL;

	//	hRes = myinfo.EnumerateDevices(&pDeviceList, &lItems);
    myinfo= new wirelessinfo;
	if (myinfo->hRes==E_FAIL) {delete myinfo;return;}
	
	if (myinfo->Items<(long)id+1) {delete myinfo;return;}
	
	if (myinfo->openflag==0)
	{
		myinfo->openflag++;
		myinfo->id=id;
		hRes = myinfo->OpenNdisDevice(myinfo->pDeviceList[id].pDeviceName);
		if (hRes==E_FAIL) {delete myinfo; return;}
	}
	
	if (id!=myinfo->id) {delete myinfo; return;}
	/*
	STATUS : Is there a wireless link active
	: Will return a 0 (no link) or 1 (link)
	CONNECTION : Access Point or Adhoc?
	: Will return 0 (adhoc) or 1 (access point)
	SSID : The SSID of the connection (not MAC address, but the string)
	: Will return a string
	BANDWIDTH : Current bandwidth (11mbps/5.5/2/1)
	: Will return a number
	STRENGTH : The link quality in percent
	: Will return a number between 0-100
	WEP : Is any encryption being used?
	: Will return a 0 (none) or 1 (encryption)
	*/
	
	switch (type)
	{
	case STATUS:
		if (myinfo->GetStatus(&status)!=E_FAIL)
		{
			if (status==NdisMediaStateConnected)
			{
				lstrcpy(buf,L"1"); //connected;
			}
			else
			{
				lstrcpy(buf,L"0"); //not connected;
			}
		}
		break;
		
	case CONNECTION:
		if (myinfo->GetNetworkMode(&networkmode)!=E_FAIL)
		{
			if (networkmode==Ndis802_11Infrastructure)
			{
				lstrcpy(buf,L"1");
			}
			else
			{
				lstrcpy(buf,L"0");
			}
		}
		break;
		
	case SSID:
		if (myinfo->GetSSId(Ssid)!=E_FAIL)
		{
			std::wstring strSSID = ConvertToWide((const char*)Ssid);
			wcscpy(buf, strSSID.c_str());
		}
		break;
		
	case BANDWIDTH:
		if (myinfo->GetSpeed(&speed)!=E_FAIL)
		{
			double bw = (1.0 * speed) / 10000.0;
			swprintf(buf,L"%.1f",bw);
		}
		break;
		
	case STRENGTH:
		
		if (myinfo->GetSignalStrength(&rssi)!=E_FAIL)
		{
			int temp=(rssi+Min)*100/(Min-Max);
			if (temp<0) temp=0;
			if (temp>100) temp=100;
			wsprintf(buf,L"%d",temp);
		}
		break;
		
	case WEP:
		if (myinfo->GetWEP(&status)!=E_FAIL)
		{
			if (status==Ndis802_11WEPEnabled)
			{
				lstrcpy(buf,L"1");//WEP
			}
			else
			{
				lstrcpy(buf,L"0");
			}
		}
		break;
		
	default:
		break;
	}
	delete myinfo;
}

UINT Update(UINT ID)
{
	UINT id,type,Min,Max;
	HRESULT				hRes;	
	long				lItems = 0;
	long				lNumItems = 0;
	UCHAR				Ssid[32] = {0};
	ULONG				lRTSThresh = 0; 
	ULONG               status=0;
	ULONG               speed=0;
	MAC_ADDR			addr = {0};
	int                 networkmode;
	long                rssi;
	std::map<UINT, TYPE>::iterator typeIter = g_Types.find(ID);
	std::map<UINT, UINT>::iterator dataIter = g_Datas.find(ID);
	std::map<UINT, UINT>::iterator MinIter = g_Min.find(ID);
	std::map<UINT, UINT>::iterator MaxIter = g_Max.find(ID);
	AP_DATA				*pAP_list = NULL;
	
	if(typeIter == g_Types.end()) return 0;
	if(dataIter == g_Datas.end())
	{
		id = 0;
	}
	else
	{
		id = (*dataIter).second;
	}
	
	if(MinIter == g_Min.end())
	{
		Min = 0;
	}
	else
	{
		Min = (*MinIter).second;
	}
	
	if(MaxIter == g_Max.end())
	{
		Max = 0;
	}
	else
	{
		Max = (*MaxIter).second;
	}
	
    type=(*typeIter).second;
	
	myinfo=new wirelessinfo;
	
	if (myinfo->hRes==E_FAIL) {delete myinfo; return 0;}
	
	if (myinfo->Items<(long)id+1) {delete myinfo; return 0;}
	
	if (myinfo->openflag==0)
	{
		myinfo->openflag++;
		myinfo->id=id;
		hRes = myinfo->OpenNdisDevice(myinfo->pDeviceList[id].pDeviceName);
		if (hRes==E_FAIL) {delete myinfo; return 0;}
	}
	
	if (id!=myinfo->id) {delete myinfo; return 0;}
	switch (type)
	{
	case STATUS:
		if (myinfo->GetStatus(&status)!=E_FAIL)
		{
			if (status==NdisMediaStateConnected)
			{
				delete myinfo;
				return 1; //connected;
			}
			else
			{
				delete myinfo;
				return 0; //not connected;
			}
		}
		break;
		
	case CONNECTION:
		if (myinfo->GetNetworkMode(&networkmode)!=E_FAIL)
		{
			if (networkmode==Ndis802_11Infrastructure)
			{
				delete myinfo;
				return 1;
			}
			else
			{
				delete myinfo;
				return 0;
			}
		}
		break;
		
	case SSID:
		if (myinfo->GetSSId(Ssid)!=E_FAIL)
		{
			//sprintf(buf,Ssid);
			//memcpy(buf,Ssid,32);
			delete myinfo;
			return 0;
		}
		break;
		
	case BANDWIDTH:
		//if (myinfo.GetDesiredRates(
		if (myinfo->GetSpeed(&speed)!=E_FAIL)
		{
			delete myinfo;
			return speed*100;
		}
		break;
		
	case STRENGTH:
		if (myinfo->GetSignalStrength(&rssi)!=E_FAIL)
		{
			delete myinfo;
			int temp=(rssi+Min)*100/(Min-Max);
			if (temp<0) temp=0;
			if (temp>100) temp=100;
			return(temp);
		}
		break;
		
	case WEP:
		if (myinfo->GetWEP(&status)!=E_FAIL)
		{
			if (status==Ndis802_11WEPEnabled)
			{
				//strcpy(buf,"1");//WEP
				delete myinfo;
				return 1;
			}
			else
			{
				//strcpy(buf,"0");
				delete myinfo;
				return 0;
				
			}
		}
		break;
		
	default:
		break;
	}
	delete myinfo;
	return 0;
}

LPCTSTR GetString(UINT id, UINT flags) 
{
	static WCHAR buffer[4096];
	UINT data,Min,Max;
	DWORD len = 4095;
	std::map<UINT, TYPE>::iterator typeIter = g_Types.find(id);
	std::map<UINT, UINT>::iterator dataIter = g_Datas.find(id);
	std::map<UINT, UINT>::iterator MinIter = g_Min.find(id);
	std::map<UINT, UINT>::iterator MaxIter = g_Max.find(id);
	
	if(typeIter == g_Types.end()) return NULL;
	if(dataIter == g_Datas.end())
	{
		data = 0;
	}
	else
	{
		data = (*dataIter).second;
	}
	
	if(MinIter == g_Min.end())
	{
		Min = 0;
	}
	else
	{
		Min = (*MinIter).second;
	}
	
	if(MaxIter == g_Max.end())
	{
		Max = 0;
	}
	else
	{
		Max = (*MaxIter).second;
	}
	
    buffer[0]='\0';
	//	sprintf(buffer,"status OK %d %d",(*typeIter).second, data );
	
	getwirelessinfo(data,(*typeIter).second,buffer,Min,Max);
	
	if (buffer[0]!='\0') return buffer;
	
	return NULL;
}

void Finalize(HMODULE instance, UINT id)
{
	std::map<UINT, TYPE>::iterator i1 = g_Types.find(id);
	if (i1 != g_Types.end())
	{
		g_Types.erase(i1);
	}
	
	std::map<UINT, UINT>::iterator i2 = g_Datas.find(id);
	if (i2 != g_Datas.end())
	{
		g_Datas.erase(i2);
	}
	
	std::map<UINT, UINT>::iterator i3 = g_Min.find(id);
	if (i3 != g_Min.end())
	{
		g_Min.erase(i3);
	}
	
	std::map<UINT, UINT>::iterator i4 = g_Max.find(id);
	if (i4 != g_Max.end())
	{
		g_Max.erase(i4);
	}
}

void DebugLog(const WCHAR* format, ... )
{
	WCHAR buffer[4096];
    va_list args;
    va_start( args, format );
    _vsnwprintf( buffer, 4096, format, args );
	LSLog(LOG_DEBUG, L"Rainmeter", buffer);
	va_end(args);
};

UINT GetPluginVersion()
{
	return 1004;
}

LPCTSTR GetPluginAuthor()
{
	return L"";
}