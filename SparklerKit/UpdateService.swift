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
    case BadAuthenticationCredentials
}

public struct UpdateService {
    let baseURL:NSURL
    
    let app:String
    let feed:String
    
    let username:String
    let password:String
    
    public init(baseURL:NSURL, app:String, feed:String, username:String, password:String) {
        self.baseURL = baseURL
        self.app = app
        self.feed = feed
        self.username = username
        self.password = password
    }
    
    var versionsURL:NSURL { get {
            return self.baseURL.URLByAppendingPathComponent("apps/\(app)/\(feed)/versions")
        }
    }
    
    func versionURL(version:Version) -> NSURL {
        return self.versionsURL.URLByAppendingPathComponent(version.version)
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
    
    private func ensureBasicAuthenticationHeaders(req:NSMutableURLRequest) throws -> Void {
        let loginString = "\(self.username):\(self.password)"
        guard let loginData = loginString.dataUsingEncoding(NSUTF8StringEncoding) else {
            throw UpdateServiceError.BadAuthenticationCredentials
        }
        
        let base64LoginString = loginData.base64EncodedStringWithOptions([])
        req.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
    }
    
    public func update(version version:Version) throws -> Bool {
        fputs("Updating version \(version.version)\n", __stderrp)
        
        let req = NSMutableURLRequest(URL: self.versionURL(version))
        try self.ensureBasicAuthenticationHeaders(req)
        req.HTTPMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Accepts")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.HTTPBody = try version.toJSON().serialize()
        
        let data = try NSString(data: version.toJSON().serialize(), encoding: NSUTF8StringEncoding)!
        print (data)
        
        let responseData = try NSURLConnection.sendSynchronousRequest(req, returningResponse: nil)
        
        // doing it this way because NSURLConnection.sendSynchronousRequest seems to have issues in Swift accepting the response…
        do {
            let responseJSON = try JSON(data:responseData)
            let version = try Version(json: responseJSON)
            print(version)
            return true
        }
        catch let e {
            fputs("Error occurred: \(e)", __stderrp)
            return false
        }
    }
}