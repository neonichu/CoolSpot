//
//  AppDelegate.swift
//  SpotMenu
//
//  Created by Boris Bügling on 14/05/15.
//  Copyright (c) 2015 Boris Bügling. All rights reserved.
//

import Cocoa

// ¯\_AppKit & Swift_/¯
let NSSquareStatusItemLength: CGFloat = -2.0

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private var auth = SpotifyAuth()
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(notification: NSNotification) {
        auth.log = { (message) in NSLog("%@", message) }
        auth.startPlayback = self.startPlayback
        auth.start()

        statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
        statusItem.action = "itemClicked:"
        statusItem.image = NSImage(named: "dock-icon")
    }

    func handleGetURLEvent(event: NSAppleEventDescriptor!, withReplyEvent: NSAppleEventDescriptor!) {
        if let paramDescriptor = event.paramDescriptorForKeyword(AEKeyword(keyDirectObject)), urlString = paramDescriptor.stringValue, url = NSURL(string: urlString) {
            if SpotifyAuth.handleOpenURL(url) {
                NSRunningApplication.currentApplication().activateWithOptions(.ActivateAllWindows | .ActivateIgnoringOtherApps)
            }
        }
    }

    func itemClicked(statusItem: NSStatusItem) {
        if let event_ = NSApp.currentEvent, event = event_ {
            if (event.modifierFlags.rawValue & NSEventModifierFlags.ControlKeyMask.rawValue) > 0 {
                NSApplication.sharedApplication().terminate(self)
                return
            }
        }
    }

    // MARK: - Spotify

    func startPlayback() {
        
    }
}

