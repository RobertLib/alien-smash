//
//  Paddle.swift
//  AlienSmash
//
//  Created by Robert Libšanský on 09.05.2025.
//

import SpriteKit

class Paddle: SKSpriteNode {
    private var targetPositionX: CGFloat = 0
    private let lerpFactor: CGFloat = 0.2
    private let positionTolerance: CGFloat = 0.5

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

        targetPositionX = position.x
    }

    func update(deltaTime: TimeInterval) {
        if abs(position.x - targetPositionX) < positionTolerance {
            position.x = targetPositionX
            return
        }

        position.x += (targetPositionX - position.x) * lerpFactor
    }

    func moveHorizontally(to xPosition: CGFloat, in frame: CGRect) {
        let minX = size.width / 2
        let maxX = frame.width - size.width / 2

        targetPositionX = min(maxX, max(minX, xPosition))
    }

    func synchronizeTarget() {
        targetPositionX = position.x
    }
}
