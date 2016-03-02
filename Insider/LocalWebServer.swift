//
//  LocalWebServer.swift
//  Insider
//
//  Created by Alexandru Maimescu on 2/19/16.
//  Copyright © 2016 Alex Maimescu. All rights reserved.
//

import Foundation

typealias LocalWebServerRequestHandler = (JSONDictionary?) -> (LocalWebServerResponse)


enum LocalWebServerRequestMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}


protocol GCDWebServerDataResponseConvertible {
    
    func convertedToGCDWebServerDataResponse() -> GCDWebServerDataResponse
}


extension LocalWebServerResponse: GCDWebServerDataResponseConvertible {
    
    func convertedToGCDWebServerDataResponse() -> GCDWebServerDataResponse {
        
        if let jsonObject = self.response {
            return GCDWebServerDataResponse(JSONObject: jsonObject)
        } else {
            return GCDWebServerDataResponse(statusCode: self.statusCode.rawValue)
        }
    }
}


final class LocalWebServer {
    
    struct Constants {
        static let defaultPort: UInt = 8080
    }
    
    private let localWebServer = GCDWebServer()
    
    func start() {
        startWithPort(Constants.defaultPort)
    }
    
    func startWithPort(port: UInt) {
        localWebServer.startWithPort(port, bonjourName: nil)
    }
    
    func stop() {
        localWebServer.stop()
    }
    
    func addDefaultHandlerForMethod(method: LocalWebServerRequestMethod, handler: LocalWebServerRequestHandler) {
        
        localWebServer.addDefaultHandlerForMethod(method.rawValue, requestClass: GCDWebServerURLEncodedFormRequest.self) {
            (request) -> GCDWebServerResponse! in
            
            var response: LocalWebServerResponse?
            self.executeOnMainQueue {
                response = handler(nil)
            }
            
            return response?.convertedToGCDWebServerDataResponse()
        }
    }
    
    func addHandlerForMethod(method: LocalWebServerRequestMethod, path: String, handler: LocalWebServerRequestHandler) {
        
        localWebServer.addHandlerForMethod(method.rawValue, path: path, requestClass: GCDWebServerURLEncodedFormRequest.self) {
            (request) -> GCDWebServerResponse! in
            
            let params = self.paramsForRequest(request as? GCDWebServerURLEncodedFormRequest)
            var response: LocalWebServerResponse?
            self.executeOnMainQueue {
                response = handler(params)
            }
            
            return response?.convertedToGCDWebServerDataResponse()
        }
    }
    
    func executeOnMainQueue(closure: (() -> ())?) {
        dispatch_sync(dispatch_get_main_queue()) { closure?() }
    }
    
    func paramsForRequest(request: GCDWebServerURLEncodedFormRequest?) -> JSONDictionary? {
        guard let request = request where LocalWebServerRequestMethod(rawValue: request.method) != .GET else {
            return nil
        }
        
        var params: JSONDictionary?
        let contentType = request.contentType
        let jsonTypes = ["application/json", "text/json", "text/javascript"]
        if jsonTypes.contains(contentType) {
            if let json = request.jsonObject {
                params = json as? JSONDictionary
            }
        } else {
            if let encodedParams = request.arguments {
                params = encodedParams as? JSONDictionary
            }
        }
        
        return params
    }
}