//
//  Alien.swift
//  AlienSmash
//
//  Created by Robert Libšanský on 09.05.2025.
//

import SpriteKit

enum AlienState {
    case flying
    case formation
    case attacking
    case returningToFormation
}

class Alien: SKSpriteNode {
    private let moveSpeed: CGFloat = 150.0
    private let averageShootsPerSecond: Double = 0.1

    let formationIndex: CGPoint
    var state: AlienState = .flying
    var formationPosition: CGPoint = .zero

    init(formationIndex: CGPoint, size: CGSize = CGSize(width: 30, height: 30)) {
        self.formationIndex = formationIndex
        super.init(texture: nil, color: .green, size: size)
        setupAlien()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupAlien() {
        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.isDynamic = true
        physicsBody?.categoryBitMask = PhysicsCategory.alien
        physicsBody?.contactTestBitMask = PhysicsCategory.ball
        physicsBody?.collisionBitMask = PhysicsCategory.none
        physicsBody?.usesPreciseCollisionDetection = true

        let shape = SKShapeNode(rectOf: size, cornerRadius: 5)
        shape.fillColor = .green
        shape.strokeColor = .white
        shape.lineWidth = 2
        addChild(shape)
    }

    func moveToFormation() {
        guard state == .flying else { return }

        let moveDuration = 1.5
        let moveAction = SKAction.move(to: formationPosition, duration: moveDuration)
        let completionAction = SKAction.run { [weak self] in
            self?.state = .formation
        }

        run(SKAction.sequence([moveAction, completionAction]))
    }

    func attack(targetPosition: CGPoint) {
        guard state == .formation else { return }

        state = .attacking

        let attackPath = UIBezierPath()
        attackPath.move(to: .zero)

        let controlPoint1 = CGPoint(
            x: CGFloat.random(in: -100...100),
            y: CGFloat.random(in: -100...0))
        let controlPoint2 = CGPoint(
            x: CGFloat.random(in: -100...100),
            y: CGFloat.random(in: -100...0))
        let endPoint = CGPoint(
            x: targetPosition.x - position.x,
            y: targetPosition.y - position.y)

        attackPath.addCurve(
            to: endPoint,
            controlPoint1: controlPoint1,
            controlPoint2: controlPoint2)

        let followPath = SKAction.follow(
            attackPath.cgPath,
            asOffset: true,
            orientToPath: true,
            duration: 2.0)

        let returnAction = SKAction.run { [weak self] in
            self?.returnToFormation()
        }

        run(SKAction.sequence([followPath, returnAction]))
    }

    func returnToFormation() {
        state = .returningToFormation

        let returnAction = SKAction.move(to: formationPosition, duration: 1.0)
        let resetRotationAction = SKAction.rotate(toAngle: 0, duration: 0.5)
        let groupAction = SKAction.group([returnAction, resetRotationAction])
        let completionAction = SKAction.run { [weak self] in
            self?.state = .formation
        }

        run(SKAction.sequence([groupAction, completionAction]))
    }

    func shoot() -> AlienBullet? {
        guard state != .flying else { return nil }

        let bullet = AlienBullet()
        bullet.position = CGPoint(x: position.x, y: position.y - size.height / 2)
        return bullet
    }

    func update(deltaTime: TimeInterval) -> AlienBullet? {
        guard state == .formation else { return nil }

        let shootProbability = averageShootsPerSecond * deltaTime

        if Double.random(in: 0...1) < shootProbability {
            return shoot()
        }

        return nil
    }
}
