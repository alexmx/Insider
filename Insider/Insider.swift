//
//  Insider.swift
//  Insider
//
//  Created by Alexandru Maimescu on 2/16/16.
//  Copyright © 2016 Alex Maimescu. All rights reserved.
//

import Foundation
import UIKit
import Libs

@objc
final public class Insider: NSObject {

    enum StatusCodes: Int {
        case Success = 200
        case NotFound = 404
    }
    
    struct Endpoints {
        static let invokeEndpoint = "/invoke"
        static let invokeWithResponse = "/invokeForResponse"
    }
    
    struct Methods {
        static let POST = "POST"
    }
    
    struct Constants {
        static let defaultPort: UInt = 8080
        static let defaultInvokeMethodSelector = Selector("insiderInvoke:")
        static let defaultInvokeForResponseMethodSelector = Selector("insiderInvokeForResponse:")
    }
    
    public static let sharedInstance = Insider()
    
    public lazy var appDelegateInvokeMethodSelector: Selector = {
        return Constants.defaultInvokeMethodSelector
    }()
    
    public lazy var appDelegateInvokeForResponseMethodSelector: Selector = {
        return Constants.defaultInvokeForResponseMethodSelector
    }()
    
    private let localWebServer = GCDWebServer()
    
    internal override init() {}
    
    func addHandlersForServer(server: GCDWebServer) {
        
        server.addDefaultHandlerForMethod(Methods.POST, requestClass: GCDWebServerURLEncodedFormRequest.self) {
            (request) -> GCDWebServerResponse! in
            
            return GCDWebServerDataResponse(statusCode: StatusCodes.NotFound.rawValue)
        }
        
        server.addHandlerForMethod(Methods.POST, path: Endpoints.invokeEndpoint, requestClass: GCDWebServerURLEncodedFormRequest.self) {
            (request) -> GCDWebServerResponse! in
            
            var didProcessParams = false
            if let request = request as? GCDWebServerURLEncodedFormRequest {
                if let json = request.jsonObject {
                    didProcessParams = self.invokeMethodOnAppDelegateWithSelector(self.appDelegateInvokeMethodSelector, params: json)
                } else if let encodedParams = request.arguments {
                    didProcessParams = self.invokeMethodOnAppDelegateWithSelector(self.appDelegateInvokeMethodSelector, params: encodedParams)
                }
            }
            
            return GCDWebServerDataResponse(statusCode: (didProcessParams) ? StatusCodes.Success.rawValue : StatusCodes.NotFound.rawValue)
        }
        
        server.addHandlerForMethod(Methods.POST, path: Endpoints.invokeWithResponse, requestClass: GCDWebServerURLEncodedFormRequest.self) {
            (request) -> GCDWebServerResponse! in
            
            var response: Dictionary<String, AnyObject>?
            if let request = request as? GCDWebServerURLEncodedFormRequest {
                if let json = request.jsonObject {
                    response = self.invokeMethodOnAppDelegateForResponseWithSelector(self.appDelegateInvokeForResponseMethodSelector, params: json)
                } else if let encodedParams = request.arguments {
                    response = self.invokeMethodOnAppDelegateForResponseWithSelector(self.appDelegateInvokeForResponseMethodSelector, params: encodedParams)
                }
            }
            
            return (response == nil)
                ? GCDWebServerDataResponse(statusCode: StatusCodes.NotFound.rawValue)
                : GCDWebServerDataResponse(JSONObject: response)
        }
    }
    
    func canPerformSelectorOnAppDelegate(selector: Selector) -> Bool {
        return UIApplication.sharedApplication().delegate?.respondsToSelector(selector) ?? false
    }
    
    func invokeMethodOnAppDelegateWithSelector(selector: Selector, params: AnyObject?) -> Bool {
        guard canPerformSelectorOnAppDelegate(selector) else {
            return false
        }
        
        dispatch_sync(dispatch_get_main_queue()) { () -> Void in
            UIApplication.sharedApplication().delegate?.performSelector(selector, withObject: params)
        }
        
        return true
    }
    
    func invokeMethodOnAppDelegateForResponseWithSelector(selector: Selector, params: AnyObject?) -> Dictionary<String, AnyObject>? {
        guard canPerformSelectorOnAppDelegate(selector) else {
            return nil
        }
        
        var response: AnyObject?
        dispatch_sync(dispatch_get_main_queue()) { () -> Void in
            response = UIApplication.sharedApplication().delegate?.performSelector(selector, withObject: params).takeUnretainedValue()
        }
        
        return response as? Dictionary<String, AnyObject> ?? nil
    }
    
    // MARK - Public methods
    
    public func start() {
        startWithPort(Constants.defaultPort)
    }
    
    public func startWithPort(port: UInt) {
        addHandlersForServer(localWebServer)
        localWebServer.startWithPort(port, bonjourName: nil)
    }
    
    public func stop() {
        localWebServer.stop()
    }
}