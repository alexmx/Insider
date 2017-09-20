//
//  LocalWebServer.swift
//  Insider
//
//  Created by Alexandru Maimescu on 2/19/16.
//  Copyright © 2016 Alex Maimescu. All rights reserved.
//

import Foundation

typealias LocalWebServerRequestHandler = (InsiderMessage?) -> (LocalWebServerResponse)

enum LocalWebServerRequestMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
}

protocol GCDWebServerDataResponseConvertible {
    
    func convertedToGCDWebServerDataResponse() -> GCDWebServerDataResponse
}

protocol LocalWebServerDelegate: class {
    
    func localWebServer(_ server: LocalWebServer, didCreateDirectoryAtPath path: String)
    func localWebServer(_ server: LocalWebServer, didDeleteItemAtPath path: String)
    func localWebServer(_ server: LocalWebServer, didDownloadFileAtPath path: String)
    func localWebServer(_ server: LocalWebServer, didMoveItemFromPath fromPath: String, toPath: String)
    func localWebServer(_ server: LocalWebServer, didUploadFileAtPath path: String)
}

extension LocalWebServerResponse: GCDWebServerDataResponseConvertible {
    
    func convertedToGCDWebServerDataResponse() -> GCDWebServerDataResponse {
        
        if let jsonObject = self.response {
            return GCDWebServerDataResponse(jsonObject: jsonObject)
        } else {
            return GCDWebServerDataResponse(statusCode: self.statusCode.rawValue)
        }
    }
}

final class LocalWebServer: NSObject {
    
    struct Constants {
        static let defaultPort: UInt = 8080
    }
    
    private let localWebServer = GCDWebUploader()
    
    weak var delegate: LocalWebServerDelegate?
    
    func start() {
        startWithPort(Constants.defaultPort)
    }
    
    func startWithPort(_ port: UInt) {
        localWebServer?.delegate = self
        localWebServer?.start(withPort: port, bonjourName: nil)
    }
    
    func stop() {
        localWebServer?.stop()
    }
    
    func addSandboxDirectory(_ path: String, endpoint: String) {
        localWebServer?.addDirectory(path, endpoint: endpoint)
    }
    
    func addHandlerForMethod(_ method: LocalWebServerRequestMethod, path: String, handler: @escaping LocalWebServerRequestHandler) {
        
        localWebServer?.addHandler(forMethod: method.rawValue,
                                   path: path,
                                   request: GCDWebServerURLEncodedFormRequest.self) { (request) -> GCDWebServerResponse! in
            
            let params = self.paramsForRequest(request as? GCDWebServerURLEncodedFormRequest)
            var response: LocalWebServerResponse?
            self.executeOnMainQueue {
                response = handler(params)
            }
            
            return response?.convertedToGCDWebServerDataResponse()
        }
    }
    
    private func executeOnMainQueue(_ closure: (() -> Void)?) {
        DispatchQueue.main.sync { closure?() }
    }
    
    private func paramsForRequest(_ request: GCDWebServerURLEncodedFormRequest?) -> InsiderMessage? {
        guard let request = request, LocalWebServerRequestMethod(rawValue: request.method) != .GET else {
            return nil
        }
        
        var params: InsiderMessage?
        let contentType = request.contentType
        let jsonTypes = ["application/json", "text/json", "text/javascript"]
        if jsonTypes.contains(contentType!) {
            if let json = request.jsonObject {
                params = json as? InsiderMessage
            }
        } else {
            if let encodedParams = request.arguments {
                params = encodedParams as InsiderMessage?
            }
        }
        
        return params
    }
}

extension LocalWebServer: GCDWebUploaderDelegate {
    
    func webUploader(_ uploader: GCDWebUploader!, didCreateDirectoryAtPath path: String!) {
        delegate?.localWebServer(self, didCreateDirectoryAtPath: path)
    }
    
    func webUploader(_ uploader: GCDWebUploader!, didDeleteItemAtPath path: String!) {
        delegate?.localWebServer(self, didDeleteItemAtPath: path)
    }
    
    func webUploader(_ uploader: GCDWebUploader!, didDownloadFileAtPath path: String!) {
        delegate?.localWebServer(self, didDownloadFileAtPath: path)
    }
    
    func webUploader(_ uploader: GCDWebUploader!, didMoveItemFromPath fromPath: String!, toPath: String!) {
        delegate?.localWebServer(self, didMoveItemFromPath: fromPath, toPath: toPath)
    }
    
    func webUploader(_ uploader: GCDWebUploader!, didUploadFileAtPath path: String!) {
        delegate?.localWebServer(self, didUploadFileAtPath: path)
    }
}
