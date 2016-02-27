//
//  DSASignature.swift
//  Sparkler
//
//  Created by Matias Piipari on 24/02/2016.
//  Copyright © 2016 Manuscripts.app Limited. All rights reserved.
//

import Foundation

struct SignatureVerifier {
    
    let privateKeyPath:String
    
    init(privateKeyPath:String) {
        self.privateKeyPath = privateKeyPath
    }
    
    func DSASignature(path:String) throws -> String {
        return try executeTask("./sign_update", arguments: [path, privateKeyPath])
    }
}