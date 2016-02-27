//
//  Delta.swift
//  Sparkler
//
//  Created by Matias Piipari on 24/02/2016.
//  Copyright © 2016 Manuscripts.app Limited. All rights reserved.
//

import Foundation
import Darwin
import Freddy

enum VersionError : ErrorType {
    case BadPrivateKeyPath
    case PrivateKeyMissing(String)
}

struct Delta: JSONDecodable {
    let url:String
    let identifier:String
    let fromVersion:String
    let toVersion:String
    let signature:String
    let length:UInt
    let fromVersionSignature:String
    let toVersionSignature:String
    
    init(json: JSON) throws {
        self.url = try json.string("url")
        self.identifier = try json.string("identifier")
        self.fromVersion = try json.string("fromVersion")
        self.toVersion = try json.string("toVersion")
        self.signature = try json.string("signature")
        self.length = UInt(try json.int("length"))
        self.fromVersionSignature = try json.string("fromVersionSignature")
        self.toVersionSignature = try json.string("toVersionSignature")
    }
}

public class VersionSequence : SequenceType {
    
    var index = 0
    private var files: [NSURL]
    private let signUpdateURL:NSURL
    private let privateKeyURL:NSURL
   
    init(files:[NSURL], signUpdateURL:NSURL, privateKeyURL:NSURL) {
        self.files = files
        self.signUpdateURL = signUpdateURL
        self.privateKeyURL = privateKeyURL
    }
    
    public func generate() -> VersionGenerator {
        return VersionGenerator(files:files, signUpdateURL: signUpdateURL, privateKeyURL: privateKeyURL)
    }
}

public class VersionGenerator : GeneratorType {
    
    private let files:[NSURL]
    private let signUpdateURL:NSURL
    private let privateKeyURL:NSURL
    private var index = 0
    
    init(files:[NSURL], signUpdateURL:NSURL, privateKeyURL:NSURL) {
        self.files = files
        self.signUpdateURL = signUpdateURL
        self.privateKeyURL = privateKeyURL
    }
    
    public func next() -> Version? {
        
        if index >= self.files.count {
            return nil
        }
        
        let fileURL = files[index]
        guard let pathExtension = fileURL.pathExtension where pathExtension == "zip",
              let path = fileURL.path else {
                fatalError("Expecting zip path extension and valid path: \(fileURL)")
        }
        
        do {
            
            let version = (path as NSString).lastPathComponent.stringByReplacingOccurrencesOfString(".zip", withString: "")
            
            let shortVersion = version.componentsSeparatedByString("-").first!
            
            let attribs = try NSFileManager.defaultManager().attributesOfItemAtPath(path)
            let size = (attribs[NSFileSize] as! NSNumber).unsignedIntegerValue

            let signature = try SignatureVerifier(signUpdatePath: signUpdateURL.path!, privateKeyPath: privateKeyURL.path!).DSASignature(path)
            
            let v = Version(localURL: fileURL, downloadURL: nil, version: version, shortVersion: shortVersion, signature: signature, length: size)

            index += 1
            
            return v
        }
        catch let e {
            fatalError("Failed to get next item in version sequence: \(e)")
        }
    }
}

public struct Version: CustomStringConvertible, JSONDecodable {
    public var localURL:NSURL?
    public var downloadURL:NSURL?
    
    public let version:String
    public let shortVersion:String
    public let signature:String
    public var length:UInt
   
    public init(localURL:NSURL?, downloadURL:NSURL?, version:String, shortVersion:String, signature:String, length:UInt) {
        self.localURL = localURL
        self.downloadURL = downloadURL
        self.version = version
        self.shortVersion = shortVersion
        self.signature = signature
        self.length = length
    }
    
    public init(json: JSON) throws {
        self.downloadURL = NSURL(string:try json.string("url"))
        self.version = try json.string("version")
        self.shortVersion = try json.string("shortVersion")
        self.signature = try json.string("signature")
        self.length = UInt(try json.int("length"))
    }
    
    public static func listVersionsAtDirectoryURL(directoryURL:NSURL, signUpdateURL:NSURL, privateKeyURL:NSURL) throws -> VersionSequence {
        
        guard let privateKeyPath = privateKeyURL.path else {
            throw VersionError.BadPrivateKeyPath
        }
        
        guard NSFileManager.defaultManager().fileExistsAtPath(privateKeyPath) else {
            throw VersionError.PrivateKeyMissing(privateKeyPath)
        }
        
        let files = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(directoryURL, includingPropertiesForKeys: [NSFileSize], options: .SkipsSubdirectoryDescendants)
        
        let zipFiles = files.filter({ $0.pathExtension == "zip" && $0.path != nil })
        
        return VersionSequence(files:zipFiles, signUpdateURL:signUpdateURL, privateKeyURL:privateKeyURL)
    }
    
    public var description:String { get {
            return "{version:\(version), shortVersion:\(shortVersion), length:\(length), signature:\(signature)}"
        }
    }
}