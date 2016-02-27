//
//  ShellCommand.swift
//  Sparkler
//
//  Created by Matias Piipari on 24/02/2016.
//  Copyright © 2016 Manuscripts.app Limited. All rights reserved.
//

import Foundation

enum ShellCommandError:ErrorType {
    case NonzeroTerminationStatus
}

// http://stackoverflow.com/questions/26971240/how-do-i-run-an-terminal-command-in-a-swift-script-e-g-xcodebuild
func executeTask(launchPath: String, arguments: [String]) throws -> String
{
    let task = NSTask()
    task.launchPath = launchPath
    task.arguments = arguments
    
    let pipe = NSPipe()
    task.standardOutput = pipe
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: NSUTF8StringEncoding)!
    if output.characters.count > 0 {
        return output.substringToIndex(output.endIndex.advancedBy(-1))
    }
    
    if task.terminationStatus != 0 {
        throw ShellCommandError.NonzeroTerminationStatus
    }
    
    return output
}

