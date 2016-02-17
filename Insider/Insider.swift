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
    
    struct Constants {
        static let defaultPort: UInt = 8080
        static let defaultInsiderMethodSelector = Selector("insider:")
    }
    
    public static let sharedInstance = Insider()
    
    public lazy var appDelegateInsiderSelector: Selector = {
        return Constants.defaultInsiderMethodSelector
    }()
    
    private let localWebServer = GCDWebServer()
    
    private override init() {}
    
    private func addHandlersForServer(server: GCDWebServer, withAppDelegateInsiderSelector selector: Selector) {
        
        // Add POST handler for x-www-form-urlencoded requests
        server.addDefaultHandlerForMethod("POST", requestClass: GCDWebServerURLEncodedFormRequest.self, processBlock: { request in
            
            var didProcessParams = false
            if let request = request as? GCDWebServerURLEncodedFormRequest {
                if let json = request.jsonObject {
                    didProcessParams = self.processRequestParams(json, selector: selector)
                } else if let encodedParams = request.arguments {
                    didProcessParams = self.processRequestParams(encodedParams, selector: selector)
                }
            }
            
            return GCDWebServerDataResponse(statusCode: (didProcessParams) ? StatusCodes.Success.rawValue : StatusCodes.NotFound.rawValue);
        })
    }
    
    private func canProcessRequestParams() -> Bool {
        return UIApplication.sharedApplication().delegate?.respondsToSelector(appDelegateInsiderSelector) ?? false
    }
    
    private func processRequestParams(params: AnyObject, selector: Selector) -> Bool {
        guard canProcessRequestParams() else {
            return false
        }
        
        dispatch_sync(dispatch_get_main_queue()) { () -> Void in
            UIApplication.sharedApplication().delegate?.performSelector(selector, withObject: params)
        }
        
        return true
    }
    
    // MARK - Public methods
    
    public func start() {
        startWithPort(Constants.defaultPort)
    }
    
    public func startWithPort(port: UInt) {
        addHandlersForServer(localWebServer, withAppDelegateInsiderSelector: appDelegateInsiderSelector)
        localWebServer.startWithPort(port, bonjourName: nil)
    }
    
    public func stop() {
        localWebServer.stop()
    }
}