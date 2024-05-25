// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Game.swift instead.

import Foundation
import CoreData

import DeltaCore

public class _Game: NSManagedObject 
{   
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Game> {
        return NSFetchRequest<Game>(entityName: "Game")
    }
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        setPrimitiveValue(false, forKey: #keyPath(Game.isFavorite))
        
        setPrimitiveValue(0, forKey: #keyPath(Game.overscanTop))
        setPrimitiveValue(0, forKey: #keyPath(Game.overscanBottom))
        setPrimitiveValue(0, forKey: #keyPath(Game.overscanLeft))
        setPrimitiveValue(0, forKey: #keyPath(Game.overscanRight))
        
        setPrimitiveValue(0, forKey: #keyPath(Game.playTime))
    }

    // MARK: - Properties

    @NSManaged public var artworkURL: URL?

    @NSManaged public var filename: String

    @NSManaged public var identifier: String

    @NSManaged public var name: String

    @NSManaged public var playedDate: Date?

    @NSManaged public var type: GameType
    
    @NSManaged public var isFavorite: Bool
    
    @NSManaged public var overscanTop: UInt16
    
    @NSManaged public var overscanBottom: UInt16
    
    @NSManaged public var overscanLeft: UInt16
    
    @NSManaged public var overscanRight: UInt16
    
    @NSManaged public var playTime: UInt32

    // MARK: - Relationships

    @NSManaged public var cheats: Set<Cheat>

    @NSManaged public var gameCollection: GameCollection?

    @NSManaged public var gameSave: GameSave?

    @NSManaged public var preferredLandscapeSkin: ControllerSkin?

    @NSManaged public var preferredPortraitSkin: ControllerSkin?

    @NSManaged public var previewSaveState: SaveState?

    @NSManaged public var saveStates: Set<SaveState>

}

