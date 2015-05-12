//
//  AppDelegate.swift
//  CoolSpot
//
//  Created by Boris Bügling on 15/06/14.
//  Copyright (c) 2014 Boris Bügling. All rights reserved.
//

import AVFoundation
import KeychainAccess
import Keys
import MediaPlayer
import MMWormhole
import Spotify
import UIKit

let kClientId               = CoolSpotKeys().spotifyClientId()
let kCallbackURL            = "coolspot://callback"
let kSessionUserDefaultsKey = "SpotifySession"
let kTokenRefreshURL        = CoolSpotKeys().spotifyTokenRefreshURL()
let kTokenSwapURL           = CoolSpotKeys().spotifyTokenSwapURL()

extension Array {
    func shuffled() -> [T] {
        var list = self
        for i in 0..<(list.count - 1) {
            let j = Int(arc4random_uniform(UInt32(list.count - i))) + i
            swap(&list[i], &list[j])
        }
        return list
    }
}

// MARK: - UIApplicationDelegate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SPTAudioStreamingPlaybackDelegate {
    var auth: SPTAuth {
        let auth = SPTAuth.defaultInstance()
        auth.clientID = kClientId
        auth.redirectURL = NSURL(string: kCallbackURL)
        auth.requestedScopes = [SPTAuthUserReadPrivateScope, SPTAuthUserLibraryReadScope, SPTAuthStreamingScope]
        auth.tokenRefreshURL = NSURL(string: kTokenRefreshURL)
        auth.tokenSwapURL = NSURL(string: kTokenSwapURL)
        return auth
    }
    let keychain = Keychain(service: kClientId)
    let wormhole = MMWormhole(applicationGroupIdentifier: AppGroupIdentifier, optionalDirectory: AppGroupIdentifier)

    var player: SPTAudioStreamingController!
    var session: SPTSession!
    var window: UIWindow?

    // MARK: - Application lifecycle

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        var validSession = false

        if let data = keychain.getData(kSessionUserDefaultsKey), session = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? SPTSession {
            if session.isValid() {
                self.session = session
                self.startPlayback()
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

        AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, error: nil)
        return true
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        
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

    func application(application: UIApplication, handleWatchKitExtensionRequest userInfo: [NSObject : AnyObject]?, reply: (([NSObject : AnyObject]!) -> Void)!) {
        application.beginBackgroundTaskWithExpirationHandler() { }
    }

    // MARK: - Logging

    func log(message: String) {
        NSLog("%@", message)

        wormhole.passMessageObject(message, identifier: Errors)
    }

    // MARK: - Spotify
    
    func startPlayback() {
        player = SPTAudioStreamingController(clientId: auth.clientID)
        player.diskCache = SPTDiskCache(capacity: 1024 * 1024 * 64)
        player.playbackDelegate = self

        player.loginWithSession(session, callback: { (error) -> Void in
            if let error = error {
                self.log(String(format: "Login error: %@", error))
            }
        })

        wormhole.listenForMessageWithIdentifier(Next) { (reply) in
            if let reply: AnyObject = reply {
                self.player.skipNext({ (error) -> Void in
                    if let error = error {
                        self.log(String(format: "could not skip: %@", error))
                    }
                })
            }
        }

        wormhole.listenForMessageWithIdentifier(Stop) { (reply) in
            if let reply: AnyObject = reply {
                self.play()
            }
        }

        SPTYourMusic.savedTracksForUserWithAccessToken(session.accessToken, callback: { (error, result) -> Void in
            if let result = result as? SPTListPage {
                self.fetchAll(result) { (tracks) in
                    let uris = SPTTrack.urisFromArray(tracks.shuffled())

                    self.player.playURIs(uris, fromIndex: 0) { (error) -> Void in
                        if let error = error {
                            self.log(String(format: "playURIs error: %@", error))
                        }
                    }
                }
            }
        })


    }

    func fetchAll(listPage: SPTListPage, _ callback: (tracks: [SPTSavedTrack]) -> Void) {
        if listPage.hasNextPage {
            listPage.requestNextPageWithSession(session, callback: { (error, page) -> Void in
                if let page = page as? SPTListPage {
                    self.fetchAll(listPage.pageByAppendingPage(page), callback)
                }
            })
        } else {
            if let items = listPage.items as? [SPTSavedTrack] {
                callback(tracks: items)
            }
        }
    }

    func play() {
        self.player.setIsPlaying(!self.player.isPlaying, callback: { (error) -> Void in
            if let error = error {
                self.log(String(format: "setIsPlaying error: %@", error))
            }
        })
    }

    // MARK: - SPTAudioStreamingPlaybackDelegate

    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didStartPlayingTrack trackUri: NSURL!) {
        SPTTrack.trackWithURI(trackUri, session: session) { (error, track) -> Void in
            if let error = error {
                self.log(String(format: "trackWithURI error: %@", error))
            }

            if let track = track as? SPTTrack, artist = track.artists.first as? SPTPartialArtist {
                var info: [String:AnyObject] = [ MPMediaItemPropertyTitle: track.name, MPMediaItemPropertyArtist: artist.name ]

                self.wormhole.passMessageObject([ Track.ArtistName.rawValue: artist.name, Track.TrackName.rawValue: track.name ], identifier: TrackInfo)

                let largeAlbumArtUrl = track.album.largestCover.imageURL
                NSURLConnection.sendAsynchronousRequest(NSURLRequest(URL: largeAlbumArtUrl), queue: NSOperationQueue.mainQueue()) { (_, data, _) -> Void in
                    if let data = data, image = UIImage(data: data), itemImage = MPMediaItemArtwork(image: image) {
                        info[MPMediaItemPropertyArtwork] = itemImage
                    }

                    let center = MPNowPlayingInfoCenter.defaultCenter()
                    center.nowPlayingInfo = info
                }

                let albumArtUrl = track.album.smallestCover.imageURL
                NSURLConnection.sendAsynchronousRequest(NSURLRequest(URL: albumArtUrl), queue: NSOperationQueue.mainQueue()) { (_, data, _) -> Void in
                    if let data = data {
                        self.wormhole.passMessageObject([ Track.AlbumArt.rawValue: data ], identifier: TrackInfo)
                    }
                }
            }
        }
    }

    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        AVAudioSession.sharedInstance().setActive(isPlaying, error: nil)

        let center = MPRemoteCommandCenter.sharedCommandCenter()

        center.playCommand.addTarget(self, action: "play")
        center.playCommand.enabled = true

        center.pauseCommand.addTarget(self, action: "play")
        center.pauseCommand.enabled = true

        center.togglePlayPauseCommand.addTarget(self, action: "play")
        center.togglePlayPauseCommand.enabled = true
    }

    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didFailToPlayTrack trackUri: NSURL!) {
        log(String(format: "Failed to play track: %@", trackUri))
    }
}
