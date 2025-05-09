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
            cornerWidth: 10,
            cornerHeight: 10,
            transform: nil)

        self.fillColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 0.9)
        self.strokeColor = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0)
        self.lineWidth = 2
        self.glowWidth = 1
        self.zPosition = 10
        self.name = "button"

        let innerShadow = SKShapeNode(
            rectOf: CGSize(width: size.width - 6, height: size.height - 6),
            cornerRadius: 8)
        innerShadow.fillColor = UIColor(red: 0.15, green: 0.3, blue: 0.6, alpha: 0.8)
        innerShadow.strokeColor = .clear
        innerShadow.zPosition = -1
        addChild(innerShadow)

        setupLabel(text: text)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLabel(text: String) {
        buttonLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        buttonLabel.text = text
        buttonLabel.fontSize = 24
        buttonLabel.fontColor = UIColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 1.0)
        buttonLabel.position = CGPoint.zero
        buttonLabel.verticalAlignmentMode = .center
        buttonLabel.horizontalAlignmentMode = .center
        buttonLabel.name = "button"

        let shadowLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        shadowLabel.text = text
        shadowLabel.fontSize = 24
        shadowLabel.fontColor = UIColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 0.8)
        shadowLabel.position = CGPoint(x: 1, y: -1)
        shadowLabel.verticalAlignmentMode = .center
        shadowLabel.horizontalAlignmentMode = .center
        shadowLabel.zPosition = -1
        buttonLabel.addChild(shadowLabel)

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
            let scaleDown = SKAction.scale(to: 0.95, duration: 0.1)
            let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
            let pulse = SKAction.sequence([scaleDown, scaleUp])

            self.run(pulse)
            onPressed?()
            return true
        }
        return false
    }
}
