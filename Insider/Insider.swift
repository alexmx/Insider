//
//  Insider.swift
//  Insider
//
//  Created by Alexandru Maimescu on 2/16/16.
//  Copyright © 2016 Alex Maimescu. All rights reserved.
//

import Foundation
import UIKit

@objc
final public class Insider: NSObject {
    
    struct Endpoints {
        static let invokeEndpoint = "/invoke"
        static let invokeWithResponse = "/invokeForResponse"
        static let sendNotification = "/notification"
        static let systemInfo = "/systemInfo"
    }
    
    struct Constants {
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
    
    private lazy var deviceInfoService: DeviceInfoService = DeviceInfoService()
    
    private let localWebServer = LocalWebServer()
    
    internal override init() {}
    
    func addHandlersForServer(server: LocalWebServer) {
                
        // Default handler
        server.addDefaultHandlerForMethod(.POST) { (requestParams) -> (LocalWebServerResponse) in
            return LocalWebServerResponse(statusCode: .NotFound)
        }
        
        // Invoke method on AppDelegate
        server.addHandlerForMethod(.POST, path: Endpoints.invokeEndpoint) { (requestParams) -> (LocalWebServerResponse) in
            
            let didProcessParams = self.invokeMethodOnAppDelegateWithSelector(self.appDelegateInvokeMethodSelector, params: requestParams)
            return LocalWebServerResponse(statusCode: (didProcessParams) ? .Success : .NotFound)
        }
        
        // Invoke method on AppDelegate and wait for return value
        server.addHandlerForMethod(.POST, path: Endpoints.invokeWithResponse) { (requestParams) -> (LocalWebServerResponse) in
            
            let response = self.invokeMethodOnAppDelegateForResponseWithSelector(self.invokeForResponseMethodSelector, params: requestParams)
            return (response == nil) ? LocalWebServerResponse(statusCode: .NotFound) : LocalWebServerResponse(response: response)
        }
        
        // Send a local notification
        server.addHandlerForMethod(.POST, path: Endpoints.sendNotification) { (requestParams) -> (LocalWebServerResponse) in
            
            self.sendLocalNotificationWithParams(requestParams)
            return LocalWebServerResponse(statusCode: .Success)
        }
        
        server.addHandlerForMethod(.GET, path: Endpoints.systemInfo) { (requestParams) -> (LocalWebServerResponse) in
            return LocalWebServerResponse(response: self.deviceInfoService.allSystemInfo)
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
    
    func sendLocalNotificationWithParams(params: AnyObject?) {
        NSNotificationCenter.defaultCenter().postNotificationName(Insider.insiderNotificationKey, object: params)
    }
    
    // MARK - Public methods
    
    public func start() {
        addHandlersForServer(localWebServer)
        localWebServer.start()
    }
    
    public func startWithPort(port: UInt) {
        addHandlersForServer(localWebServer)
        localWebServer.startWithPort(port)
    }
    
    public func stop() {
        localWebServer.stop()
    }
}