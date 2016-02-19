//
//  SystemServices.h
//  SystemServicesDemo
//
//  Created by Shmoopi LLC on 9/15/12.
//  Copyright (c) 2012 Shmoopi LLC. All rights reserved.
//

#import "SSAccelerometerInfo.h"
#import "SSAccessoryInfo.h"
#import "SSApplicationInfo.h"
#import "SSBatteryInfo.h"
#import "SSCarrierInfo.h"
#import "SSDiskInfo.h"
#import "SSHardwareInfo.h"
#import "SSJailbreakCheck.h"
#import "SSLocalizationInfo.h"
#import "SSMemoryInfo.h"
#import "SSNetworkInfo.h"
#import "SSProcessInfo.h"
#import "SSProcessorInfo.h"
#import "SSUUID.h"

/* New Hardware Stuff, new accelerometer stuff, localization stuff, and application info */

@interface SystemServices : NSObject

// Shared Manager
+ (id)sharedServices;

// Parent ID for a certain PID
- (int)parentPIDForProcess:(int)pid;

// Properties

/* All System Information in Dictionary Format */
@property (nonatomic, readonly) NSDictionary *allSystemInformation;

/* Hardware Information */

// System Uptime (dd hh mm)
@property (nonatomic, readonly) NSString *systemsUptime;

// Model of Device
@property (nonatomic, readonly) NSString *deviceModel;

// Device Name
@property (nonatomic, readonly) NSString *deviceName;

// System Name
@property (nonatomic, readonly) NSString *systemName;

// System Version
@property (nonatomic, readonly) NSString *systemsVersion;

// System Device Type (Not Formatted = iPhone1,0)
@property (nonatomic, readonly) NSString *systemDeviceTypeNotFormatted;

// System Device Type (Formatted = iPhone 1)
@property (nonatomic, readonly) NSString *systemDeviceTypeFormatted;

// Get the Screen Width (X)
@property (nonatomic, readonly) NSInteger screenWidth;

// Get the Screen Height (Y)
@property (nonatomic, readonly) NSInteger screenHeight;

// Get the Screen Brightness
@property (nonatomic, readonly) float screenBrightness;

// Multitasking enabled?
@property (nonatomic, readonly) BOOL multitaskingEnabled;

// Proximity sensor enabled?
@property (nonatomic, readonly) BOOL proximitySensorEnabled;

// Debugger Attached?
@property (nonatomic, readonly) BOOL debuggerAttached;

// Plugged In?
@property (nonatomic, readonly) BOOL pluggedIn;

/* Jailbreak Check */

// Jailbroken?
@property (nonatomic, readonly) int jailbroken;

/* Processor Information */

// Number of processors
@property (nonatomic, readonly) NSInteger numberProcessors;

// Number of Active Processors
@property (nonatomic, readonly) NSInteger numberActiveProcessors;

// Processor Speed in MHz
@property (nonatomic, readonly) NSInteger processorSpeed;

// Processor Bus Speed in MHz
@property (nonatomic, readonly) NSInteger processorBusSpeed;

/* Accessory Information */

// Are any accessories attached?
@property (nonatomic, readonly) BOOL accessoriesAttached;

// Are headphone attached?
@property (nonatomic, readonly) BOOL headphonesAttached;

// Number of attached accessories
@property (nonatomic, readonly) NSInteger numberAttachedAccessories;

// Name of attached accessory/accessories (seperated by , comma's)
@property (nonatomic, readonly) NSString *nameAttachedAccessories;

/* Carrier Information */

// Carrier Name
@property (nonatomic, readonly) NSString *carrierName;

// Carrier Country
@property (nonatomic, readonly) NSString *carrierCountry;

// Carrier Mobile Country Code
@property (nonatomic, readonly) NSString *carrierMobileCountryCode;

// Carrier ISO Country Code
@property (nonatomic, readonly) NSString *carrierISOCountryCode;

// Carrier Mobile Network Code
@property (nonatomic, readonly) NSString *carrierMobileNetworkCode;

// Carrier Allows VOIP
@property (nonatomic, readonly) BOOL carrierAllowsVOIP;

/* Battery Information */

// Battery Level
@property (nonatomic, readonly) float batteryLevel;

// Charging?
@property (nonatomic, readonly) BOOL charging;

// Fully Charged?
@property (nonatomic, readonly) BOOL fullyCharged;

/* Network Information */

// Get Current IP Address
@property (nonatomic, readonly) NSString *currentIPAddress;

// Get Current MAC Address
@property (nonatomic, readonly) NSString *currentMACAddress;

// Get External IP Address
@property (nonatomic, readonly) NSString *externalIPAddress;

// Get Cell IP Address
@property (nonatomic, readonly) NSString *cellIPAddress;

// Get Cell MAC Address
@property (nonatomic, readonly) NSString *cellMACAddress;

// Get Cell Netmask Address
@property (nonatomic, readonly) NSString *cellNetmaskAddress;

// Get Cell Broadcast Address
@property (nonatomic, readonly) NSString *cellBroadcastAddress;

// Get WiFi IP Address
@property (nonatomic, readonly) NSString *wiFiIPAddress;

// Get WiFi MAC Address
@property (nonatomic, readonly) NSString *wiFiMACAddress;

// Get WiFi Netmask Address
@property (nonatomic, readonly) NSString *wiFiNetmaskAddress;

// Get WiFi Broadcast Address
@property (nonatomic, readonly) NSString *wiFiBroadcastAddress;

// Get WiFi Router Address
@property (nonatomic, readonly) NSString *wiFiRouterAddress;

// Connected to WiFi?
@property (nonatomic, readonly) BOOL connectedToWiFi;

// Connected to Cellular Network?
@property (nonatomic, readonly) BOOL connectedToCellNetwork;

/* Process Information */

// Process ID
@property (nonatomic, readonly) int processID;

// Process Name
@property (nonatomic, readonly) NSString *processName;

// Process Status
@property (nonatomic, readonly) int processStatus;

// Parent Process ID
@property (nonatomic, readonly) int parentPID;

// List of process information including PID's, Names, PPID's, and Status'
@property (nonatomic, readonly) NSMutableArray *processesInformation;

/* Disk Information */

// Total Disk Space
@property (nonatomic, readonly) NSString *diskSpace;

// Total Free Disk Space (Raw)
@property (nonatomic, readonly) NSString *freeDiskSpaceinRaw;

// Total Free Disk Space (Percentage)
@property (nonatomic, readonly) NSString *freeDiskSpaceinPercent;

// Total Used Disk Space (Raw)
@property (nonatomic, readonly) NSString *usedDiskSpaceinRaw;

// Total Used Disk Space (Percentage)
@property (nonatomic, readonly) NSString *usedDiskSpaceinPercent;

// Get the total disk space in long format
@property (nonatomic, readonly) long long longDiskSpace;

// Get the total free disk space in long format
@property (nonatomic, readonly) long long longFreeDiskSpace;

/* Memory Information */

// Total Memory
@property (nonatomic, readonly) double totalMemory;

// Free Memory (Raw)
@property (nonatomic, readonly) double freeMemoryinRaw;

// Free Memory (Percent)
@property (nonatomic, readonly) double freeMemoryinPercent;

// Used Memory (Raw)
@property (nonatomic, readonly) double usedMemoryinRaw;

// Used Memory (Percent)
@property (nonatomic, readonly) double usedMemoryinPercent;

// Active Memory (Raw)
@property (nonatomic, readonly) double activeMemoryinRaw;

// Active Memory (Percent)
@property (nonatomic, readonly) double activeMemoryinPercent;

// Inactive Memory (Raw)
@property (nonatomic, readonly) double inactiveMemoryinRaw;

// Inactive Memory (Percent)
@property (nonatomic, readonly) double inactiveMemoryinPercent;

// Wired Memory (Raw)
@property (nonatomic, readonly) double wiredMemoryinRaw;

// Wired Memory (Percent)
@property (nonatomic, readonly) double wiredMemoryinPercent;

// Purgable Memory (Raw)
@property (nonatomic, readonly) double purgableMemoryinRaw;

// Purgable Memory (Percent)
@property (nonatomic, readonly) double purgableMemoryinPercent;

/* Accelerometer Information */

// Device Orientation
@property (nonatomic, readonly) UIInterfaceOrientation deviceOrientation;

/* Localization Information */

// Country
@property (nonatomic, readonly) NSString *country;

// Language
@property (nonatomic, readonly) NSString *language;

// TimeZone
@property (nonatomic, readonly) NSString *timeZoneSS;

// Currency Symbol
@property (nonatomic, readonly) NSString *currency;

/* Application Information */

// Application Version
@property (nonatomic, readonly) NSString *applicationVersion;

// Clipboard Content
@property (nonatomic, readonly) NSString *clipboardContent;

/* Universal Unique Identifiers */

// Unique ID
@property (nonatomic, readonly) NSString *uniqueID;

// Device Signature
@property (nonatomic, readonly) NSString *deviceSignature;

// CFUUID
@property (nonatomic, readonly) NSString *cfuuid;

// CPU Usage
@property (nonatomic, readonly) float cpuUsage;

@end
