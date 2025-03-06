//
//  GBACoreFeatures.swift
//  Ignited
//
//  Created by Chris Rittenhouse on 3/17/24.
//  Copyright © 2024 LitRitt. All rights reserved.
//

import SwiftUI

import mGBADeltaCore

import Features

struct GBACoreOptions
{
    @Option(name: "Core Info",
            description: "Information about the current core",
            detailView: { _ in
        ForEach(Settings.preferredCore(for: .gba)?.metadata?.sortedKeys ?? []) { key in
            if let item = Settings.preferredCore(for: .gba)?.metadata?[key]
            {
                VStack {
                    if let url = item.url
                    {
                        Link(destination: url) {
                            HStack {
                                Text(key.rawValue)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(item.value)
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.forward")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    else
                    {
                        HStack {
                            Text(key.rawValue)
                            Spacer()
                            Text(item.value)
                        }
                    }
                    
                    if let lastKey = Settings.preferredCore(for: .gba)?.metadata?.sortedKeys?.last,
                       key != lastKey
                    {
                        Divider()
                    }
                }
            }
        }
        .displayInline()
    })
    var coreInfo: String = ""
    
//    @Option(name: "Change Core",
//            description: "Choose the core to use for GBA games.",
//            detailView: { value in
//        HStack {
//            Spacer()
//            Button("Choose Core") {
//                GBACoreOptions.changeCore()
//            }
//            .foregroundColor(.red)
//            Spacer()
//        }
//        .displayInline()
//    })
//    var coreName: String = Settings.preferredCore(for: .gba)?.metadata?.name.value ?? mGBA.core.name
}

//extension GBACoreOptions
//{
//    static func changeCore()
//    {
//        guard let topViewController = UIApplication.shared.topViewController() else { return }
//        
//        let alertController = UIAlertController(title: NSLocalizedString("Change Emulator Core", comment: ""), message: NSLocalizedString("Save states are not compatible between different emulator cores. Make sure to use in-game saves in order to keep using your save data.\n\nYour existing save states will not be deleted and will be available whenever you switch cores again.", comment: ""), preferredStyle: .actionSheet)
//        alertController.preparePopoverPresentationController(topViewController.view)
//        
//        var vbamActionTitle = GBA.core.metadata?.name.value ?? GBA.core.name
//        var mgbaActionTitle = mGBA.core.metadata?.name.value ?? mGBA.core.name
//        
//        if Settings.preferredCore(for: .gba) == GBA.core
//        {
//            vbamActionTitle += " ✓"
//        }
//        else
//        {
//            mgbaActionTitle += " ✓"
//        }
//        
//        alertController.addAction(UIAlertAction(title: vbamActionTitle, style: .default, handler: { (action) in
//            Settings.setPreferredCore(GBA.core, for: .gba)
//            Settings.gbaFeatures.core.coreName = GBA.core.metadata?.name.value ?? GBA.core.name
//        }))
//        
//        alertController.addAction(UIAlertAction(title: mgbaActionTitle, style: .default, handler: { (action) in
//            Settings.setPreferredCore(mGBA.core, for: .gba)
//            Settings.gbaFeatures.core.coreName = mGBA.core.metadata?.name.value ?? mGBA.core.name
//        }))
//        alertController.addAction(.cancel)
//        topViewController.present(alertController, animated: true, completion: nil)
//    }
//}
