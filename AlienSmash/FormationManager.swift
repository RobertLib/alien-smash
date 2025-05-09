//
//  FormationManager.swift
//  AlienSmash
//
//  Created by Robert Libšanský on 09.05.2025.
//

import SpriteKit

class FormationManager {
    private let formationRows = 4
    private let formationColumns = 6
    private let horizontalSpacing: CGFloat = 50
    private let verticalSpacing: CGFloat = 40
    private let formationHeight: CGFloat = 200

    private let pulseAmplitude: CGFloat = 5.0
    private let pulseCycleDuration: TimeInterval = 4.0
    private var pulseTimer: TimeInterval = 0.0
    private var pulseFactor: CGFloat = 0.0

    private var aliens: [[Alien?]]
    private var scene: SKScene
    private var spawnActionKey = "spawnAlienAction"
    private var attackActionKey = "launchAttackAction"
    private var lastUpdateTime: TimeInterval = 0

    private let maxAliens: Int
    private var aliensRemaining: Int
    private var activeAlienCount: Int = 0

    private var formationCenter: CGPoint {
        return CGPoint(x: scene.frame.midX, y: scene.frame.maxY - formationHeight)
    }

    var onLevelCompleted: (() -> Void)?

    init(scene: SKScene) {
        self.scene = scene
        self.aliens = Array(
            repeating: Array(repeating: nil, count: formationColumns), count: formationRows)

        self.maxAliens = formationRows * formationColumns * 2
        self.aliensRemaining = self.maxAliens

        setupTimers()
        setupNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKamikazeComplete(_:)),
            name: Notification.Name("AlienKamikazeComplete"),
            object: nil
        )
    }

    @objc private func handleKamikazeComplete(_ notification: Notification) {
        guard let kamikazeAlien = notification.object as? Alien else { return }

        for row in 0..<formationRows {
            for col in 0..<formationColumns {
                if aliens[row][col] === kamikazeAlien {
                    aliens[row][col] = nil
                    activeAlienCount -= 1
                    kamikazeAlien.removeFromParent()
                    break
                }
            }
        }
    }

    func resetTimers() {
        scene.removeAction(forKey: spawnActionKey)
        scene.removeAction(forKey: attackActionKey)

        lastUpdateTime = 0

        setupTimers()
    }

    func resetLevel() {
        for row in 0..<formationRows {
            for col in 0..<formationColumns {
                if let alien = aliens[row][col] {
                    alien.removeFromParent()
                    aliens[row][col] = nil
                }
            }
        }

        aliensRemaining = maxAliens
        activeAlienCount = 0

        resetTimers()
    }

    private func setupTimers() {
        let spawnAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.wait(forDuration: 1.0),
                SKAction.run { [weak self] in
                    self?.spawnAlien()
                },
            ]))

        let attackAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.wait(forDuration: 2.0),
                SKAction.run { [weak self] in
                    self?.launchAttack()
                },
            ]))

        scene.run(spawnAction, withKey: spawnActionKey)
        scene.run(attackAction, withKey: attackActionKey)
    }

    private func spawnAlien() {
        guard aliensRemaining > 0 else { return }

        var availablePositions: [(row: Int, col: Int)] = []
        for row in 0..<formationRows {
            for col in 0..<formationColumns {
                if aliens[row][col] == nil {
                    availablePositions.append((row: row, col: col))
                }
            }
        }

        guard !availablePositions.isEmpty else { return }

        let randomIndex = Int.random(in: 0..<availablePositions.count)
        let selectedPosition = availablePositions[randomIndex]
        let row = selectedPosition.row
        let col = selectedPosition.col

        let formationPosition = calculateFormationPosition(row: row, col: col, pulseFactor: 0)

        let alien = Alien(formationIndex: CGPoint(x: col, y: row))

        if let gameScene = scene as? GameScene {
            alien.onBulletCreated = { [weak gameScene] bullet in
                gameScene?.addAlienBullet(bullet)
            }
        }

        aliens[row][col] = alien
        aliensRemaining -= 1
        activeAlienCount += 1

        let sideMargin: CGFloat = 50
        let randomSide = Bool.random()
        let startPosition: CGPoint

        if randomSide {
            startPosition = CGPoint(
                x: scene.frame.minX - sideMargin,
                y: CGFloat.random(in: scene.frame.midY...(scene.frame.maxY - 100)))
        } else {
            startPosition = CGPoint(
                x: scene.frame.maxX + sideMargin,
                y: CGFloat.random(in: scene.frame.midY...(scene.frame.maxY - 100)))
        }

        alien.position = startPosition
        alien.formationPosition = formationPosition
        alien.state = .flying

        scene.addChild(alien)
        alien.moveToFormation()
    }

    private func calculateFormationPosition(row: Int, col: Int, pulseFactor: CGFloat) -> CGPoint {
        let baseHorizontalSpacing = horizontalSpacing
        let baseVerticalSpacing = verticalSpacing

        let scaleFactor = 1.0 + (pulseFactor / 100.0)

        let currentHorizontalSpacing = baseHorizontalSpacing * scaleFactor
        let currentVerticalSpacing = baseVerticalSpacing * scaleFactor

        let startX =
            formationCenter.x - ((CGFloat(formationColumns - 1) * currentHorizontalSpacing) / 2)
        let startY = formationCenter.y

        let x = startX + CGFloat(col) * currentHorizontalSpacing
        let y = startY - CGFloat(row) * currentVerticalSpacing

        return CGPoint(x: x, y: y)
    }

    private func launchAttack() {
        var bottomAliens: [Alien] = []

        for col in 0..<formationColumns {
            var bottomAlienInColumn: Alien? = nil

            for row in (0..<formationRows).reversed() {
                if let alien = aliens[row][col], alien.state == .formation {
                    bottomAlienInColumn = alien
                    break
                }
            }

            if let alien = bottomAlienInColumn {
                bottomAliens.append(alien)
            }
        }

        guard !bottomAliens.isEmpty else { return }

        let randomIndex = Int.random(in: 0..<bottomAliens.count)
        let attackingAlien = bottomAliens[randomIndex]
        let targetY = scene.frame.minY + 400
        let targetX = CGFloat.random(in: scene.frame.minX + 50...scene.frame.maxX - 50)
        let targetPosition = CGPoint(x: targetX, y: targetY)

        attackingAlien.attack(targetPosition: targetPosition)
    }

    private func updateBottomAliens() {
        for row in 0..<formationRows {
            for col in 0..<formationColumns {
                if let alien = aliens[row][col] {
                    alien.isBottomInColumn = false
                }
            }
        }

        for col in 0..<formationColumns {
            for row in (0..<formationRows).reversed() {
                if let alien = aliens[row][col], alien.state == .formation {
                    alien.isBottomInColumn = true
                    break
                }
            }
        }
    }

    private func updateFormationPulse(deltaTime: TimeInterval) {
        pulseTimer += deltaTime
        if pulseTimer > pulseCycleDuration {
            pulseTimer -= pulseCycleDuration
        }

        pulseFactor = pulseAmplitude * sin(2 * .pi * pulseTimer / pulseCycleDuration)

        for row in 0..<formationRows {
            for col in 0..<formationColumns {
                if let alien = aliens[row][col], alien.state == .formation {
                    let newPosition = calculateFormationPosition(
                        row: row, col: col, pulseFactor: pulseFactor)
                    alien.position = newPosition
                    alien.formationPosition = newPosition
                }
            }
        }

        if activeAlienCount == 0 && aliensRemaining == 0 {
            onLevelCompleted?()
        }
    }

    func update(currentTime: TimeInterval, allowShooting: Bool = true) {
        let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        let cappedDeltaTime = min(deltaTime, 0.1)
        lastUpdateTime = currentTime

        updateBottomAliens()
        updateFormationPulse(deltaTime: cappedDeltaTime)

        for row in 0..<formationRows {
            for col in 0..<formationColumns {
                if let alien = aliens[row][col] {
                    if allowShooting {
                        alien.update(deltaTime: cappedDeltaTime)
                    } else {
                        alien.updatePositionOnly(deltaTime: cappedDeltaTime)
                    }
                }
            }
        }
    }

    func handleCollisionWithBall(alien: Alien) {
        for row in 0..<formationRows {
            for col in 0..<formationColumns {
                if aliens[row][col] === alien {
                    aliens[row][col] = nil
                    activeAlienCount -= 1
                    break
                }
            }
        }

        alien.removeFromParent()
    }

    func stopAllActions() {
        scene.removeAction(forKey: spawnActionKey)
        scene.removeAction(forKey: attackActionKey)

        for row in 0..<formationRows {
            for col in 0..<formationColumns {
                if let alien = aliens[row][col] {
                    if alien.state == .attacking {
                        alien.returnToFormation()
                    }
                }
            }
        }
    }

    func areAllAliensInFormation() -> Bool {
        for row in 0..<formationRows {
            for col in 0..<formationColumns {
                if let alien = aliens[row][col] {
                    if alien.state == .attacking || alien.state == .returningToFormation
                        || alien.state == .kamikaze
                    {
                        return false
                    }
                }
            }
        }
        return true
    }
}
