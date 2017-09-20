//
//  DeviceInfoService.swift
//  Insider
//
//  Created by Alexandru Maimescu on 2/18/16.
//  Copyright © 2016 Alex Maimescu. All rights reserved.
//

import Foundation

final class DeviceInfoService {
    
    var allSystemInfo: InsiderMessage? {
        return SystemServices.shared().allSystemInformation as InsiderMessage?
    }
}
