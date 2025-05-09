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
    case kamikaze
}

class Alien: SKSpriteNode {
    private let moveSpeed: CGFloat = 150.0
    private let averageShootsPerSecond: Double = 0.1
    private var attackCount: Int = 0
    private let maxAttacksBeforeKamikaze: Int = 3

    let formationIndex: CGPoint
    var state: AlienState = .flying
    var formationPosition: CGPoint = .zero
    var isBottomInColumn: Bool = false

    var onBulletCreated: ((AlienBullet) -> Void)?

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
        physicsBody?.contactTestBitMask = PhysicsCategory.ball | PhysicsCategory.paddle
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

        attackCount += 1

        if attackCount > maxAttacksBeforeKamikaze {
            performKamikazeAttack()
            return
        }

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

        let fireAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.shoot()

            let wait = SKAction.wait(forDuration: 0.3)
            self.run(wait)
        }

        let returnAction = SKAction.run { [weak self] in
            self?.returnToFormation()
        }

        run(SKAction.sequence([followPath, fireAction, returnAction]))
    }

    private func performKamikazeAttack() {
        guard let scene = self.scene else { return }

        state = .kamikaze

        let targetY = -100
        let targetPosition = CGPoint(x: position.x, y: CGFloat(targetY))
        let rotateAction = SKAction.rotate(toAngle: CGFloat.pi, duration: 0.5)
        let moveAction = SKAction.move(to: targetPosition, duration: 2.0)
        let speedUp = SKAction.speed(by: 1.5, duration: 0)
        let moveWithSpeed = SKAction.sequence([speedUp, moveAction])

        let fireSequence = SKAction.sequence([
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.shoot()
            },
            SKAction.wait(forDuration: 0.3),
        ])

        let repeatedFire = SKAction.repeat(fireSequence, count: 3)
        let groupAction = SKAction.group([moveWithSpeed, repeatedFire])

        let notifyAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            NotificationCenter.default.post(
                name: Notification.Name("AlienKamikazeComplete"),
                object: self
            )
        }

        run(SKAction.sequence([rotateAction, groupAction, notifyAction]))
    }

    func returnToFormation() {
        state = .returningToFormation

        let currentRotation = self.zRotation
        let degrees = currentRotation * 180 / .pi
        let nearestRightAngle = round(degrees / 90) * 90
        let targetRotation = nearestRightAngle * .pi / 180
        let returnAction = SKAction.move(to: formationPosition, duration: 1.0)
        let resetRotationAction = SKAction.rotate(toAngle: targetRotation, duration: 1.0)
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

        onBulletCreated?(bullet)

        return bullet
    }

    func update(deltaTime: TimeInterval) -> AlienBullet? {
        guard state == .formation, isBottomInColumn else { return nil }

        let shootProbability = averageShootsPerSecond * deltaTime

        if Double.random(in: 0...1) < shootProbability {
            return shoot()
        }

        return nil
    }

    func updatePositionOnly(deltaTime: TimeInterval) {}

    func isInKamikazeState() -> Bool {
        return state == .kamikaze
    }
}
