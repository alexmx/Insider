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

    struct Constants {
        static let defaultPort: UInt = 8080
        static let defaultInsiderMethodSelector = Selector("insider:")
    }
    
    public static let sharedInstance = Insider()
    
    public var appDelegateInsiderSelector: Selector?
    
    private let localWebServer = GCDWebServer()
    
    private override init() {}
    
    private func addHandlersForServer(server: GCDWebServer, withAppDelegateInsiderSelector selector: Selector) {
        
        // Add POST handler for x-www-form-urlencoded requests
        server.addDefaultHandlerForMethod("POST", requestClass: GCDWebServerURLEncodedFormRequest.self, processBlock: { request in
            
            if let request = request as? GCDWebServerURLEncodedFormRequest {
                if let json = request.jsonObject {
                    self.processRequestParams(json, selector: selector)
                } else if let params = request.arguments {
                    self.processRequestParams(params, selector: selector)
                }
            }
            
            return nil
        })
    }
    
    private func processRequestParams(params: AnyObject, selector: Selector) {
        dispatch_sync(dispatch_get_main_queue()) { () -> Void in
            UIApplication.sharedApplication().delegate?.performSelector(selector, withObject: params)
        }
    }
    
    public func start() {
        startWithPort(Constants.defaultPort)
    }
    
    public func startWithPort(port: UInt) {
        addHandlersForServer(localWebServer,
            withAppDelegateInsiderSelector: appDelegateInsiderSelector ?? Constants.defaultInsiderMethodSelector
        )
        
        localWebServer.startWithPort(port, bonjourName: nil)
    }
    
    public func stop() {
        localWebServer.stop()
    }
}