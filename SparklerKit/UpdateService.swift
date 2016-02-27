//
//  UpdateService.swift
//  Sparkler
//
//  Created by Matias Piipari on 27/02/2016.
//  Copyright © 2016 Manuscripts.app Limited. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

enum UpdateServiceError: ErrorType {
    case MissingResultValue
    case MissingVersionMetadata(AnyObject)
}

struct UpdateService {
    let baseURL:NSURL
    
    let app:String
    let feed:String
    
    init(baseURL:NSURL, app:String, feed:String) {
        self.baseURL = baseURL
        self.app = app
        self.feed = feed
    }
    
    var versionsURL:NSURL { get {
            return self.baseURL.URLByAppendingPathComponent("apps/\(app)/\(feed)/versions")
        }
    }
    
    func listVersions(errorHandler:(ErrorType)->Void, versionsHandler:([Version])->Void) {
        Alamofire.request(.GET, self.versionsURL).responseJSON { (response:Response<AnyObject, NSError>) -> Void in
            if let error = response.result.error {
                errorHandler(error)
                return
            }
            
            guard let json = response.result.value else {
                errorHandler(UpdateServiceError.MissingResultValue)
                return
            }
            
            let versionsJSON = JSON(json)
            
            do {
                let versions:[Version] = try versionsJSON.map { _ in
                    
                    guard let downloadURL:NSURL = versionsJSON["downloadURL"].URL,
                          let version:String = versionsJSON["version"].string,
                          let shortVersion:String = versionsJSON["shortVersion"].string,
                          let signature:String = versionsJSON["signature"].string,
                          let length:UInt = versionsJSON["length"].number?.unsignedIntegerValue else {
                        throw UpdateServiceError.MissingVersionMetadata(json)
                    }
                    
                    return Version(localURL:nil,
                                    downloadURL:downloadURL,
                                    version:version,
                                    shortVersion:shortVersion,
                                    signature:signature,
                                    length:length)
                }
                
                versionsHandler(versions)
            }
            catch UpdateServiceError.MissingVersionMetadata(let obj) {
                errorHandler(UpdateServiceError.MissingVersionMetadata(obj))
                return
            }
            catch { fatalError("Only expected error is UpdateServiceError.MissingVersionMetadata") }
        }
    }
}