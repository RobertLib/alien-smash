//
//  GameButton.swift
//  AlienSmash
//
//  Created by Robert Libšanský on 12.05.2025.
//

import SpriteKit

class GameButton: SKShapeNode {

    private var buttonLabel: SKLabelNode!
    var onPressed: (() -> Void)?

    init(text: String, size: CGSize = CGSize(width: 200, height: 50)) {
        super.init()

        self.path = CGPath(
            roundedRect: CGRect(
                origin: CGPoint(x: -size.width / 2, y: -size.height / 2),
                size: size),
            cornerWidth: 15,
            cornerHeight: 15,
            transform: nil)
        self.fillColor = UIColor(white: 0.3, alpha: 1.0)
        self.strokeColor = .white
        self.lineWidth = 2
        self.zPosition = 10
        self.name = "button"

        setupLabel(text: text)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLabel(text: String) {
        buttonLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        buttonLabel.text = text
        buttonLabel.fontSize = 30
        buttonLabel.fontColor = .white
        buttonLabel.position = CGPoint.zero
        buttonLabel.verticalAlignmentMode = .center
        buttonLabel.horizontalAlignmentMode = .center
        buttonLabel.name = "button"
        addChild(buttonLabel)
    }

    func fadeIn(after delay: TimeInterval = 0.0) {
        self.setScale(0.1)
        self.alpha = 0.0

        let delayAction = SKAction.wait(forDuration: delay)
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.5)
        let group = SKAction.group([fadeIn, scaleUp])

        self.run(SKAction.sequence([delayAction, group]))
    }

    func fadeOut(completion: (() -> Void)? = nil) {
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.5)
        let group = SKAction.group([fadeOut, scaleUp])

        self.run(group) {
            completion?()
        }
    }

    func handleTouch(_ touchLocation: CGPoint) -> Bool {
        if self.contains(touchLocation) {
            onPressed?()
            return true
        }
        return false
    }
}
