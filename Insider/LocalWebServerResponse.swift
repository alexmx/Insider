//
//  LocalWebServerResponse.swift
//  Insider
//
//  Created by Alexandru Maimescu on 2/19/16.
//  Copyright © 2016 Alex Maimescu. All rights reserved.
//

import Foundation

enum LocalWebServerResponseStatusCode: Int {
    case success = 200
    case notFound = 404
}

final class LocalWebServerResponse {
    
    var statusCode: LocalWebServerResponseStatusCode
    var response: InsiderMessage?
    
    init(statusCode: LocalWebServerResponseStatusCode) {
        self.statusCode = statusCode
    }
    
    init(response: InsiderMessage?) {
        self.statusCode = .success
        self.response = response
    }
}
