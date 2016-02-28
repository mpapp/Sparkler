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
    case MissingVersion(NSURL)
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
    
    $0.command("verify-appcast",
        Argument<String>("updateBaseURL", description:"Update service base URL."),
        Argument<String>("publicKey", description:"DSA public key path."),
        Option("working-directory", "../Updates/Builds", description:"Path to a working directory where updates downloaded from the appcast are stored."),
        Option("app", "manuscripts", description:"App name"),
        Option("feed", "alpha", description:"Feed name"))
        { updateBaseURLString, publicKey, workingDir, app, feed in
            
            let updateBaseURL = NSURL(string: updateBaseURLString)!
            let publicKeyURL = NSURL(fileURLWithPath: publicKey)
            
            let verifier = try SignatureVerifier(publicKeyPath:publicKey)
            
            let workingDirURL = NSURL(fileURLWithPath: workingDir)
            
            let updateService = UpdateService(baseURL: updateBaseURL, app: app, feed: feed)
            let appcastVersions = try updateService.appcastVersions()
            
            fputs("Verifying \(appcastVersions.count) versions…\n", __stderrp)
            for version in appcastVersions {
                fputs("Verifying \(version.version)…\n", __stderrp)
                let localURL = workingDirURL.URLByAppendingPathComponent(version.version).URLByAppendingPathExtension("zip")
                let localPath = localURL.path!
                if !NSFileManager.defaultManager().fileExistsAtPath(localURL.path!) {
                    throw SparklerError.MissingVersion(localURL)
                }
                
                let success = try verifier.verifyDSASignature(localPath, signature: version.signature)
                if !success {
                    fputs("Verification failed for \(version.version)", __stderrp)
                    exit(-2)
                }
                
                let attribs = try NSFileManager.defaultManager().attributesOfItemAtPath(localPath)
                guard let size = attribs[NSFileSize], sizeInt = size.integerValue else {
                    fputs("File size determination failed for \(localPath)", __stderrp)
                    exit(-3)
                }
            }
    }
    
    $0.command("verify",
        Argument<String>("updateBaseURL", description:"Update service base URL."),
        Argument<String>("username", description:"Update service username."),
        Argument<String>("password", description:"Update service password."),
        Option("dsa", "./dsa_priv.pem", description:"Path to DSA private key for the updates."),
        Option("app", "manuscripts", description:"App name"),
        Option("feed", "alpha", description:"Feed name"),
        Flag("repair-size", description:"Repair size field for update versions."),
        Option("sign-update", "../External/Sparkle/bin/sign_update", description:"Path to Sparkle's sign_update"),
        Option("working-directory", "../Updates/Builds", description:"Path to a working directory where updates downloaded from the appcast are stored."))
        { updateBaseURLString, username, password, dsa, app, feed, repairSizes, signUpdate, workingDir in
            
            let dsaURL = NSURL(fileURLWithPath:dsa)
            let workingDirURL = NSURL(fileURLWithPath:workingDir)
            let signUpdateURL = NSURL(fileURLWithPath:signUpdate)
            
            let updateBaseURL = NSURL(string: updateBaseURLString)!
            
            let updateService = UpdateService(baseURL: updateBaseURL, app: app, feed: feed, username:username, password:password)
            
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
                    print("Length mismatch for version \(version.version): \(matchingVersion.length) !== \(version.length).")
                    
                    if repairSizes {
                        matchingVersion.length = version.length
                        try updateService.update(version:matchingVersion)
                    }
                }
            }
    }
    
}.run()
