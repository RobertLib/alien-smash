//
//  StarField.swift
//  AlienSmash
//
//  Created by Robert Libšanský on 10.05.2025.
//

import SpriteKit

class StarField: SKNode {

    private let starCount: Int
    private let screenSize: CGSize
    private var stars: [SKShapeNode] = []

    private let starSpeeds: [CGFloat] = [15, 30, 50]
    private let starSizes: [CGFloat] = [1, 1.5, 2]
    private let starColors: [UIColor] = [
        .white, UIColor(white: 1.0, alpha: 0.7), UIColor(white: 1.0, alpha: 0.5),
    ]

    init(size: CGSize, starCount: Int = 100) {
        self.screenSize = size
        self.starCount = starCount
        super.init()

        setupStars()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupStars() {
        for _ in 0..<starCount {
            createStar()
        }
    }

    private func createStar() {
        let speedIndex = Int.random(in: 0..<starSpeeds.count)
        let starSize = starSizes[speedIndex]
        let star = SKShapeNode(circleOfRadius: starSize)
        star.fillColor = starColors[speedIndex]
        star.strokeColor = .clear
        star.glowWidth = 0.3

        star.position = CGPoint(
            x: CGFloat.random(in: 0...screenSize.width),
            y: CGFloat.random(in: 0...screenSize.height)
        )

        star.userData = NSMutableDictionary()
        star.userData?["speed"] = starSpeeds[speedIndex]
        star.userData?["blinkTimer"] = Double.random(in: 0...3)

        star.zPosition = -100 + CGFloat(speedIndex)

        stars.append(star)
        addChild(star)
    }

    func update(deltaTime: TimeInterval) {
        for star in stars {
            guard let userData = star.userData else { continue }

            if let speed = userData["speed"] as? CGFloat {
                star.position.y -= speed * CGFloat(deltaTime)

                if star.position.y < 0 {
                    star.position.y = screenSize.height
                    star.position.x = CGFloat.random(in: 0...screenSize.width)
                }
            }

            if var blinkTimer = userData["blinkTimer"] as? Double {
                blinkTimer -= deltaTime

                if blinkTimer <= 0 {
                    let blink = SKAction.sequence([
                        SKAction.fadeOut(withDuration: 0.1),
                        SKAction.fadeIn(withDuration: 0.1),
                    ])
                    star.run(blink)

                    blinkTimer = Double.random(in: 1...5)
                }

                userData["blinkTimer"] = blinkTimer
            }
        }
    }
}
