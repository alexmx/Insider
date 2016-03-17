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
    
    /**
     This method is caled when a new directory is created in sandbox
     
     - parameter insider: instance of Insider class
     - parameter path:    path to the new created directory
     */
    optional func insider(insider: Insider, didCreateDirectoryAtPath path: String)
    
    /**
     This method is called when an item is removed from sandbox
     
     - parameter insider: instance of Insider class
     - parameter path:    path of the removed item
     */
    optional func insider(insider: Insider, didDeleteItemAtPath path: String)
    
    /**
     This method is called when an item is downloaded from sandbox
     
     - parameter insider: instance of Insider class
     - parameter path:    path to the downloaded item
     */
    optional func insider(insider: Insider, didDownloadFileAtPath path: String)
    
    /**
     This method is called when an item is moved in sandbox
     
     - parameter insider:  instance of Insider class
     - parameter fromPath: initial path to the item
     - parameter toPath:   path to the item after it was moved
     */
    optional func insider(insider: Insider, didMoveItemFromPath fromPath: String, toPath: String)
    
    /**
     This method is called when an item is uploaded to sandbox
     
     - parameter insider: instance of Insider class
     - parameter path:    path to the uploaded item
     */
    optional func insider(insider: Insider, didUploadFileAtPath path: String)
}

@objc
final public class Insider: NSObject {
    
    struct Endpoints {
        static let invokeEndpoint = "/invoke"
        static let invokeWithResponse = "/invokeForResponse"
        static let sendNotification = "/notification"
        static let systemInfo = "/systemInfo"
        static let documents = "/documents"
        static let library = "/library"
        static let tmp = "/tmp"
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
        
        server.delegate = self
        
        // Add sandbox access handlers
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first
        server.addSandboxDirectory(documentsPath!, endpoint: Endpoints.documents);
        let libraryPath = NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true).first
        server.addSandboxDirectory(libraryPath!, endpoint: Endpoints.library);
        let tmpPath = NSTemporaryDirectory();
        server.addSandboxDirectory(tmpPath, endpoint: Endpoints.tmp)
                
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


extension Insider: LocalWebServerDelegate {
    
    func localWebServer(server: LocalWebServer, didCreateDirectoryAtPath path: String) {
        delegate?.insider?(self, didCreateDirectoryAtPath: path)
    }
    
    func localWebServer(server: LocalWebServer, didDeleteItemAtPath path: String) {
        delegate?.insider?(self, didDeleteItemAtPath: path)
    }
    
    func localWebServer(server: LocalWebServer, didDownloadFileAtPath path: String) {
        delegate?.insider?(self, didDownloadFileAtPath: path)
    }
    
    func localWebServer(server: LocalWebServer, didMoveItemFromPath fromPath: String, toPath: String) {
        delegate?.insider?(self, didMoveItemFromPath: fromPath, toPath: toPath)
    }
    
    func localWebServer(server: LocalWebServer, didUploadFileAtPath path: String) {
        delegate?.insider?(self, didUploadFileAtPath: path)
    }
}