//
//  AppDelegate.swift
//  CoolSpot
//
//  Created by Boris Bügling on 15/06/14.
//  Copyright (c) 2014 Boris Bügling. All rights reserved.
//

import KeychainAccess
import Keys
import Spotify
import UIKit

let kClientId               = CoolSpotKeys().spotifyClientId()
let kCallbackURL            = "coolspot://callback"
let kSessionUserDefaultsKey = "SpotifySession"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let keychain = Keychain(service: kClientId)
    var auth: SPTAuth {
        let auth = SPTAuth.defaultInstance()
        auth.clientID = kClientId
        auth.redirectURL = NSURL(string: kCallbackURL)
        auth.requestedScopes = [SPTAuthUserReadPrivateScope]
        return auth
    }
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        var validSession = false

        if let data = keychain.getData(kSessionUserDefaultsKey), session = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? SPTSession {
            if session.isValid() {
                self.enableAudioPlaybackWithSession(session)
                validSession = true
            }
        }

        if !validSession {
            var loginURL = auth.loginURL

            var delayInSeconds = 0.1
            var popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delayInSeconds * Double(NSEC_PER_SEC)))
            dispatch_after(popTime, dispatch_get_main_queue(), {
                UIApplication.sharedApplication().openURL(loginURL)
                return
            })
        }
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window?.backgroundColor = UIColor.whiteColor()
        self.window?.rootViewController = UIViewController()
        self.window?.makeKeyAndVisible()
        
        return true
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        
        var authCallback = { (error: NSError?, session: SPTSession?) -> Void in
            if let error = error {
                NSLog("*** Auth error: %@", error)
                return
            }

            if let session = session {
                self.keychain.set( NSKeyedArchiver.archivedDataWithRootObject(session), key: kSessionUserDefaultsKey)
                self.enableAudioPlaybackWithSession(session)
            }
        }
        
        if (auth.canHandleURL(url)) {
            auth.handleAuthCallbackWithTriggeredAuthURL(url, callback:authCallback)
            return true
        }
        
        return false
    }
    
    func enableAudioPlaybackWithSession(session: SPTSession!) {
        //var viewController = self.window!.rootViewController
        //viewController.handleNewSession(session)
    }
}
