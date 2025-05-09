//
//  LevelCompleted.swift
//  AlienSmash
//
//  Created by Robert Libšanský on 11.05.2025.
//

import SpriteKit

class LevelCompleted: SKNode {

    private var nextLevelButton: GameButton!
    private var titleLabel: GameTitle!
    private var nextLevelLabel: GameTitle?
    private var scoreInfoLabel: GameTitle?
    var onNextLevelPressed: (() -> Void)?

    override init() {
        super.init()
        self.zPosition = 1000
        setupLevelCompleted()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLevelCompleted() {
        titleLabel = GameTitle(text: "LEVEL COMPLETED!")
        titleLabel.position = CGPoint(x: 0, y: 160)
        addChild(titleLabel)

        nextLevelButton = GameButton(text: "NEXT LEVEL")
        nextLevelButton.position = CGPoint(x: 0, y: -100)
        nextLevelButton.onPressed = { [weak self] in
            self?.onNextLevelPressed?()
        }
        addChild(nextLevelButton)

        self.setScale(0.1)
        self.run(SKAction.scale(to: 1.0, duration: 0.5))

        titleLabel.alpha = 1.0
        nextLevelButton.alpha = 1.0
    }

    func handleTouch(_ location: CGPoint) -> Bool {
        return nextLevelButton.handleTouch(self.convert(location, to: nextLevelButton.parent!))
    }

    func setStats(_ level: Int, _ score: Int) {
        titleLabel.text = "LEVEL \(level) COMPLETED!"

        nextLevelLabel = GameTitle(text: "STARTING LEVEL \(level + 1)", fontSize: 32)
        nextLevelLabel?.position = CGPoint(x: 0, y: 80)
        addChild(nextLevelLabel!)
        nextLevelLabel?.fadeIn()

        scoreInfoLabel = GameTitle(text: "YOUR SCORE: \(score)", fontSize: 32)
        scoreInfoLabel?.position = CGPoint(x: 0, y: 0)
        addChild(scoreInfoLabel!)
        scoreInfoLabel?.fadeIn()
    }
}
