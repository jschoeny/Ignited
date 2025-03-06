//
//  System.swift
//  Ignited
//
//  Created by Riley Testut on 4/30/17.
//  Copyright © 2017 Riley Testut. All rights reserved.
//

import DeltaCore

import Systems

enum System: CaseIterable
{
    case gbc
    case gba
    
    static var registeredSystems: [System] {
        let systems = System.allCases.filter { Delta.registeredCores.keys.contains($0.gameType) }
        return systems
    }
    
    static var allCores: [DeltaCoreProtocol] {
        return [mGBA.core, mGBC.core]
    }
}

extension System
{
    var localizedName: String {
        switch self
        {
        case .gbc: return NSLocalizedString("Game Boy Color", comment: "")
        case .gba: return NSLocalizedString("Game Boy Advance", comment: "")
        }
    }
    
    var localizedShortName: String {
        switch self
        {
        case .gbc: return NSLocalizedString("GBC", comment: "")
        case .gba: return NSLocalizedString("GBA", comment: "")
        }
    }
    
    var year: Int {
        switch self
        {
        case .gbc: return 1998
        case .gba: return 2001
        }
    }
}

extension System
{
    var deltaCore: DeltaCoreProtocol {
        switch self
        {
        case .gbc: return mGBC.core
        case .gba: return mGBA.core
        }
    }
    
    var gameType: DeltaCore.GameType {
        switch self
        {
        case .gbc: return .gbc
        case .gba: return .gba
        }
    }
    
    init?(gameType: DeltaCore.GameType)
    {
        switch gameType
        {
        case GameType.gbc: self = .gbc
        case GameType.gba: self = .gba
        default: return nil
        }
    }
}

extension DeltaCore.GameType
{
    init?(fileExtension: String)
    {
        switch fileExtension.lowercased()
        {
        case "gbc", "gb": self = .gbc
        case "gba": self = .gba
        default: return nil
        }
    }
}
