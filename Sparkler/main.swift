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

enum SparklerError : ErrorType {
    case VersionListingFailed
}

Group {
    
    $0.command("version") {
        guard let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] else {
            fputs("Failed not determine version.\n", __stderrp)
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
        //Argument<String>("appcast", description:"Path to the appcast whose entries we are to verify."),
        Argument<String>("updateBaseURL", description:"Update service base URL."),
        Option("dsa", "./dsa_priv.pem", description:"Path to DSA private key for the updates."),
        Option("app", "manuscripts", description:"App name"),
        Option("feed", "alpha", description:"Feed name"),
        Flag("repair-size", description:"Repair size field for update versions."),
        Option("sign-update", "../External/Sparkle/bin/sign_update", description:"Path to Sparkle's sign_update"),
        Option("working-directory", "../Updates/Builds", description:"Path to a working directory where updates downloaded from the appcast are stored."))
        { updateBaseURLString, dsa, app, feed, repairSizes, signUpdate, workingDir in
            
            let dsaURL = NSURL(fileURLWithPath:dsa)
            let workingDirURL = NSURL(fileURLWithPath:workingDir)
            let signUpdateURL = NSURL(fileURLWithPath:signUpdate)
            
            let updateBaseURL = NSURL(string: updateBaseURLString)!
            
            let updateService = UpdateService(baseURL: updateBaseURL, app: app, feed: feed)
            
            fputs("Getting versions from \(updateBaseURL)\n", __stderrp)
            
            let serviceVersions = try updateService.listVersions()
            
            for version in try Version.listVersionsAtDirectoryURL(workingDirURL, signUpdateURL:signUpdateURL, privateKeyURL: dsaURL) {
                
                var matchingVersionOpt = serviceVersions.filter { (v:Version) -> Bool in
                    return v.version == version.version
                }.first
                
                guard var matchingVersion = matchingVersionOpt else {
                    fputs("Skipping \(version.version) because failed to find matching version for it.\n", __stderrp)
                    continue
                }

                let lengthMatch = matchingVersion.length == version.length
                if !lengthMatch {
                    print("Length mismatch for version \(version): \(matchingVersion.length) !== \(version.length)", __stderrp)
                    
                    if repairSizes {
                        matchingVersion.length = version.length
                    }
                }
            }
    }
    
}.run()
