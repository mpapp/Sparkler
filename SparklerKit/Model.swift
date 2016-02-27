//
//  Delta.swift
//  Sparkler
//
//  Created by Matias Piipari on 24/02/2016.
//  Copyright © 2016 Manuscripts.app Limited. All rights reserved.
//

import Foundation
import Darwin

enum VersionError : ErrorType {
    case BadPrivateKeyPath
    case PrivateKeyMissing(String)
}

struct Delta {
    let url:String
    let identifier:String
    let fromVersion:String
    let toVersion:String
    let signature:String
    let length:UInt
    let fromVersionSignature:String
    let toVersionSignature:String
}

public struct Version {
    var localURL:NSURL?
    var downloadURL:NSURL?
    
    let version:String
    let shortVersion:String
    let signature:String
    let length:UInt
    
    public static func listVersionsAtDirectoryURL(directoryURL:NSURL, signUpdateURL:NSURL, privateKeyURL:NSURL) throws -> [Version] {
        
        guard let privateKeyPath = privateKeyURL.path else {
            throw VersionError.BadPrivateKeyPath
        }
        
        guard NSFileManager.defaultManager().fileExistsAtPath(privateKeyPath) else {
            throw VersionError.PrivateKeyMissing(privateKeyPath)
        }
        
        let files = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(directoryURL, includingPropertiesForKeys: [NSFileSize], options: .SkipsSubdirectoryDescendants)
        
        return try files.flatMap {
            
            guard let pathExtension = $0.pathExtension where pathExtension == "zip",
                let path = $0.path else {
                    return nil
            }
            
            let version = (path as NSString).lastPathComponent.stringByReplacingOccurrencesOfString(".zip", withString: "")
            let shortVersion = version.componentsSeparatedByString("-").first!
            
            let attribs = try NSFileManager.defaultManager().attributesOfItemAtPath(path)
            let size = (attribs[NSFileSize] as! NSNumber).unsignedIntegerValue
            
            let signature = try SignatureVerifier(signUpdatePath: signUpdateURL.path!, privateKeyPath: privateKeyURL.path!).DSASignature(path)
            
            let v = Version(localURL: $0, downloadURL: nil, version: version, shortVersion: shortVersion, signature: signature, length: size)
            
            fputs("Version: \(v)\n", __stderrp)
            
            return v
        }
    }
}