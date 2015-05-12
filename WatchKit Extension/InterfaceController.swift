//
//  InterfaceController.swift
//  CoolSpot WatchKit Extension
//
//  Created by Boris Bügling on 12/05/15.
//  Copyright (c) 2015 Boris Bügling. All rights reserved.
//

import Foundation
import MMWormhole
import WatchKit

class InterfaceController: WKInterfaceController {
    @IBOutlet weak var image: WKInterfaceImage!
    let wormhole = MMWormhole(applicationGroupIdentifier: AppGroupIdentifier, optionalDirectory: AppGroupIdentifier)

    @IBAction func tapped() {
        tickle()
        wormhole.passMessageObject(Next, identifier: Next)
    }

    func tickle() {
        WKInterfaceController.openParentApplication(["": ""], reply: { (_, _) -> Void in
        })
    }

    override func willActivate() {
        super.willActivate()
        tickle()

        wormhole.listenForMessageWithIdentifier(Errors) { (reply) in
            if let reply = reply as? String {
                NSLog("%@", reply)
            }
        }

        wormhole.listenForMessageWithIdentifier(TrackInfo) { (reply) in
            if let reply = reply as? [String:AnyObject] {
                for (key, value) in reply {
                    let type = Track(rawValue: key)!

                    switch (type) {
                    case .AlbumArt:
                        if let data = value as? NSData {
                            let albumArt = UIImage(data: data)
                            self.image.setImage(albumArt)
                        }
                        break

                    case .ArtistName:
                        break

                    case .TrackName:
                        if let name = value as? String {
                            self.setTitle(name)
                        }
                        break
                    }
                }
            }
        }
    }
}
