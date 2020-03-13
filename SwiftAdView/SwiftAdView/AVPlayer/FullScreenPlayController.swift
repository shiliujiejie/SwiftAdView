//
//  FullScreenPlayController.swift
//  SwiftAdView
//
//  Created by mac on 2020-03-14.
//  Copyright © 2020 mac. All rights reserved.
//

import UIKit
import AVKit

class FullScreenPlayController: AVPlayerViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        player?.play()
    }
}
