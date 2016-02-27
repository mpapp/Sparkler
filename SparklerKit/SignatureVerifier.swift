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
}

struct SignatureVerifier {
    
    let signUpdatePath:String
    let privateKeyPath:String
    
    init(signUpdatePath:String, privateKeyPath:String) throws {
        if !NSFileManager.defaultManager().fileExistsAtPath(signUpdatePath) {
            throw SignatureVerifierError.BadSignUpdatePath(signUpdatePath)
        }
        
        self.signUpdatePath = signUpdatePath
        self.privateKeyPath = privateKeyPath
    }
    
    func DSASignature(path:String) throws -> String {
        return try executeTask(self.signUpdatePath, arguments: [path, privateKeyPath])
    }
}