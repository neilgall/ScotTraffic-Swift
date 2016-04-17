//
//  DiagnosticEmail.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/03/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import Foundation

@objc protocol DiagnosticsEmail {
    func setSubject(subject: String)
    func setToRecipients(recipients: [String]?)
    func setMessageBody(messageBody: String, isHTML: Bool)
    func addAttachmentData(attachment: NSData, mimeType: String, fileName filename: String)
}

func populateDiagnosticsEmail(email: DiagnosticsEmail) {
    let userDefaultsDictionary = Configuration.sharedUserDefaults.dictionaryRepresentation()
    
    let device = UIDevice.currentDevice()
    let deviceData: [String: String] = [
        "name": device.name,
        "systemName": device.systemName,
        "systemVersion": device.systemVersion,
        "model": device.model
    ]

    let attachment = ["deviceData": deviceData, "userDefaults": userDefaultsDictionary]
    let attachmentData = NSKeyedArchiver.archivedDataWithRootObject(attachment)
    
    email.setSubject("ScotTraffic Beta Diagnostics")
    email.setToRecipients(["dev@scottraffic.co.uk"])
    email.setMessageBody("Diagnostic data attached", isHTML: false)
    email.addAttachmentData(attachmentData, mimeType: "application/data", fileName: "diagnostics.plist")
}

func loadUserDefaultsFromDiagnosticDataIfPresent() {
    if #available(iOS 9.0, *) {
        guard let documents = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first,
            path = NSURL(string: "diagnostics.plist", relativeToURL: documents),
            data = NSData(contentsOfURL: path) else {
                return
        }
        
        do {
            guard let diagnosticsDictionary = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? NSDictionary,
                diagnosticUserDefaults = diagnosticsDictionary["userDefaults"] as? NSDictionary else {
                fatalError("cannot unarchive diagnostic data: not a dictionary")
            }
        
            let userDefaults = Configuration.sharedUserDefaults
            
            for (key, value) in diagnosticUserDefaults {
                if let key = key as? String {
                    userDefaults.setObject(value, forKey: key)
                }
            }
        } catch {
            fatalError("cannot unarchive diagnostic data: \(error)")
        }
    }
}