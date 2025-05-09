//
//  GameViewController.swift
//  AlienSmash
//
//  Created by Robert Libšanský on 09.05.2025.
//

import GameplayKit
import SpriteKit
import UIKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        if let view = self.view as! SKView? {
            let welcomeScene = WelcomeScene(size: CGSize(width: 750, height: 1334))
            welcomeScene.scaleMode = .aspectFit
            view.presentScene(welcomeScene)

            view.ignoresSiblingOrder = true

            #if DEBUG
                view.showsFPS = true
                view.showsNodeCount = true
            #endif

            view.preferredFramesPerSecond = 60
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
