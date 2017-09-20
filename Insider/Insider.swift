//
//  Insider.swift
//  Insider
//
//  Created by Alexandru Maimescu on 2/16/16.
//  Copyright © 2016 Alex Maimescu. All rights reserved.
//

import Foundation

public typealias InsiderMessage = [NSObject: AnyObject]

/// The Insider delegate protocol.
@objc
public protocol InsiderDelegate: AnyObject {
    
    /**
     This method will be called on delegate for "send" command
     
     - parameter insider: instance of Insider class
     - parameter params:  request params
     */
    @objc(insider:didReceiveRemoteMessage:)
    optional func insider(_ insider: Insider, didReceiveRemote message: InsiderMessage?)
    
    /**
     This method will be called on delegate for "sendAndWaitForResponse" command
     
     - parameter insider: instance of Insider class
     - parameter params:  request params
     
     - returns: return params
     */
    @objc(insider:returnResponseMessageForRemoteMessage:)
    optional func insider(_ insider: Insider, returnResponseMessageForRemote message: InsiderMessage?) -> InsiderMessage?
    
    /**
     This method will be called on delegate for "notification" command
     
     - parameter insider: instance of Insider class
     - parameter params:  request params sent in notification
     */
    @objc(insider:didSendNotificationWithMessage:)
    optional func insider(_ insider: Insider, didSendNotificationWith message: InsiderMessage?)
    
    /**
     This method will be called on delegate for "systemInfo" command
     
     - parameter insider:    instance of Insider class
     - parameter systemInfo: returned system information
     */
    @objc(insider:didReturnSystemInfo:)
    optional func insider(_ insider: Insider, didReturn systemInfo: InsiderMessage?)
    
    /**
     This method is caled when a new directory is created in sandbox
     
     - parameter insider: instance of Insider class
     - parameter path:    path to the new created directory
     */
    @objc(insider:didCreateDirectoryAtPath:)
    optional func insider(_ insider: Insider, didCreateDirectoryAt path: String)
    
    /**
     This method is called when an item is removed from sandbox
     
     - parameter insider: instance of Insider class
     - parameter path:    path of the removed item
     */
    @objc(insider:didDeleteItemAtPath:)
    optional func insider(_ insider: Insider, didDeleteItemAt path: String)
    
    /**
     This method is called when an item is downloaded from sandbox
     
     - parameter insider: instance of Insider class
     - parameter path:    path to the downloaded item
     */
    @objc(insider:didDownloadFileAtPath:)
    optional func insider(_ insider: Insider, didDownloadFileAt path: String)
    
    /**
     This method is called when an item is moved in sandbox
     
     - parameter insider:  instance of Insider class
     - parameter fromPath: initial path to the item
     - parameter toPath:   path to the item after it was moved
     */
    @objc(insider:didMoveItemFromPath:toPath:)
    optional func insider(_ insider: Insider, didMoveItem fromPath: String, to path: String)
    
    /**
     This method is called when an item is uploaded to sandbox
     
     - parameter insider: instance of Insider class
     - parameter path:    path to the uploaded item
     */
    @objc(insider:didUploadFileAtPath:)
    optional func insider(_ insider: Insider, didUploadFileAt path: String)
}

/// The Insider API facade class.
@objcMembers
final public class Insider: NSObject {
    
    private struct Endpoints {
        static let sendMessage = "/send"
        static let sendMessageAndWaitForResponse = "/sendAndWaitForResponse"
        static let sendNotification = "/notification"
        static let systemInfo = "/systemInfo"
        static let documents = "/documents"
        static let library = "/library"
        static let tmp = "/tmp"
    }
    
    /// The shared instance.
    public static let shared = Insider()
    
    /// The Insider delegate.
    public weak var delegate: InsiderDelegate?
    
    /// The Insider notification key.
    public static let insiderNotificationKey = "com.insider.insiderNotificationKey"
    
    private lazy var deviceInfoService = DeviceInfoService()
    
    private let localWebServer = LocalWebServer()
    
    // MARK: - Public methods
    
    /**
     Start the local web server which will listen for commands.
     By default server listens on port 8080.
     */
    public func start() {
        addHandlersForServer(localWebServer)
        localWebServer.start()
    }
    
    /**
     Start the local web server which will listen for commands, for given delegate.
     By default server listens on port 8080.
     
     - parameter delegate: Insider delegate reference
     */
    public func start(withDelegate delegate: InsiderDelegate?) {
        self.delegate = delegate
        start()
    }
    
    /// Start the local web server which will listen for commands, for given delegate and port number.
    ///
    /// - Parameters:
    ///   - delegate: The Insider delegate reference.
    ///   - port: the port on which local webserver will listen for commands.
    public func start(withDelegate delegate: InsiderDelegate?, port: UInt) {
        self.delegate = delegate
        addHandlersForServer(localWebServer)
        localWebServer.startWithPort(port)
    }
    
    /**
     Stop the local web server.
     */
    public func stop() {
        localWebServer.stop()
    }
    
    // MARK: - Private methods
    
    private func addHandlersForServer(_ server: LocalWebServer) {
        
        server.delegate = self
        
        // Add sandbox access handlers
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        server.addSandboxDirectory(documentsPath!, endpoint: Endpoints.documents)
        let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first
        server.addSandboxDirectory(libraryPath!, endpoint: Endpoints.library)
        let tmpPath = NSTemporaryDirectory()
        server.addSandboxDirectory(tmpPath, endpoint: Endpoints.tmp)
                
        // Invoke method on delegate
        server.addHandlerForMethod(.POST, path: Endpoints.sendMessage) { (requestParams) -> (LocalWebServerResponse) in
            let didProcessParams = self.didReceiveRemoteMessage(requestParams)
            return LocalWebServerResponse(statusCode: (didProcessParams) ? .success : .notFound)
        }
        
        // Invoke method on delegate and wait for return value
        server.addHandlerForMethod(.POST, path: Endpoints.sendMessageAndWaitForResponse) { (requestParams) -> (LocalWebServerResponse) in
            let response = self.returnResponseMessageForRemoteMesssage(requestParams)
            
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
    
    private func didReceiveRemoteMessage(_ message: InsiderMessage?) -> Bool {
        guard let delegate = delegate else {
            print("[Insider] Warning: Delegate not set.")
            return false
        }
        
        delegate.insider?(self, didReceiveRemote: message)
        
        return true
    }
    
    private func returnResponseMessageForRemoteMesssage(_ message: InsiderMessage?) -> InsiderMessage? {
        guard let delegate = delegate else {
            print("[Insider] Warning: Delegate not set.")
            return nil
        }
        
        return delegate.insider?(self, returnResponseMessageForRemote: message)
    }
    
    private func sendLocalNotificationWithParams(_ params: InsiderMessage?) {
        defer {
            delegate?.insider?(self, didSendNotificationWith: params)
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Insider.insiderNotificationKey), object: params)
    }
    
    private func getSystemInfo() -> InsiderMessage? {
        let systemInfo = self.deviceInfoService.allSystemInfo
        
        defer {
            delegate?.insider?(self, didReturn: systemInfo)
        }
        
        return systemInfo
    }
}

extension Insider: LocalWebServerDelegate {
    
    func localWebServer(_ server: LocalWebServer, didCreateDirectoryAtPath path: String) {
        delegate?.insider?(self, didCreateDirectoryAt: path)
    }
    
    func localWebServer(_ server: LocalWebServer, didDeleteItemAtPath path: String) {
        delegate?.insider?(self, didDeleteItemAt: path)
    }
    
    func localWebServer(_ server: LocalWebServer, didDownloadFileAtPath path: String) {
        delegate?.insider?(self, didDownloadFileAt: path)
    }
    
    func localWebServer(_ server: LocalWebServer, didMoveItemFromPath fromPath: String, toPath: String) {
        delegate?.insider?(self, didMoveItem: fromPath, to: toPath)
    }
    
    func localWebServer(_ server: LocalWebServer, didUploadFileAtPath path: String) {
        delegate?.insider?(self, didUploadFileAt: path)
    }
}
