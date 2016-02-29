//
//  LocalWebServerResponse.swift
//  Insider
//
//  Created by Alexandru Maimescu on 2/19/16.
//  Copyright © 2016 Alex Maimescu. All rights reserved.
//

import Foundation

enum LocalWebServerResponseStatusCode: Int {
    case Success = 200
    case NotFound = 404
}

final class LocalWebServerResponse {
    
    var statusCode: LocalWebServerResponseStatusCode
    var response: JSONDictionary?
    
    init(statusCode: LocalWebServerResponseStatusCode) {
        self.statusCode = statusCode
    }
    
    init(response: JSONDictionary?) {
        self.statusCode = .Success
        self.response = response
    }
}