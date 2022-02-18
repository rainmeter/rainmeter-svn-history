/*
  Copyright (C) 2005 Kimmo Pekkola

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/


#pragma warning(disable: 4786)
#pragma warning(disable: 4996)

#include <windows.h>
#include <math.h>
#include <string>
#include <map>
#include "..\..\Library\Export.h"	// Rainmeter's exported functions

/* The exported functions */
extern "C"
{
__declspec( dllexport ) UINT Initialize(HMODULE instance, LPCTSTR iniFile, LPCTSTR section, UINT id);
__declspec( dllexport ) void Finalize(HMODULE instance, UINT id);
__declspec( dllexport ) double Update2(UINT id);
__declspec( dllexport ) UINT GetPluginVersion();
__declspec( dllexport ) LPCTSTR GetPluginAuthor();
}

#define NrTemperature 32
#define NrVoltage 16
#define NrFan 16
#define NrCPU 4

//    enum Bus
#define BusType     char
#define ISA         0
#define SMBus       1
#define VIA686Bus   2
#define DirectIO    3

//    enum SMB
#define SMBType         char
#define smtSMBIntel     0
#define smtSMBAMD       1
#define smtSMBALi       2
#define smtSMBNForce    3
#define smtSMBSIS       4

// enum Sensor Types
#define SensorType      char
#define stUnknown       0
#define stTemperature   1
#define stVoltage       2
#define stFan           3
#define stMhz           4
#define stPercentage    5    

typedef struct {
    SensorType  iType;          // type of sensor
    int         Count;          // number of sensor for that type
} SharedIndex;

typedef struct {
    SensorType ssType;          // type of sensor
    unsigned char ssName[12];   // name of sensor
    char sspadding1[3];         // padding of 3 byte
    double ssCurrent;           // current value
    double ssLow;               // lowest readout
    double ssHigh;              // highest readout
    long ssCount;               // total number of readout
    char sspadding2[4];         // padding of 4 byte
    long double ssTotal;        // total amout of all readouts
    char sspadding3[6];         // padding of 6 byte
    double ssAlarm1;            // temp & fan: high alarm; voltage: % off;
    double ssAlarm2;            // temp: low alarm
} SharedSensor;

typedef struct {
    short siSMB_Base;            // SMBus base address
    BusType siSMB_Type;         // SMBus/Isa bus used to access chip
    SMBType siSMB_Code;         // SMBus sub type, Intel, AMD or ALi
    char siSMB_Addr;            // Address of sensor chip on SMBus
    unsigned char siSMB_Name[41];        // Nice name for SMBus
    short siISA_Base;            // ISA base address of sensor chip on ISA
    int siChipType;             // Chip nr, connects with Chipinfo.ini
    char siVoltageSubType;      // Subvoltage option selected
} SharedInfo;

typedef struct {
    double sdVersion;           // version number (example: 51090)
    SharedIndex sdIndex[10];     // Sensor index
    SharedSensor sdSensor[100];  // sensor info
    SharedInfo sdInfo;          // misc. info
    unsigned char sdStart[41];           // start time
    unsigned char sdCurrent[41];         // current time
    unsigned char sdPath[256];           // MBM path
} SharedData;

bool ReadSharedData(SensorType type, UINT number, double* value);

static std::map<UINT, SensorType> g_Types;
static std::map<UINT, UINT> g_Numbers;

/*
  This function is called when the measure is initialized.
  The function must return the maximum value that can be measured. 
  The return value can also be 0, which means that Rainmeter will
  track the maximum value automatically. The parameters for this
  function are:

  instance  The instance of this DLL
  iniFile   The name of the ini-file (usually Rainmeter.ini)
  section   The name of the section in the ini-file for this measure
  id        The identifier for the measure. This is used to identify the measures that use the same plugin.
*/
UINT Initialize(HMODULE instance, LPCTSTR iniFile, LPCTSTR section, UINT id)
{
	/* Read our own settings from the ini-file */
	LPCTSTR type = ReadConfigString(section, L"MBM5Type", L"TEMPERATURE");
	if (type)
	{
		if (_wcsicmp(L"TEMPERATURE", type) == 0)
		{
			g_Types[id] = stTemperature;
		} 
		else if (_wcsicmp(L"FAN", type) == 0)
		{
			g_Types[id] = stFan;
		} 
		else if (_wcsicmp(L"VOLTAGE", type) == 0)
		{
			g_Types[id] = stVoltage;
		} 
		else if (_wcsicmp(L"CPU", type) == 0)
		{
			g_Types[id] = stPercentage;
		} 
		else if (_wcsicmp(L"MHZ", type) == 0)
		{
			g_Types[id] = stMhz;
		} 
		else
		{
			std::wstring error = L"MBM5Type=";
			error += type;
			error += L" is not valid in measure [";
			error += section;
			error += L"].";
			MessageBox(NULL, error.c_str(), L"Rainmeter", MB_OK | MB_TOPMOST | MB_ICONEXCLAMATION);
		}
	}
	
	LPCTSTR data = ReadConfigString(section, L"MBM5Number", L"0");
	if (data)
	{
		g_Numbers[id] = _wtoi(data);
	}
	
	int maxVal = 0;
	data = ReadConfigString(section, L"MBM5MaxValue", L"0");
	if (data)
	{
		maxVal = _wtoi(data);
	}

	return maxVal;
}

/*
This function is called when new value should be measured.
The function returns the new value.
*/
double Update2(UINT id)
{
	double value = 0; 
	
	std::map<UINT, SensorType>::iterator type = g_Types.find(id);
	std::map<UINT, UINT>::iterator number = g_Numbers.find(id);
	
	if(type == g_Types.end() || number == g_Numbers.end())
	{
		return 0;		// No id in the map. How this can be ????
	}
	
	if (ReadSharedData((*type).second, (*number).second, &value))
	{
		return value;
	}
	
	return 0;
}

/*
  If the measure needs to free resources before quitting.
  The plugin can export Finalize function, which is called
  when Rainmeter quits (or refreshes).
*/
void Finalize(HMODULE instance, UINT id)
{
	std::map<UINT, SensorType>::iterator i1 = g_Types.find(id);
	if (i1 != g_Types.end())
	{
		g_Types.erase(i1);
	}

	std::map<UINT, UINT>::iterator i2 = g_Numbers.find(id);
	if (i2 != g_Numbers.end())
	{
		g_Numbers.erase(i2);
	}
}

/*
  Get the data from MBM5's shared memory.
*/
bool ReadSharedData(SensorType type, UINT number, double* value)
{
	SharedData* ptr;
	HANDLE hSData;
	int i;
	
	hSData=OpenFileMapping(FILE_MAP_READ, FALSE, L"$M$B$M$5$S$D$");
	if (hSData==0) return false;
	
	ptr = (SharedData*)MapViewOfFile(hSData, FILE_MAP_READ, 0, 0, 0);
	if (ptr == 0)
	{
		CloseHandle(hSData);
		return false;
	}
	
	// Find the correct sensor
	int startIndex = 0;
	UINT size = 0;
	for (i = 0; i < 5; i++) 
	{
		if (type == ptr->sdIndex[i].iType)
		{
			// This is the one we're looking for
			size = ptr->sdIndex[i].Count;
			break;
		}

		// Not the one, let's skip to the next
		size = ptr->sdIndex[i].Count;
		startIndex += size;
	}

	if (number < size)
	{
		double val = ptr->sdSensor[startIndex + number].ssCurrent;
		double lo = ptr->sdSensor[startIndex + number].ssLow;
		double hi = ptr->sdSensor[startIndex + number].ssHigh;

        if (type == stMhz) 
        {
            *value = val;
        }
        else
        {
		    // Put the value between min and max if it's not (this clears the 255.0 values)
		    val = min(hi, val);
		    val = max(lo, val);

		    *value = (val * 1000);
    	}
	}
	else
	{
		// The given number is greater than the size of sensors
		return false;
	}
	
	UnmapViewOfFile(ptr);
	CloseHandle(hSData);
	
	return true;
}

UINT GetPluginVersion()
{
	return 1003;
}

LPCTSTR GetPluginAuthor()
{
	return L"Rainy (rainy@iki.fi)";
}