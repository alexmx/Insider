//
//  LocalWebServer.swift
//  Insider
//
//  Created by Alexandru Maimescu on 2/19/16.
//  Copyright © 2016 Alex Maimescu. All rights reserved.
//

import Foundation

typealias LocalWebServerRequestHandler = (Dictionary<String, AnyObject>?) -> (LocalWebServerResponse)


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
            
            let response = handler(nil)
            
            return response.convertedToGCDWebServerDataResponse()
        }
    }
    
    func addHandlerForMethod(method: LocalWebServerRequestMethod, path: String, handler: LocalWebServerRequestHandler) {
        
        localWebServer.addHandlerForMethod(method.rawValue, path: path, requestClass: GCDWebServerURLEncodedFormRequest.self) {
            (request) -> GCDWebServerResponse! in
            
            let params = self.paramsForRequest(request as? GCDWebServerURLEncodedFormRequest)
            let response = handler(params)
            
            return response.convertedToGCDWebServerDataResponse()
        }
    }
    
    func paramsForRequest(request: GCDWebServerURLEncodedFormRequest?) -> Dictionary<String, AnyObject>? {
        guard let request = request where LocalWebServerRequestMethod(rawValue: request.method!) != .GET else {
            return nil
        }
        
        var params: Dictionary<String, AnyObject>?
        let contentType = request.contentType
        if contentType == "application/json" || contentType == "text/json" || contentType == "text/javascript" {
            if let json = request.jsonObject {
                params = json as? Dictionary<String, AnyObject>
            }
        } else {
            if let encodedParams = request.arguments {
                params = encodedParams as? Dictionary<String, AnyObject>
            }
        }
        
        return params
    }
}