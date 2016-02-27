//
//  UpdateService.swift
//  Sparkler
//
//  Created by Matias Piipari on 27/02/2016.
//  Copyright © 2016 Manuscripts.app Limited. All rights reserved.
//

import Foundation
import Alamofire
import Freddy

import Darwin

enum UpdateServiceError: ErrorType {
    case MissingResultValue
    case MissingVersionMetadata(AnyObject)
}

public struct UpdateService {
    let baseURL:NSURL
    
    let app:String
    let feed:String
    
    public init(baseURL:NSURL, app:String, feed:String) {
        self.baseURL = baseURL
        self.app = app
        self.feed = feed
    }
    
    var versionsURL:NSURL { get {
            return self.baseURL.URLByAppendingPathComponent("apps/\(app)/\(feed)/versions")
        }
    }
    
    public func listVersions() throws -> [Version] {
        fputs("Listing versions at \(self.versionsURL)\n", __stderrp)
        
        let req = NSMutableURLRequest(URL: self.versionsURL)
        req.setValue("application/json", forHTTPHeaderField: "Accepts")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let response:AutoreleasingUnsafeMutablePointer<NSURLResponse?> = nil
        let responseData = try NSURLConnection.sendSynchronousRequest(req, returningResponse: response)
        
        let versions:[Version] = try JSON(data:responseData).array().map(Version.init)
        
        //print(versions)
        return versions
    }
}