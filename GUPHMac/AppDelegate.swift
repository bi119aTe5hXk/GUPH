//
//  AppDelegate.swift
//  GUPHMac
//
//  Created by billgateshxk on 2020/11/30.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        UserDefaults.standard.register(defaults: ["csrftokenArr":["","","","",""]])
        UserDefaults.standard.register(defaults: ["sessionidArr":["","","","",""]])
        UserDefaults.standard.register(defaults: ["query_hashArr":["","","","",""]])
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

