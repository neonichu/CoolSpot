//
//  AppDelegate.swift
//  CoolSpot
//
//  Created by Boris Bügling on 15/06/14.
//  Copyright (c) 2014 Boris Bügling. All rights reserved.
//

import UIKit

let kClientId       = "spotify-ios-sdk-beta"
let kCallbackURL    = "spotify-ios-sdk-beta://callback"

let kSessionUserDefaultsKey = "SpotifySession"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        var plistRep : AnyObject! = NSUserDefaults.standardUserDefaults().valueForKey(kSessionUserDefaultsKey)
        var session = SPTSession(propertyListRepresentation:plistRep)
        
        if (session.credential? && countElements(String(session.credential)) > 0) {
            self.enableAudioPlaybackWithSession(session)
        } else {
            var auth = SPTAuth.defaultInstance()
            var loginURL = auth.loginURLForClientId(kClientId,
                declaredRedirectURL:NSURL.URLWithString(kCallbackURL), scopes:["login"])
            
            var delayInSeconds = 0.1
            var popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delayInSeconds * Double(NSEC_PER_SEC)))
            dispatch_after(popTime, dispatch_get_main_queue(), {
                UIApplication.sharedApplication().openURL(loginURL)
                return
            })
        }
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.backgroundColor = UIColor.whiteColor()
        self.window!.rootViewController = UIViewController()
        self.window!.makeKeyAndVisible()
        
        return true
    }
    
    func application(application: UIApplication!, openURL url: NSURL!, sourceApplication: String!, annotation: AnyObject!) -> Bool {
        
        var authCallback = { (error: NSError!, session: SPTSession!) -> Void in
            if (error != nil) {
                NSLog("*** Auth error: %@", error)
                return
            }
            
            NSUserDefaults.standardUserDefaults().setValue(session.propertyListRepresentation(),
                forKey:kSessionUserDefaultsKey)
            self.enableAudioPlaybackWithSession(session)
        }
        
        if (SPTAuth.defaultInstance().canHandleURL(url, withDeclaredRedirectURL:NSURL.URLWithString(kCallbackURL))) {
            SPTAuth.defaultInstance().handleAuthCallbackWithTriggeredAuthURL(url,
                tokenSwapServiceEndpointAtURL:NSURL.URLWithString("http://localhost:1234/swap"),
                callback:authCallback)
            return true
        }
        
        return false
    }
    
    func enableAudioPlaybackWithSession(session: SPTSession!) {
        //var viewController = self.window!.rootViewController
        //viewController.handleNewSession(session)
    }
    
}

