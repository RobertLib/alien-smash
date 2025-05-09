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

    private var aliens: [[Alien?]]
    private var scene: SKScene
    private var spawnActionKey = "spawnAlienAction"
    private var attackActionKey = "launchAttackAction"
    private var lastUpdateTime: TimeInterval = 0

    private var formationCenter: CGPoint {
        return CGPoint(x: scene.frame.midX, y: scene.frame.maxY - formationHeight)
    }

    init(scene: SKScene) {
        self.scene = scene
        self.aliens = Array(
            repeating: Array(repeating: nil, count: formationColumns), count: formationRows)

        setupTimers()
    }

    func resetTimers() {
        scene.removeAction(forKey: spawnActionKey)
        scene.removeAction(forKey: attackActionKey)

        setupTimers()
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
        let startX = formationCenter.x - (CGFloat(formationColumns - 1) * horizontalSpacing / 2)
        let startY = formationCenter.y
        let formationPosition = CGPoint(
            x: startX + CGFloat(col) * horizontalSpacing,
            y: startY - CGFloat(row) * verticalSpacing
        )

        let alien = Alien(formationIndex: CGPoint(x: col, y: row))
        aliens[row][col] = alien

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

    private func launchAttack() {
        var formationAliens: [Alien] = []
        for row in 0..<formationRows {
            for col in 0..<formationColumns {
                if let alien = aliens[row][col], alien.state == .formation {
                    formationAliens.append(alien)
                }
            }
        }

        guard !formationAliens.isEmpty else { return }

        let randomIndex = Int.random(in: 0..<formationAliens.count)
        let attackingAlien = formationAliens[randomIndex]
        let targetY = scene.frame.minY + 100
        let targetX = CGFloat.random(in: scene.frame.minX + 50...scene.frame.maxX - 50)
        let targetPosition = CGPoint(x: targetX, y: targetY)

        attackingAlien.attack(targetPosition: targetPosition)
    }

    func update(currentTime: TimeInterval, playerPosition: CGPoint) -> [AlienBullet] {
        let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        lastUpdateTime = currentTime

        var newBullets: [AlienBullet] = []

        for row in 0..<formationRows {
            for col in 0..<formationColumns {
                if let alien = aliens[row][col] {
                    if let bullet = alien.update(deltaTime: deltaTime) {
                        newBullets.append(bullet)
                        scene.addChild(bullet)
                    }
                }
            }
        }

        return newBullets
    }

    func handleCollisionWithBall(alien: Alien) {
        for row in 0..<formationRows {
            for col in 0..<formationColumns {
                if aliens[row][col] === alien {
                    aliens[row][col] = nil
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
                    if alien.state == .attacking || alien.state == .returningToFormation {
                        return false
                    }
                }
            }
        }
        return true
    }
}
