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

Group {
    
    $0.command("download",
        Argument<String>("appcast", description:"Path to the appcast whose entries we are to create deltas for."),
        Option("number", 10, description:"Number or appcast items to build a delta for."),
        Option("dsa", "", description:"Path to DSA private key for the updates."),
        Option("working-directory", "", description:"Path to a working directory where updates downloaded from the appcast are stored."))
        { appcast, number, dsa, workingDir in
            
        
    }
}.run()
