//
//  LevelCompleted.swift
//  AlienSmash
//
//  Created by Robert Libšanský on 11.05.2025.
//

import SpriteKit

class LevelCompleted: SKNode {

    private var gamePanel: GamePanel!
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
        gamePanel = GamePanel()
        addChild(gamePanel)

        gamePanel.setupContent(
            title: "LEVEL COMPLETED!",
            buttonText: "NEXT LEVEL",
            buttonAction: { [weak self] in
                self?.onNextLevelPressed?()
            }
        )

        gamePanel.show()
    }

    func handleTouch(_ location: CGPoint) -> Bool {
        return gamePanel.handleTouch(self.convert(location, to: gamePanel))
    }

    func setStats(_ level: Int, _ score: Int) {
        gamePanel.setupContent(
            title: "LEVEL \(level) COMPLETED!",
            subtitle: "STARTING LEVEL \(level + 1)",
            infoTexts: [
                "YOUR SCORE: \(score)"
            ],
            buttonText: "NEXT LEVEL",
            buttonAction: { [weak self] in
                self?.onNextLevelPressed?()
            }
        )
    }
}
