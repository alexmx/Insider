//
//  Insider.swift
//  Insider
//
//  Created by Alexandru Maimescu on 2/16/16.
//  Copyright © 2016 Alex Maimescu. All rights reserved.
//

import Foundation

@objc
final public class Insider: NSObject {
    
    struct Constants {
        static let defaultPort: UInt = 8080
    }
    
    public static let sharedInstance = Insider()
    
    private lazy var localWebServer: GCDWebServer = {
        let server = GCDWebServer()
        return server;
    }()
    
    private override init() {}
    
    public func start() {
        startWithPort(Constants.defaultPort)
    }
    
    public func startWithPort(port: UInt) {
        localWebServer.startWithPort(port, bonjourName: nil)
    }
    
    public func stop() {
        localWebServer.stop()
    }
}