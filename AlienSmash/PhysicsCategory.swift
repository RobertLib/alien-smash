//
//  PhysicsCategory.swift
//  AlienSmash
//
//  Created by Robert Libšanský on 09.05.2025.
//

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let all: UInt32 = UInt32.max
    static let ball: UInt32 = 0x1 << 0
    static let paddle: UInt32 = 0x1 << 1
    static let alien: UInt32 = 0x1 << 2
    static let alienBullet: UInt32 = 0x1 << 3
}
