//
//  CheatDevice.swift
//  Ignited
//
//  Created by Riley Testut on 1/30/23.
//  Copyright © 2023 Riley Testut. All rights reserved.
//

import Foundation

import DeltaCore

@objc
enum CheatDevice: Int16
{
    case gbGameGenie = 4
    
    case gbaActionReplayMax = 5
    case gbaCodeBreaker = 6
    case gbaGameShark = 7
    
    case gbcGameShark = 8
}

extension CheatDevice
{
    var cheatType: CheatType? {
        switch self
        {
        case .gbaActionReplayMax:
            return .actionReplay
            
        case .gbcGameShark, .gbaGameShark:
            return .gameShark
            
        case .gbGameGenie:
            return .gameGenie
            
        case .gbaCodeBreaker:
            return .codeBreaker
        }
    }
    
    var gameType: GameType? {
        switch self
        {
        case .gbGameGenie, .gbcGameShark: return .gbc
        case .gbaActionReplayMax, .gbaGameShark, .gbaCodeBreaker: return .gba
        }
    }
    
    var cheatFormat: CheatFormat? {
        guard
            let cheatType = self.cheatType,
            let gameType = self.gameType,
            let deltaCore = Delta.core(for: gameType)
        else { return nil }
        
        let cheatFormat = deltaCore.supportedCheatFormats.first { $0.type == cheatType }
        return cheatFormat
    }
}
