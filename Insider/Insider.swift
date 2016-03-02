//
//  Insider.swift
//  Insider
//
//  Created by Alexandru Maimescu on 2/16/16.
//  Copyright © 2016 Alex Maimescu. All rights reserved.
//

import Foundation
import UIKit

public typealias JSONDictionary = Dictionary<String, AnyObject>

@objc
public protocol InsiderDelegate: class {
    
    /**
     This method will be called on delegate for "invoke" action
     
     - parameter insider: instance of Insider class
     - parameter params:  request params
     */
    func insider(insider: Insider, invokeMethodWithParams params: JSONDictionary?)
    
    /**
     This method will be called on delegate for "invokeForResponse" action
     
     - parameter insider: instance of Insider class
     - parameter params:  request params
     
     - returns: return params
     */
    func insider(insider: Insider, invokeMethodForResponseWithParams params: JSONDictionary?) -> JSONDictionary?
    
    /**
     This method will be called on delegate for "notification" action
     
     - parameter insider: instance of Insider class
     - parameter params:  request params sent in notification
     */
    optional func insider(insider: Insider, didSendNotificationWithParams params: JSONDictionary?)
    
    /**
     This method will be called on delegate for "systemInfo" action
     
     - parameter insider:    instance of Insider class
     - parameter systemInfo: returned system information
     */
    optional func insider(insider: Insider, didReturnSystemInfo systemInfo: JSONDictionary?)
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
    
    /// Insider delegate
    public weak var delegate: InsiderDelegate?
    
    /// Insider notification key
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
            
            if let response = response {
                return LocalWebServerResponse(response: response)
            } else {
                return LocalWebServerResponse(statusCode: .NotFound)
            }
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
    
    func invokeMethodOnDelegateWithParams(params: JSONDictionary?) -> Bool {
        guard let delegate = delegate else {
            print("[Insider] Warning: Delegate not set.")
            return false
        }
        
        delegate.insider(self, invokeMethodWithParams: params)
        
        return true
    }
    
    func invokeMethodOnDelegateWithParamsForResponse(params: JSONDictionary?) -> JSONDictionary? {
        guard let delegate = delegate else {
            print("[Insider] Warning: Delegate not set.")
            return nil;
        }
        
        return delegate.insider(self, invokeMethodForResponseWithParams: params)
    }
    
    func sendLocalNotificationWithParams(params: JSONDictionary?) {
        defer {
            delegate?.insider?(self, didSendNotificationWithParams: params)
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(Insider.insiderNotificationKey, object: params)
    }
    
    func getSystemInfo() -> JSONDictionary? {
        defer {
            delegate?.insider?(self, didReturnSystemInfo: systemInfo)
        }
        
        let systemInfo = self.deviceInfoService.allSystemInfo
        
        return systemInfo
    }
    
    // MARK - Public methods
    
    /**
     Start local web server which will listen for commands.
     By default server listens on port 8080.
    */
    public func start() {
        addHandlersForServer(localWebServer)
        localWebServer.start()
    }
    
    /**
     Start local web server which will listen for commands, for given delegate
     By default server listens on port 8080.
     
     - parameter delegate: Insider delegate reference
     */
    public func startWithDelegate(delegate: InsiderDelegate?) {
        self.delegate = delegate
        start()
    }
    
    /**
     Start local web server which will listen for commands, for given port.
     By default server listens on port 8080.
     
     - parameter port: port on which local webserver will listen for commands.
     */
    public func startWithPort(port: UInt) {
        addHandlersForServer(localWebServer)
        localWebServer.startWithPort(port)
    }
    
    /**
     Stop local web server.
     */
    public func stop() {
        localWebServer.stop()
    }
}