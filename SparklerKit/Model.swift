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

public struct Delta: JSONDecodable, JSONEncodable {
    public let url:String
    public let identifier:String
    public let fromVersion:String
    public let toVersion:String
    public let signature:String
    public let length:UInt
    public var fromVersionSignature:String?
    public var toVersionSignature:String?
    
    public init(url:String,
                identifier:String,
                fromVersion:String,
                toVersion:String,
                signature:String,
                length:UInt,
                fromVersionSignature:String?,
                toVersionSignature:String?) {
        self.url = url
        self.identifier = identifier
        self.fromVersion = fromVersion
        self.toVersion = toVersion
        self.signature = signature
        self.length = length
        self.fromVersionSignature = fromVersionSignature
        self.toVersionSignature = toVersionSignature
    }
    
    public init(json: JSON) throws {
        self.url = try json.string("url")
        self.identifier = try json.string("identifier")
        self.fromVersion = try json.string("fromVersion")
        self.toVersion = try json.string("toVersion")
        self.signature = try json.string("signature")
        self.length = UInt(try json.int("length"))
        self.fromVersionSignature = try json.string("fromVersionSignature")
        self.toVersionSignature = try json.string("toVersionSignature")
    }
    
    public func toJSON() -> JSON {
        guard let fromVersionSignature = self.fromVersionSignature else {
            fatalError("Missing fromVersionSignature")
        }
        guard let toVersionSignature = self.toVersionSignature else {
            fatalError("Missing toVersionSignature")
        }
        
        return .Dictionary(["url": .String(self.url),
                            "identifier": .String(self.identifier),
                            "fromVersion": .String(self.fromVersion),
                            "toVersion": .String(self.toVersion),
                            "signature": .String(self.signature),
                            "length": .Int(Int(self.length)),
                            "fromVersionSignature": .String(fromVersionSignature),
                            "toVersionSignature": .String(toVersionSignature)])
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

            let signature = try SignatureVerifier(signUpdatePath: signUpdateURL.path!, privateKeyPath: privateKeyURL.path!, publicKeyPath: "").DSASignature(path)
            
            let v = Version(localURL: fileURL, downloadURL: nil, version: version, shortVersion: shortVersion, signature: signature, length: size)

            index += 1
            
            return v
        }
        catch let e {
            fatalError("Failed to get next item in version sequence: \(e)")
        }
    }
}

public struct Version: CustomStringConvertible, JSONDecodable, JSONEncodable {
    public var localURL:NSURL?
    public var downloadURL:NSURL?
    
    public let version:String
    public let shortVersion:String
    public let signature:String
    public var length:UInt
   
    public var deltas:[Delta]
    
    public init(localURL:NSURL?, downloadURL:NSURL?, version:String, shortVersion:String, signature:String, length:UInt) {
        self.localURL = localURL
        self.downloadURL = downloadURL
        self.version = version
        self.shortVersion = shortVersion
        self.signature = signature
        self.length = length
        
        self.deltas = []
    }
    
    public init(json: JSON) throws {
        self.downloadURL = NSURL(string:try json.string("url"))
        self.version = try json.string("version")
        self.shortVersion = try json.string("shortVersion")
        self.signature = try json.string("signature")
        self.length = UInt(try json.int("length"))
        
        self.deltas = try json.array("deltas").map(Delta.init)
    }
    
    public func toJSON() -> JSON {
        guard let downloadURL = self.downloadURL else {
            fatalError("Attempting to JSON serialize version with no download URL: \(self)")
        }
        
        return .Dictionary(["url":.String(downloadURL.absoluteString),
                            "version":.String(self.version),
                            "shortVersion":.String(self.shortVersion),
                            "signature":.String(self.signature),
                            "length":.Int(Int(self.length))])
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