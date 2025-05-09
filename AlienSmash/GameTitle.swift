//
//  GameTitle.swift
//  AlienSmash
//
//  Created by Robert Libšanský on 12.05.2025.
//

import SpriteKit

class GameTitle: SKLabelNode {

    init(text: String, fontSize: CGFloat = 42) {
        super.init()

        self.fontName = "Helvetica-Bold"
        self.text = text
        self.fontSize = fontSize
        self.fontColor = .white
        self.horizontalAlignmentMode = .center
        self.verticalAlignmentMode = .center
        self.zPosition = 10
        self.alpha = 0.0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func fadeIn() {
        let fadeIn = SKAction.fadeIn(withDuration: 1.0)
        self.run(fadeIn) {
            self.startPulseAnimation()
        }
    }

    func startPulseAnimation() {
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        let pulseContinously = SKAction.repeatForever(pulse)

        self.run(pulseContinously)
    }

    func fadeOut(duration: TimeInterval = 0.5, completion: (() -> Void)? = nil) {
        let fadeOut = SKAction.fadeOut(withDuration: duration)
        let scaleUp = SKAction.scale(to: 1.2, duration: duration)
        let group = SKAction.group([fadeOut, scaleUp])

        self.run(group) {
            completion?()
        }
    }
}
