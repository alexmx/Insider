//
//  Insider.swift
//  Insider
//
//  Created by Alexandru Maimescu on 2/16/16.
//  Copyright © 2016 Alex Maimescu. All rights reserved.
//

import Foundation
import UIKit

public typealias JSONDictionary = [NSObject: AnyObject]

@objc
public protocol InsiderDelegate: class {
    
    /**
     This method will be called on delegate for "invoke" action
     
     - parameter insider: instance of Insider class
     - parameter params:  request params
     */
    @objc optional func insider(_ insider: Insider, invokeMethodWithParams params: JSONDictionary?)
    
    /**
     This method will be called on delegate for "invokeForResponse" action
     
     - parameter insider: instance of Insider class
     - parameter params:  request params
     
     - returns: return params
     */
    @objc optional func insider(_ insider: Insider, invokeMethodForResponseWithParams params: JSONDictionary?) -> JSONDictionary?
    
    /**
     This method will be called on delegate for "notification" action
     
     - parameter insider: instance of Insider class
     - parameter params:  request params sent in notification
     */
    @objc optional func insider(_ insider: Insider, didSendNotificationWithParams params: JSONDictionary?)
    
    /**
     This method will be called on delegate for "systemInfo" action
     
     - parameter insider:    instance of Insider class
     - parameter systemInfo: returned system information
     */
    @objc optional func insider(_ insider: Insider, didReturnSystemInfo systemInfo: JSONDictionary?)
    
    /**
     This method is caled when a new directory is created in sandbox
     
     - parameter insider: instance of Insider class
     - parameter path:    path to the new created directory
     */
    @objc optional func insider(_ insider: Insider, didCreateDirectoryAtPath path: String)
    
    /**
     This method is called when an item is removed from sandbox
     
     - parameter insider: instance of Insider class
     - parameter path:    path of the removed item
     */
    @objc optional func insider(_ insider: Insider, didDeleteItemAtPath path: String)
    
    /**
     This method is called when an item is downloaded from sandbox
     
     - parameter insider: instance of Insider class
     - parameter path:    path to the downloaded item
     */
    @objc optional func insider(_ insider: Insider, didDownloadFileAtPath path: String)
    
    /**
     This method is called when an item is moved in sandbox
     
     - parameter insider:  instance of Insider class
     - parameter fromPath: initial path to the item
     - parameter toPath:   path to the item after it was moved
     */
    @objc optional func insider(_ insider: Insider, didMoveItemFromPath fromPath: String, toPath: String)
    
    /**
     This method is called when an item is uploaded to sandbox
     
     - parameter insider: instance of Insider class
     - parameter path:    path to the uploaded item
     */
    @objc optional func insider(_ insider: Insider, didUploadFileAtPath path: String)
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
    public static let shared = Insider()
    
    /// Insider delegate
    public weak var delegate: InsiderDelegate?
    
    /// Insider notification key
    public static let insiderNotificationKey = "com.insider.insiderNotificationKey"
    
    fileprivate lazy var deviceInfoService = DeviceInfoService()
    
    fileprivate let localWebServer = LocalWebServer()
    
    func addHandlersForServer(_ server: LocalWebServer) {
        
        server.delegate = self
        
        // Add sandbox access handlers
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        server.addSandboxDirectory(documentsPath!, endpoint: Endpoints.documents)
        let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first
        server.addSandboxDirectory(libraryPath!, endpoint: Endpoints.library)
        let tmpPath = NSTemporaryDirectory()
        server.addSandboxDirectory(tmpPath, endpoint: Endpoints.tmp)
                
        // Invoke method on delegate
        server.addHandlerForMethod(.POST, path: Endpoints.invokeEndpoint) { (requestParams) -> (LocalWebServerResponse) in
            let didProcessParams = self.invokeMethodOnDelegateWithParams(requestParams)
            return LocalWebServerResponse(statusCode: (didProcessParams) ? .success : .notFound)
        }
        
        // Invoke method on delegate and wait for return value
        server.addHandlerForMethod(.POST, path: Endpoints.invokeWithResponse) { (requestParams) -> (LocalWebServerResponse) in
            let response = self.invokeMethodOnDelegateWithParamsForResponse(requestParams)
            
            if let response = response {
                return LocalWebServerResponse(response: response)
            } else {
                return LocalWebServerResponse(statusCode: .notFound)
            }
        }
        
        // Send a local notification
        server.addHandlerForMethod(.POST, path: Endpoints.sendNotification) { (requestParams) -> (LocalWebServerResponse) in
            self.sendLocalNotificationWithParams(requestParams)
            return LocalWebServerResponse(statusCode: .success)
        }
        
        server.addHandlerForMethod(.GET, path: Endpoints.systemInfo) { _ in
            return LocalWebServerResponse(response: self.getSystemInfo())
        }
    }
    
    func invokeMethodOnDelegateWithParams(_ params: JSONDictionary?) -> Bool {
        guard let delegate = delegate else {
            print("[Insider] Warning: Delegate not set.")
            return false
        }
        
        delegate.insider?(self, invokeMethodWithParams: params)
        
        return true
    }
    
    func invokeMethodOnDelegateWithParamsForResponse(_ params: JSONDictionary?) -> JSONDictionary? {
        guard let delegate = delegate else {
            print("[Insider] Warning: Delegate not set.")
            return nil
        }
        
        return delegate.insider!(self, invokeMethodForResponseWithParams: params)
    }
    
    func sendLocalNotificationWithParams(_ params: JSONDictionary?) {
        defer {
            delegate?.insider?(self, didSendNotificationWithParams: params)
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Insider.insiderNotificationKey), object: params)
    }
    
    func getSystemInfo() -> JSONDictionary? {
        let systemInfo = self.deviceInfoService.allSystemInfo
        
        defer {
            delegate?.insider?(self, didReturnSystemInfo: systemInfo)
        }
        
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
    public func start(withDelegate delegate: InsiderDelegate?) {
        self.delegate = delegate
        start()
    }
    
    /**
     Start local web server which will listen for commands, for given port.
     By default server listens on port 8080.
     
     - parameter port: port on which local webserver will listen for commands.
     */
    public func start(withPort port: UInt) {
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
    
    func localWebServer(_ server: LocalWebServer, didCreateDirectoryAtPath path: String) {
        delegate?.insider?(self, didCreateDirectoryAtPath: path)
    }
    
    func localWebServer(_ server: LocalWebServer, didDeleteItemAtPath path: String) {
        delegate?.insider?(self, didDeleteItemAtPath: path)
    }
    
    func localWebServer(_ server: LocalWebServer, didDownloadFileAtPath path: String) {
        delegate?.insider?(self, didDownloadFileAtPath: path)
    }
    
    func localWebServer(_ server: LocalWebServer, didMoveItemFromPath fromPath: String, toPath: String) {
        delegate?.insider?(self, didMoveItemFromPath: fromPath, toPath: toPath)
    }
    
    func localWebServer(_ server: LocalWebServer, didUploadFileAtPath path: String) {
        delegate?.insider?(self, didUploadFileAtPath: path)
    }
}
