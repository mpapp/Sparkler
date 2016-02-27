#!/usr/bin/env swift

//
//  main.swift
//  Sparkler
//
//  Created by Matias Piipari on 24/02/2016.
//  Copyright © 2016 Manuscripts.app Limited. All rights reserved.
//

import Foundation
import SparklerKit
import Commander

import Darwin

Group {
    
    $0.command("version") {
        guard let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] else {
            fputs("Failed not determine version.", __stderrp)
            return
        }
        print(version)
    }
    
    $0.command("download",
        Argument<String>("appcast", description:"Path to the appcast whose entries we are to create deltas for."),
        Option("number", 10, description:"Number or appcast items to build a delta for."),
        Option("dsa", "./dsa_priv.pem", description:"Path to DSA private key for the updates."),
        Option("sign-update", "../External/Sparkle/bin/sign_update", description:"Path to Sparkle's sign_update"),
        Option("working-directory", "../Updates/Builds", description:"Path to a working directory where updates downloaded from the appcast are stored."))
        { appcast, number, dsa, signUpdate, workingDir in
        
            
        
    }
    
    $0.command("verify",
        Argument<String>("appcast", description:"Path to the appcast whose entries we are to verify."),
        Option("dsa", "./dsa_priv.pem", description:"Path to DSA private key for the updates."),
        Option("sign-update", "../External/Sparkle/bin/sign_update", description:"Path to Sparkle's sign_update"),
        Option("working-directory", "../Updates/Builds", description:"Path to a working directory where updates downloaded from the appcast are stored."))
        { appcast, dsa, signUpdate, workingDir in
            
            let dsaURL = NSURL(fileURLWithPath:dsa)
            let workingDirURL = NSURL(fileURLWithPath:workingDir)
            let signUpdateURL = NSURL(fileURLWithPath:signUpdate)
            
            let versions = try Version.listVersionsAtDirectoryURL(workingDirURL, signUpdateURL:signUpdateURL, privateKeyURL: dsaURL)
            
            for version in versions {
                print(version)
            }
    }
    
}.run()
