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
        static let sendNotification = "/notification"
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
    
    public static let insiderNotificationKey = "com.insider.insiderNotificationKey"
    
    public lazy var appDelegateInvokeMethodSelector: Selector = {
        return Constants.defaultInvokeMethodSelector
    }()
    
    public lazy var invokeForResponseMethodSelector: Selector = {
        return Constants.defaultInvokeForResponseMethodSelector
    }()
    
    private let localWebServer = GCDWebServer()
    
    internal override init() {}
    
    func addHandlersForServer(server: GCDWebServer) {
        
        server.addDefaultHandlerForMethod(Methods.POST, requestClass: GCDWebServerURLEncodedFormRequest.self) {
            (request) -> GCDWebServerResponse! in
            
            return GCDWebServerDataResponse(statusCode: StatusCodes.NotFound.rawValue)
        }
        
        // Invoke method on AppDelegate
        server.addHandlerForMethod(Methods.POST, path: Endpoints.invokeEndpoint, requestClass: GCDWebServerURLEncodedFormRequest.self) {
            (request) -> GCDWebServerResponse! in
            
            let params = self.paramsForRequest(request as? GCDWebServerURLEncodedFormRequest)
            let didProcessParams = self.invokeMethodOnAppDelegateWithSelector(self.appDelegateInvokeMethodSelector, params: params)
            
            return GCDWebServerDataResponse(statusCode: (didProcessParams) ? StatusCodes.Success.rawValue : StatusCodes.NotFound.rawValue)
        }
        
        // Invoke method on AppDelegate and wait for return value
        server.addHandlerForMethod(Methods.POST, path: Endpoints.invokeWithResponse, requestClass: GCDWebServerURLEncodedFormRequest.self) {
            (request) -> GCDWebServerResponse! in
            
            let params = self.paramsForRequest(request as? GCDWebServerURLEncodedFormRequest)
            let response = self.invokeMethodOnAppDelegateForResponseWithSelector(self.invokeForResponseMethodSelector, params: params)
            
            return (response == nil)
                ? GCDWebServerDataResponse(statusCode: StatusCodes.NotFound.rawValue)
                : GCDWebServerDataResponse(JSONObject: response)
        }
        
        // Send a local notification
        server.addHandlerForMethod(Methods.POST, path: Endpoints.sendNotification, requestClass: GCDWebServerURLEncodedFormRequest.self) {
            (request) -> GCDWebServerResponse! in
            
            let params = self.paramsForRequest(request as? GCDWebServerURLEncodedFormRequest)
            self.sendLocalNotificationWithParams(params)
            
            return GCDWebServerDataResponse(statusCode: StatusCodes.Success.rawValue)
        }
    }
    
    func paramsForRequest(request: GCDWebServerURLEncodedFormRequest?) -> Dictionary<String, AnyObject>? {
        
        var params: Dictionary<String, AnyObject>?
        if let request = request {
            if let json = request.jsonObject {
                params = json as? Dictionary<String, AnyObject>
            } else if let encodedParams = request.arguments {
                params = encodedParams as? Dictionary<String, AnyObject>
            }
        }
        
        return params
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
    
    func sendLocalNotificationWithParams(params: AnyObject?) {
        NSNotificationCenter.defaultCenter().postNotificationName(Insider.insiderNotificationKey, object: params)
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