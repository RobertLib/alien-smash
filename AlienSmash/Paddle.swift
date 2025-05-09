//
//  Paddle.swift
//  AlienSmash
//
//  Created by Robert Libšanský on 09.05.2025.
//

import SpriteKit

class Paddle: SKSpriteNode {

    init(size: CGSize = CGSize(width: 120, height: 20)) {
        super.init(texture: nil, color: .white, size: size)
        setupPaddle()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPaddle() {
        zPosition = 1

        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = PhysicsCategory.paddle
        physicsBody?.contactTestBitMask =
            PhysicsCategory.ball | PhysicsCategory.alien | PhysicsCategory.alienBullet
        physicsBody?.collisionBitMask = PhysicsCategory.none
        physicsBody?.usesPreciseCollisionDetection = true
    }

    func moveHorizontally(to xPosition: CGFloat, in frame: CGRect) {
        let minX = size.width / 2
        let maxX = frame.width - size.width / 2

        position.x = min(maxX, max(minX, xPosition))
    }
}
