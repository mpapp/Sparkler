//
//  DSASignature.swift
//  Sparkler
//
//  Created by Matias Piipari on 24/02/2016.
//  Copyright © 2016 Manuscripts.app Limited. All rights reserved.
//

import Foundation

enum SignatureVerifierError: ErrorType {
    case BadSignUpdatePath(String)
    case BadPublicKeyPath(String)
    case BadPath(String)
}

public struct SignatureVerifier {
    
    let signUpdatePath:String
    let privateKeyPath:String
    let publicKeyPath:String
    let openSSLPath:String = "/usr/bin/openssl"
    
    public init(signUpdatePath:String, privateKeyPath:String) throws {
        try self.init(signUpdatePath:signUpdatePath, privateKeyPath:privateKeyPath, publicKeyPath:"")
    }
    
    public init(publicKeyPath:String) throws {
        try self.init(signUpdatePath:"", privateKeyPath:"", publicKeyPath:publicKeyPath)
    }
    
    public init(signUpdatePath:String, privateKeyPath:String, publicKeyPath:String) throws {
        self.signUpdatePath = signUpdatePath
        self.privateKeyPath = privateKeyPath
        self.publicKeyPath = publicKeyPath
    }
    
    public func DSASignature(path:String) throws -> String {
        if !NSFileManager.defaultManager().fileExistsAtPath(signUpdatePath) {
            throw SignatureVerifierError.BadSignUpdatePath(signUpdatePath)
        }
        
        return try executeTask(self.signUpdatePath, arguments: [path, privateKeyPath])
    }
    
    public func verifyDSASignature(path:String, signature:String) throws -> Bool {
        if self.publicKeyPath.utf8.count == 0 || !NSFileManager.defaultManager().fileExistsAtPath(self.publicKeyPath) {
            throw SignatureVerifierError.BadPublicKeyPath(self.publicKeyPath)
        }
        
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            throw SignatureVerifierError.BadPath(path)
        }
        
        let binaryDigest:NSData = try executeTask(self.openSSLPath, arguments: ["dgst", "-sha1", "-binary", path])
        
        let directory = NSTemporaryDirectory()
        
        let binaryDigestURL = NSURL.fileURLWithPathComponents([directory, NSUUID().UUIDString])!
        try binaryDigest.writeToURL(binaryDigestURL, options: [])
        
        let signatureURL = NSURL.fileURLWithPathComponents([directory, NSUUID().UUIDString])!
        try NSData(base64EncodedString: signature, options: [])!.writeToURL(signatureURL, options: [])
        
        let signatureCheckResult:String = try executeTask(self.openSSLPath, arguments: ["dgst", "-dss1", "-verify", self.publicKeyPath, "-signature", signatureURL.path!, binaryDigestURL.path!])
        
        try NSFileManager.defaultManager().removeItemAtURL(binaryDigestURL)
        try NSFileManager.defaultManager().removeItemAtURL(signatureURL)
        
        let success = signatureCheckResult == "Verified OK"
        
        if !success {
            fputs("Signature check result: \(signatureCheckResult)\n", __stderrp)
        }
        
        return success
    }
}