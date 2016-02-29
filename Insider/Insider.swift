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
public protocol InsiderDelegate: class {
    
    /**
     This method will be called on delegate for "invoke" action
     
     - parameter insider: instance of Insider class
     - parameter params:  request params
     */
    func insider(insider: Insider, invokeMethodWithParams params: AnyObject?)
    
    /**
     This method will be called on delegate for "invokeForResponse" action
     
     - parameter insider: instance of Insider class
     - parameter params:  request params
     
     - returns: return params
     */
    func insider(insider: Insider, invokeMethodForResponseWithParams params: AnyObject?) -> Dictionary<String, AnyObject>?
    
    /**
     This method will be called on delegate for "notification" action
     
     - parameter insider: instance of Insider class
     - parameter params:  request params sent in notification
     */
    optional func insider(insider: Insider, didSendNotificationWithParams params: AnyObject?)
    
    /**
     This method will be called on delegate for "systemInfo" action
     
     - parameter insider:    instance of Insider class
     - parameter systemInfo: returned system information
     */
    optional func insider(insider: Insider, didReturnSystemInfo systemInfo: Dictionary<String, AnyObject>?)
}

@objc
final public class Insider: NSObject {
    
    struct Endpoints {
        static let invokeEndpoint = "/invoke"
        static let invokeWithResponse = "/invokeForResponse"
        static let sendNotification = "/notification"
        static let systemInfo = "/systemInfo"
    }
    
    /// Shared instance
    public static let sharedInstance = Insider()
    
    // Insider delegate
    public weak var delegate: InsiderDelegate?
    
    // Insider notification key
    public static let insiderNotificationKey = "com.insider.insiderNotificationKey"
    private lazy var deviceInfoService = DeviceInfoService()
    
    private let localWebServer = LocalWebServer()
    
    func addHandlersForServer(server: LocalWebServer) {
                
        // Default handler
        server.addDefaultHandlerForMethod(.POST) { (requestParams) -> (LocalWebServerResponse) in
            return LocalWebServerResponse(statusCode: .NotFound)
        }
        
        // Invoke method on delegate
        server.addHandlerForMethod(.POST, path: Endpoints.invokeEndpoint) { (requestParams) -> (LocalWebServerResponse) in
            
            let didProcessParams = self.invokeMethodOnDelegateWithParams(requestParams)
            return LocalWebServerResponse(statusCode: (didProcessParams) ? .Success : .NotFound)
        }
        
        // Invoke method on delegate and wait for return value
        server.addHandlerForMethod(.POST, path: Endpoints.invokeWithResponse) { (requestParams) -> (LocalWebServerResponse) in
            
            let response = self.invokeMethodOnDelegateWithParamsForResponse(requestParams)
            return (response == nil) ? LocalWebServerResponse(statusCode: .NotFound) : LocalWebServerResponse(response: response)
        }
        
        // Send a local notification
        server.addHandlerForMethod(.POST, path: Endpoints.sendNotification) { (requestParams) -> (LocalWebServerResponse) in
            
            self.sendLocalNotificationWithParams(requestParams)
            return LocalWebServerResponse(statusCode: .Success)
        }
        
        server.addHandlerForMethod(.GET, path: Endpoints.systemInfo) { (requestParams) -> (LocalWebServerResponse) in
            return LocalWebServerResponse(response: self.getSystemInfo())
        }
    }
    
    func invokeMethodOnDelegateWithParams(params: AnyObject?) -> Bool {
        guard let delegate = delegate else {
            return false
        }
        
        mainQueue {
            delegate.insider(self, invokeMethodWithParams: params)
        }
        
        return true
    }
    
    func invokeMethodOnDelegateWithParamsForResponse(params: AnyObject?) -> Dictionary<String, AnyObject>? {
        mainQueue {
            return self.delegate?.insider(self, invokeMethodForResponseWithParams: params)
        }
        return nil
    }
    
    func sendLocalNotificationWithParams(params: AnyObject?) {
        mainQueue {
            NSNotificationCenter.defaultCenter().postNotificationName(Insider.insiderNotificationKey, object: params)
            self.delegate?.insider?(self, didSendNotificationWithParams: params)
        }
    }
    
    func getSystemInfo() -> Dictionary<String, AnyObject>? {
        let systemInfo = self.deviceInfoService.allSystemInfo
        mainQueue {
            self.delegate?.insider?(self, didReturnSystemInfo: systemInfo)
        }
        
        return systemInfo
    }
    
    func mainQueue(closure: (() -> ())?) {
        dispatch_sync(dispatch_get_main_queue()) { () -> Void in closure?() }
    }
    
    // MARK - Public methods
    
    public func start() {
        addHandlersForServer(localWebServer)
        localWebServer.start()
    }
    
    public func startWithDelegate(delegate: InsiderDelegate?) {
        self.delegate = delegate
        start()
    }
    
    public func startWithPort(port: UInt) {
        addHandlersForServer(localWebServer)
        localWebServer.startWithPort(port)
    }
    
    public func stop() {
        localWebServer.stop()
    }
}