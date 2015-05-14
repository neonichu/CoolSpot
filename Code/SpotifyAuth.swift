//
//  SpotifyAuth.swift
//  CoolSpot
//
//  Created by Boris Bügling on 14/05/15.
//  Copyright (c) 2015 Boris Bügling. All rights reserved.
//

import Foundation
import KeychainAccess
import Keys
import Spotify

private let kClientId               = CoolSpotKeys().spotifyClientId()
private let kCallbackURL            = "coolspot://callback"
private let kSessionUserDefaultsKey = "SpotifySession"
private let kTokenRefreshURL        = CoolSpotKeys().spotifyTokenRefreshURL()
private let kTokenSwapURL           = CoolSpotKeys().spotifyTokenSwapURL()

public class SpotifyAuth {
    private var auth: SPTAuth {
        let auth = SPTAuth.defaultInstance()
        auth.clientID = kClientId
        auth.redirectURL = NSURL(string: kCallbackURL)
        auth.requestedScopes = [SPTAuthUserReadPrivateScope, SPTAuthUserLibraryReadScope, SPTAuthStreamingScope]
        auth.tokenRefreshURL = NSURL(string: kTokenRefreshURL)
        auth.tokenSwapURL = NSURL(string: kTokenSwapURL)
        return auth
    }
    private let keychain = Keychain(service: kClientId)

    public var clientID: String { return auth.clientID }
    public var log: (String) -> Void = { (_) in return }
    public var session: SPTSession!
    public var startPlayback: () -> Void = { }

    public func start() {
        if let data = keychain.getData(kSessionUserDefaultsKey), session = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? SPTSession {
            auth.session = session

            if session.isValid() {
                self.session = session
                startPlayback()
            } else {
                auth.sessionUserDefaultsKey = "spotifySession"
                auth.renewSession(session) { (error, session) in
                    if let error = error {
                        self.log(String(format: "Token refresh error: %@", error))
                        return
                    }

                    if let session = session {
                        self.session = session
                        self.startPlayback()
                    }
                }
            }
        } else {
            var loginURL = auth.loginURL

            var delayInSeconds = 0.1
            var popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delayInSeconds * Double(NSEC_PER_SEC)))
            dispatch_after(popTime, dispatch_get_main_queue(), {
                UIApplication.sharedApplication().openURL(loginURL)
                return
            })
        }
    }

    public func handleOpenURL(url: NSURL) -> Bool {
        var authCallback = { (error: NSError?, session: SPTSession?) -> Void in
            if let error = error {
                self.log(String(format: "Auth error: %@", error))
                return
            }

            if let session = session {
                self.keychain.set( NSKeyedArchiver.archivedDataWithRootObject(session), key: kSessionUserDefaultsKey)
                self.session = session
                self.startPlayback()
            }
        }

        if (auth.canHandleURL(url)) {
            auth.handleAuthCallbackWithTriggeredAuthURL(url, callback:authCallback)
            return true
        }

        return false
    }
}
