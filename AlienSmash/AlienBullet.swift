//
//  AlienBullet.swift
//  AlienSmash
//
//  Created by Robert Libšanský on 09.05.2025.
//

import SpriteKit

class AlienBullet: SKSpriteNode {
    private let bulletSpeed: CGFloat = 300.0

    init() {
        let size = CGSize(width: 4, height: 10)
        super.init(texture: nil, color: .yellow, size: size)
        setupBullet()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupBullet() {
        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.isDynamic = true
        physicsBody?.categoryBitMask = PhysicsCategory.alienBullet
        physicsBody?.contactTestBitMask = PhysicsCategory.paddle | PhysicsCategory.ball
        physicsBody?.collisionBitMask = PhysicsCategory.none
        physicsBody?.velocity = CGVector(dx: 0, dy: -bulletSpeed)

        let shape = SKShapeNode(rectOf: size)
        shape.fillColor = .yellow
        shape.strokeColor = .white
        addChild(shape)
    }

    func isOutOfBounds(in frame: CGRect) -> Bool {
        return position.y < frame.minY
    }
}
