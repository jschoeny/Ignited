//
//  StandardControllerSkin.swift
//  Ignited
//
//  Created by Chris Rittenhouse on 2/16/24.
//  Copyright © 2024 LitRitt. All rights reserved.
//

import UIKit
import CoreGraphics
import AVFoundation

import DeltaCore

public struct StandardControllerSkin
{
    public typealias Skin = DeltaCore.ControllerSkin
    
    public var name: String { "StandardControllerSkin" }
    public var identifier: String
    public var gameType: GameType
    
    public var inputMappingMode: Bool
    public var isDebugModeEnabled: Bool { false }
    public var hasAltRepresentations: Bool { false }
    
    public init?(for gameType: GameType, inputMappingMode: Bool = false)
    {
        self.identifier = "com.ignited.StandardControllerSkin." + gameType.description
        self.gameType = gameType
        
        self.inputMappingMode = inputMappingMode
    }
    
    static public var extendedEdges: [String: CGFloat]
    {[
        "top": Settings.standardSkinFeatures.inputsAndLayout.extendedEdges,
        "bottom": Settings.standardSkinFeatures.inputsAndLayout.extendedEdges,
        "left": Settings.standardSkinFeatures.inputsAndLayout.extendedEdges,
        "right": Settings.standardSkinFeatures.inputsAndLayout.extendedEdges
    ]}
}

extension StandardControllerSkin: ControllerSkinProtocol
{
    public func items(for traits: Skin.Traits, alt: Bool) -> [Skin.Item]?
    {
        let mappingSize = self.aspectRatio(for: traits, alt: alt) ?? .zero
        let buttonAreas = self.buttonAreas(for: traits)
        let isSplitView = traits.displayType == .splitView
        
        var items = [Skin.Item]()
        
        for input in self.softwareInputs(for: traits) {
            switch input.kind
            {
            case .touchScreen:
                if let screens = self.screens(for: traits, alt: alt),
                   let screen = screens.last,
                   let screenFrame = screen.outputFrame
                {
                    items.append(Skin.Item(id: input.description(self.gameType, isSplitView: isSplitView),
                                           kind: input.kind,
                                           inputs: input.inputs(self.gameType, isSplitView: isSplitView),
                                           frame: screenFrame.getAbsolute(for: traits, inputMappingMode: self.inputMappingMode),
                                           edges: input.edges,
                                           mappingSize: mappingSize))
                }
                
            default:
                var kind = input.kind
                
                if kind == .dPad
                {
                    switch Settings.standardSkinFeatures.inputsAndLayout.directionalInputType
                    {
                    case .dPad: kind = .dPad
                    case .thumbstick: kind = .thumbstick
                    }
                }
                
                let frame = input.frame(leftButtonArea: buttonAreas.left.getAbsolute(for: traits, inputMappingMode: self.inputMappingMode),
                                        rightButtonArea: buttonAreas.right.getAbsolute(for: traits, inputMappingMode: self.inputMappingMode),
                                        gameType: self.gameType,
                                        traits: traits)
                
                if kind == .thumbstick
                {
                    let thumbstickSize = CGSize(width: (frame.width / 2) + 24, height: (frame.height / 2) + 24)
                    
                    items.append(Skin.Item(id: input.description(self.gameType, isSplitView: isSplitView),
                                           kind: kind,
                                           inputs: input.inputs(self.gameType, isSplitView: isSplitView),
                                           frame: frame,
                                           edges: input.edges,
                                           mappingSize: mappingSize,
                                           thumbstickSize: thumbstickSize))
                }
                else
                {
                    items.append(Skin.Item(id: input.description(self.gameType, isSplitView: isSplitView),
                                           kind: kind,
                                           inputs: input.inputs(self.gameType, isSplitView: isSplitView),
                                           frame: frame,
                                           edges: input.edges,
                                           mappingSize: mappingSize))
                }
            }
        }
        
        return items
    }
    
    public func screens(for traits: Skin.Traits, alt: Bool) -> [Skin.Screen]?
    {
        guard !self.inputMappingMode else {
            let screenFrame = CGRect(x: 0, y: 0.07, width: 1, height: 0.2)
            
            return [Skin.Screen(id: "standardControllerSkin.screen", outputFrame: screenFrame, style: self.screenStyle().style)]
        }
        
        let buttonAreas = self.buttonAreas(for: traits)
        
        var leftButtonArea = buttonAreas.left.getAbsolute(for: traits, inputMappingMode: self.inputMappingMode)
        var rightButtonArea = buttonAreas.right.getAbsolute(for: traits, inputMappingMode: self.inputMappingMode)
        
        switch self.gameType
        {
        case .gbc:
            if !self.customButtonsEnabled()
            {
                leftButtonArea = leftButtonArea.getSubRect(sections: 4, index: 2, size: 3)
                rightButtonArea = rightButtonArea.getSubRect(sections: 4, index: 2, size: 3)
            }
            
        default: break
        }
        
        let mappingSize = self.aspectRatio(for: traits, alt: alt) ?? .zero
        let safeArea = self.unsafeArea(for: traits, alt: alt) ?? 0
        
        var screenArea: CGRect
        
        switch (traits.displayType, traits.orientation)
        {
        case (.splitView, _):
            let screenAreaWidth = rightButtonArea.minX - leftButtonArea.maxX
            
            screenArea = CGRect(x: leftButtonArea.maxX, y: 0, width: screenAreaWidth, height: mappingSize.height)
            
        case (_, .portrait):
            var screenAreaHeight = min(leftButtonArea.minY, rightButtonArea.minY)
            var screenAreaY = 0.0
            
            if traits.device == .iphone,
               traits.displayType == .edgeToEdge
            {
                screenAreaHeight -= safeArea
                screenAreaY = safeArea
            }
            
            screenArea = CGRect(x: 0, y: screenAreaY, width: mappingSize.width, height: screenAreaHeight)
            
        case (_, .landscape):
            let screenAreaWidth = rightButtonArea.minX - leftButtonArea.maxX
            
            switch Settings.standardSkinFeatures.gameScreen.landscapeSize
            {
            case .fitDevice, .fillDevice: screenArea = CGRect(origin: .zero, size: mappingSize)
            case .fitInputs: screenArea = CGRect(x: leftButtonArea.maxX, y: 0, width: screenAreaWidth, height: mappingSize.height)
            }
        }
        
        if self.screenStyle().isFloating
        {
            screenArea = screenArea.insetBy(dx: 10, dy: 10)
        }
        
        var screenFrame: CGRect
        
        if Settings.standardSkinFeatures.gameScreen.landscapeSize == .fillDevice,
           traits.orientation == .landscape
        {
            let unsafeArea = self.unsafeArea(for: traits, alt: alt) ?? 0
            
            screenFrame = CGRect(x: screenArea.minX + unsafeArea, y: screenArea.minY,
                                 width: screenArea.width - (unsafeArea * 2), height: screenArea.height)
        }
        else
        {
            screenFrame = AVMakeRect(aspectRatio: self.screenSize(), insideRect: screenArea)
        }
        
        screenFrame = screenFrame.getRelative(for: traits, inputMappingMode: self.inputMappingMode)
        
        switch (traits.device, traits.displayType)
        {
        case (_, .splitView):
            return [Skin.Screen(id: "standardControllerSkin.screen", placement: .app, style: self.screenStyle().style)]
            
        case (.tv, _):
            return nil
            
        default:
            return [Skin.Screen(id: "standardControllerSkin.screen", outputFrame: screenFrame, style: self.screenStyle().style)]
        }
    }
    
    public func dsButtonlessScreens(for traits: Skin.Traits, alt: Bool) -> [Skin.Screen]?
    {
        let buttonAreas = self.buttonAreas(for: traits)
        
        var leftButtonArea = buttonAreas.left.getAbsolute(for: traits, inputMappingMode: self.inputMappingMode)
        var rightButtonArea = buttonAreas.right.getAbsolute(for: traits, inputMappingMode: self.inputMappingMode)
        
        let mappingSize = self.aspectRatio(for: traits, alt: alt) ?? .zero
        let safeArea = self.unsafeArea(for: traits, alt: alt) ?? 0
        
        var topScreenArea: CGRect = .zero
        var bottomScreenArea: CGRect = .zero
        
        switch traits.orientation
        {
        case .portrait:
            topScreenArea = CGRect(x: 0, y: safeArea, width: mappingSize.width, height: leftButtonArea.minY - safeArea)
            bottomScreenArea = CGRect(x: 0, y: leftButtonArea.maxY, width: mappingSize.width, height: mappingSize.height - (leftButtonArea.maxY + safeArea))
            
        case .landscape:
            topScreenArea = CGRect(x: safeArea, y: 0, width: leftButtonArea.minX - safeArea, height: mappingSize.height)
            bottomScreenArea = CGRect(x: leftButtonArea.maxX, y: 0, width: mappingSize.width - (leftButtonArea.maxX + safeArea), height: mappingSize.height)
        }
        
        if self.screenStyle().isFloating
        {
            topScreenArea = topScreenArea.insetBy(dx: 10, dy: 10)
            bottomScreenArea = bottomScreenArea.insetBy(dx: 10, dy: 10)
        }
        
        let aspectRatio = CGSize(width: self.screenSize().width, height: self.screenSize().height / 2)
        let topScreenInputFrame = CGRect(origin: .zero, size: aspectRatio)
        let bottomScreenInputFrame = CGRect(origin: CGPoint(x: 0, y: aspectRatio.height), size: aspectRatio)
        
        let topScreenFrame = AVMakeRect(aspectRatio: aspectRatio, insideRect: topScreenArea).getRelative(for: traits, inputMappingMode: self.inputMappingMode)
        let bottomScreenFrame = AVMakeRect(aspectRatio: aspectRatio, insideRect: bottomScreenArea).getRelative(for: traits, inputMappingMode: self.inputMappingMode)
        
        switch alt
        {
        case false:
            return [
                Skin.Screen(id: "standardControllerSkin.topScreen", inputFrame: topScreenInputFrame, outputFrame: topScreenFrame, style: self.screenStyle().style),
                Skin.Screen(id: "standardControllerSkin.bottomScreen", inputFrame: bottomScreenInputFrame, outputFrame: bottomScreenFrame, isTouchScreen: true, style: self.screenStyle().style)
            ]
            
        case true:
            return [
                Skin.Screen(id: "standardControllerSkin.topScreen", inputFrame: topScreenInputFrame, outputFrame: bottomScreenFrame, style: self.screenStyle().style),
                Skin.Screen(id: "standardControllerSkin.bottomScreen", inputFrame: bottomScreenInputFrame, outputFrame: topScreenFrame, isTouchScreen: true, style: self.screenStyle().style)
            ]
            
        }
    }
    
    public func image(for traits: Skin.Traits, preferredSize: Skin.Size, alt: Bool) -> UIImage?
    {
        let mappingSize = self.aspectRatio(for: traits, alt: alt) ?? .zero
        let buttonAreas = self.buttonAreas(for: traits)
        let isSplitView = traits.displayType == .splitView
        
        let leftButtonArea = buttonAreas.left.getAbsolute(for: traits, inputMappingMode: self.inputMappingMode)
        let rightButtonArea = buttonAreas.right.getAbsolute(for: traits, inputMappingMode: self.inputMappingMode)
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: mappingSize, format: format)
        
        return renderer.image { (context) in
            let ctx = context.cgContext
            
            if Settings.advancedFeatures.skinDebug.inputBoxes
            {
                ctx.saveGState()
                
                let opacity = Settings.standardSkinFeatures.styleAndColor.shadowOpacity
                ctx.setShadow(offset: CGSize(width: 0, height: 3), blur: 9, color: UIColor.black.withAlphaComponent(opacity).cgColor)
                
                ctx.setFillColor(gray: 0.5, alpha: 0.5)
                
                ctx.addPath(CGPath(roundedRect: leftButtonArea, cornerWidth: 15, cornerHeight: 15, transform: nil).union(CGPath(roundedRect: rightButtonArea, cornerWidth: 15, cornerHeight: 15, transform: nil)))
                ctx.fillPath()
                
                ctx.restoreGState()
            }
            
            for input in self.softwareInputs(for: traits)
            {
                var assetName = input.assetName(self.gameType, isSplitView: isSplitView)
                var kind = input.kind
                
                var color = Settings.standardSkinFeatures.styleAndColor.color.uiColor
                var colorSecondary = Settings.standardSkinFeatures.styleAndColor.color.uiColorSecondary
                
                if input.kind == .dPad,
                   Settings.standardSkinFeatures.inputsAndLayout.directionalInputType == .thumbstick
                {
                    assetName = SoftwareInput.thumbstick.assetName(self.gameType)
                    kind = SoftwareInput.thumbstick.kind
                }
                
                if kind == .thumbstick
                {
                    color = color.withAlphaComponent(0.5)
                }
                
                ctx.saveGState()
                
                if Settings.standardSkinFeatures.styleAndColor.shadows,
                   kind != .thumbstick
                {
                    let opacity = Settings.standardSkinFeatures.styleAndColor.shadowOpacity
                    ctx.setShadow(offset: CGSize(width: 0, height: 3), blur: 9, color: UIColor.black.withAlphaComponent(opacity).cgColor)
                }
                
                switch Settings.standardSkinFeatures.styleAndColor.style
                {
                case .outline:
                    let image = UIImage.symbolWithTemplate(name: assetName, pointSize: 150, accentColor: color)
                    image.draw(in: input.frame(leftButtonArea: leftButtonArea,
                                               rightButtonArea: rightButtonArea,
                                               gameType: self.gameType,
                                               traits: traits))
                    ctx.restoreGState()
                    
                case .filled:
                    let image = UIImage.symbolWithTemplate(name: assetName + ".fill", pointSize: 150, accentColor: color)
                    image.draw(in: input.frame(leftButtonArea: leftButtonArea,
                                               rightButtonArea: rightButtonArea,
                                               gameType: self.gameType,
                                               traits: traits))
                    ctx.restoreGState()
                    
                case .both:
                    let filledImage = UIImage.symbolWithTemplate(name: assetName + ".fill", pointSize: 150, accentColor: color)
                    let outlineImage = UIImage.symbolWithTemplate(name: assetName, pointSize: 150, accentColor: colorSecondary)
                    let frame = input.frame(leftButtonArea: leftButtonArea,
                                            rightButtonArea: rightButtonArea,
                                            gameType: self.gameType,
                                            traits: traits)
                    
                    filledImage.draw(in: frame)
                    ctx.restoreGState()
                    outlineImage.draw(in: frame)
                }
            }
        }
    }
    
    public func thumbstick(for item: Skin.Item, traits: Skin.Traits, preferredSize: Skin.Size, alt: Bool) -> (UIImage, CGSize)?
    {
        let frame = item.frame.getAbsolute(for: traits, inputMappingMode: self.inputMappingMode)
        let thumbstickSize = CGSize(width: frame.width / 2, height: frame.height / 2)
        let thumbstickFrame = CGRect(origin: CGPoint(x: 12, y: 12), size: thumbstickSize)
        let renderSize = CGSize(width: thumbstickSize.width + 24, height: thumbstickSize.height + 24)
        let size = renderSize.getRelative(for: traits, inputMappingMode: self.inputMappingMode)
        
        let assetName = "circle.circle"
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: renderSize, format: format)
        
        let image = renderer.image { (context) in
            let ctx = context.cgContext
            
            ctx.saveGState()
                
            if Settings.standardSkinFeatures.styleAndColor.shadows
            {
                let opacity = Settings.standardSkinFeatures.styleAndColor.shadowOpacity
                ctx.setShadow(offset: CGSize(width: 0, height: 3), blur: 9, color: UIColor.black.withAlphaComponent(opacity).cgColor)
            }
            
            let color = Settings.standardSkinFeatures.styleAndColor.color.uiColor
            let colorSecondary = Settings.standardSkinFeatures.styleAndColor.color.uiColorSecondary
            
            switch Settings.standardSkinFeatures.styleAndColor.style
            {
            case .outline:
                let image = UIImage.symbolWithTemplate(name: assetName, pointSize: 150, accentColor: color)
                image.draw(in: thumbstickFrame)
                ctx.restoreGState()
                
            case .filled:
                let image = UIImage.symbolWithTemplate(name: assetName + ".fill", pointSize: 150, accentColor: color)
                image.draw(in: thumbstickFrame)
                ctx.restoreGState()
                
            case .both:
                let filledImage = UIImage.symbolWithTemplate(name: assetName + ".fill", pointSize: 150, accentColor: color)
                let outlineImage = UIImage.symbolWithTemplate(name: assetName, pointSize: 150, accentColor: colorSecondary)
                
                filledImage.draw(in: thumbstickFrame)
                ctx.restoreGState()
                outlineImage.draw(in: thumbstickFrame)
            }
        }
        
        return (image, size)
    }
    
    public func aspectRatio(for traits: Skin.Traits, alt: Bool) -> CGSize?
    {
        guard !self.inputMappingMode else {
            return CGSize(width: 414, height: 736)
        }
        
        switch (traits.displayType, traits.orientation)
        {
        case (.splitView, .portrait): return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * Settings.standardSkinFeatures.inputsAndLayout.splitViewPortraitSize)
        case (.splitView, .landscape): return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * Settings.standardSkinFeatures.inputsAndLayout.splitViewLandscapeSize)
        default: return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        }
    }
    
    public func supports(_ traits: Skin.Traits, alt: Bool) -> Bool
    {
        return true
    }
    
    public func isTranslucent(for traits: Skin.Traits, alt: Bool) -> Bool?
    {
        return Settings.standardSkinFeatures.styleAndColor.translucentInputs
    }
    
    public func anyImage(for traits: Skin.Traits, preferredSize: Skin.Size, alt: Bool) -> UIImage?
    {
        return self.image(for: traits, preferredSize: preferredSize, alt: alt)
    }
    
    public func contentSize(for traits: Skin.Traits, alt: Bool) -> CGSize?
    {
        return nil
    }
    
    public func previewSize(for traits: Skin.Traits, alt: Bool) -> CGSize?
    {
        return CGSize(width: 400, height: 200)
    }
    
    public func anyPreviewSize(for traits: Skin.Traits, alt: Bool) -> CGSize?
    {
        return self.previewSize(for: traits, alt: alt)
    }
    
    public func unsafeArea(for traits: Skin.Traits, alt: Bool) -> CGFloat?
    {
        guard traits.device == .iphone,
              traits.displayType == .edgeToEdge else {
            return 0
        }
        
        return CGFloat(Settings.standardSkinFeatures.gameScreen.unsafeArea)
    }
}

extension StandardControllerSkin
{
    private func buttonAreas(for traits: Skin.Traits) -> (left: CGRect, right: CGRect)
    {
        guard !self.inputMappingMode else {
            return (
                CGRect(x: 0.01, y: 0.35, width: 0.48, height: 0.65),
                CGRect(x: 0.51, y: 0.35, width: 0.48, height: 0.65)
            )
        }
        
        var buttonAreas: (left: CGRect, right: CGRect) = (.zero, .zero)
        
        switch (traits.device, traits.displayType, traits.orientation)
        {
        case (.iphone, .standard, .portrait):
            buttonAreas.left =  CGRect(x: 0.02, y: 0.53, width: 0.46, height: 0.45)
            buttonAreas.right = CGRect(x: 0.52, y: 0.53, width: 0.46, height: 0.45)
            
        case (.iphone, .standard, .landscape):
            buttonAreas.left =  CGRect(x: 0.02, y: 0.02, width: 0.23, height: 0.96)
            buttonAreas.right = CGRect(x: 0.75, y: 0.02, width: 0.23, height: 0.96)
            
        case (.iphone, .edgeToEdge, .portrait):
            buttonAreas.left =  CGRect(x: 0.02, y: 0.53, width: 0.46, height: 0.42)
            buttonAreas.right = CGRect(x: 0.52, y: 0.53, width: 0.46, height: 0.42)
            
        case (.iphone, .edgeToEdge, .landscape):
            buttonAreas.left =  CGRect(x: 0.05, y: 0.02, width: 0.2, height: 0.96)
            buttonAreas.right = CGRect(x: 0.75, y: 0.02, width: 0.2, height: 0.96)
            
        case (.ipad, .standard, .portrait):
            buttonAreas.left =  CGRect(x: 0.05, y: 0.6, width: 0.28, height: 0.35)
            buttonAreas.right = CGRect(x: 0.67, y: 0.6, width: 0.28, height: 0.35)
            
        case (.ipad, .standard, .landscape):
            buttonAreas.left =  CGRect(x: 0.03, y: 0.4, width: 0.2, height: 0.55)
            buttonAreas.right = CGRect(x: 0.77, y: 0.4, width: 0.2, height: 0.55)
            
        case (.ipad, .splitView, .portrait):
            buttonAreas.left =  CGRect(x: 0.02, y: 0.02, width: 0.25, height: 0.96)
            buttonAreas.right = CGRect(x: 0.73, y: 0.02, width: 0.25, height: 0.96)
            
        case (.ipad, .splitView, .landscape):
            buttonAreas.left =  CGRect(x: 0.02, y: 0.02, width: 0.2, height: 0.96)
            buttonAreas.right = CGRect(x: 0.78, y: 0.02, width: 0.2, height: 0.96)
            
        default: break
        }
        
        return (buttonAreas.left, buttonAreas.right)
    }
    
    private func softwareInputs(for traits: Skin.Traits) -> [SoftwareInput]
    {
        var inputs = [SoftwareInput]()
        
        switch self.gameType
        {
        case .gba: inputs = [.dPad, .a, .b, .l, .r, .start, .select, .menu]
        case .gbc: inputs = [.dPad, .a, .b, .start, .select, .menu]
        default: break
        }
        
        guard !self.inputMappingMode else {
            return inputs
        }
        
        inputs.append(.quickSettings)
        
        if Settings.standardSkinFeatures.inputsAndLayout.customButton1 != .null
        {
            inputs.append(.custom1)
        }
        if Settings.standardSkinFeatures.inputsAndLayout.customButton2 != .null
        {
            inputs.append(.custom2)
        }
        
        return inputs
    }
    
    private func screenSize() -> CGSize
    {
        guard let deltaCore = Delta.core(for: self.gameType) else {
            return CGSize()
        }
        
        return deltaCore.videoFormat.dimensions
    }
    
    private func screenStyle() -> (style: DeltaCore.GameViewStyle, isFloating: Bool)
    {
        guard !self.inputMappingMode else {
            return (.flat, false)
        }
        
        let style = Settings.standardSkinFeatures.gameScreen.style
        let isFloating = style == .floating || style == .floatingRounded
        
        return (style, isFloating)
    }
    
    public func hasTouchScreen(for traits: Skin.Traits) -> Bool
    {
        return false
    }
    
    public func customButtonsEnabled() -> Bool
    {
        return Settings.standardSkinFeatures.inputsAndLayout.customButton1 != .null || Settings.standardSkinFeatures.inputsAndLayout.customButton2 != .null
    }
}

public enum SoftwareInput: String, CaseIterable
{
    case dPad
    case a
    case b
    case c
    case x
    case y
    case z
    case l
    case r
    case thumbstick
    case cUp
    case cDown
    case cLeft
    case cRight
    case start
    case select
    case mode
    case touchScreen
    case menu
    case quickSettings
    case toggleAltRepresentations
    case custom1
    case custom2
    
    public func description(_ gameType: GameType, isSplitView: Bool = false) -> String
    {
        switch self
        {
        case .custom1:
            switch Settings.standardSkinFeatures.inputsAndLayout.customButton1
            {
            case .fastForward: return "fastForward"
            case .quickSave: return "quickSave"
            case .quickLoad: return "quickLoad"
            case .screenshot: return "screenshot"
            case .restart: return "restart"
            default: return ""
            }
            
        case .custom2:
            switch Settings.standardSkinFeatures.inputsAndLayout.customButton2
            {
            case .fastForward: return "fastForward"
            case .quickSave: return "quickSave"
            case .quickLoad: return "quickLoad"
            case .screenshot: return "screenshot"
            case .restart: return "restart"
            default: return ""
            }
            
        default: return self.rawValue
        }
    }
    
    var kind: DeltaCore.ControllerSkin.Item.Kind
    {
        switch self
        {
        case .dPad: return .dPad
        case .thumbstick: return .thumbstick
        case .touchScreen: return .touchScreen
        default: return .button
        }
    }
    
    func inputs(_ gameType: GameType, isSplitView: Bool = false) -> DeltaCore.ControllerSkin.Item.Inputs
    {
        switch (self.kind, gameType)
        {
        case (.dPad, _):
            return .directional(up: AnyInput(stringValue: "up", intValue: nil, type: .controller(.controllerSkin), isContinuous: false),
                                down: AnyInput(stringValue: "down", intValue: nil, type: .controller(.controllerSkin), isContinuous: false),
                                left: AnyInput(stringValue: "left", intValue: nil, type: .controller(.controllerSkin), isContinuous: false),
                                right: AnyInput(stringValue: "right", intValue: nil, type: .controller(.controllerSkin), isContinuous: false))
            
        case (.touchScreen, _):
            return .touch(x: AnyInput(stringValue: "touchScreenX", intValue: nil, type: .controller(.controllerSkin), isContinuous: true),
                          y: AnyInput(stringValue: "touchScreenY", intValue: nil, type: .controller(.controllerSkin), isContinuous: true))
              
        case (.thumbstick, _):
            return .directional(up: AnyInput(stringValue: "up", intValue: nil, type: .controller(.controllerSkin), isContinuous: true),
                                down: AnyInput(stringValue: "down", intValue: nil, type: .controller(.controllerSkin), isContinuous: true),
                                left: AnyInput(stringValue: "left", intValue: nil, type: .controller(.controllerSkin), isContinuous: true),
                                right: AnyInput(stringValue: "right", intValue: nil, type: .controller(.controllerSkin), isContinuous: true))
            
        default: return .standard([AnyInput(stringValue: self.description(gameType, isSplitView: isSplitView), intValue: nil, type: .controller(.controllerSkin))])
        }
    }
    
    func frame(leftButtonArea: CGRect, rightButtonArea: CGRect, gameType: GameType, traits: DeltaCore.ControllerSkin.Traits) -> CGRect
    {
        var input = self
        
        switch gameType
        {
        case .gbc, .gba:
            switch (Settings.standardSkinFeatures.inputsAndLayout.abxyLayout, input)
            {
            case (.xbox, .a), (.swapAB, .a): input = .b
            case (.xbox, .b), (.swapAB, .b): input = .a
            case (.xbox, .x), (.swapXY, .x): input = .y
            case (.xbox, .y), (.swapXY, .y): input = .x
            default: break
            }
            
        default: break
        }
        
        var frame = CGRect()
        
        switch input
        {
        case .dPad:
            switch gameType
            {
            case .gba, .gbc:
                frame = leftButtonArea.getFaceRect(for: traits).getInsetSquare()
                
            default: break
            }
            
        case .thumbstick:
            break
            
        case .a:
            switch gameType
            {
            case .gba, .gbc:
                frame = rightButtonArea.getFaceRect(for: traits).getTwoButtonsDiagonal().right
                
            default: break
            }
            
        case .b:
            switch gameType
            {
            case .gba, .gbc:
                frame = rightButtonArea.getFaceRect(for: traits).getTwoButtonsDiagonal().left
                
            default: break
            }
            
        case .c:
            break
            
        case .x:
            break
            
        case .y:
            break
            
        case .z:
            break
            
        case .l:
            switch gameType
            {
            case .gba:
                frame = leftButtonArea.getShoulderRect(for: traits).getTwoButtonsHorizontal().left
                
            default: break
            }
            
        case .r:
            switch gameType
            {
            case .gba:
                frame = rightButtonArea.getShoulderRect(for: traits).getTwoButtonsHorizontal().right
                
            default: break
            }
            
        case .cUp:
            break
            
        case .cDown:
            break
            
        case .cLeft:
            break
            
        case .cRight:
            break
            
        case .select:
            switch gameType
            {
            case .gba, .gbc:
                frame = leftButtonArea.getMenuRect(for: traits).getTwoButtonsHorizontal().right
                
            default: break
            }
            
        case .start:
            switch gameType
            {
            case .gba, .gbc:
                frame = rightButtonArea.getMenuRect(for: traits).getTwoButtonsHorizontal().left
                
            default: break
            }
            
        case .mode:
            break
            
        case .quickSettings:
            switch gameType
            {
            case .gba, .gbc:
                frame = rightButtonArea.getMenuRect(for: traits).getTwoButtonsHorizontal().right
                
            default: break
            }
            
        case .menu:
            switch gameType
            {
            case .gba, .gbc:
                frame = leftButtonArea.getMenuRect(for: traits).getTwoButtonsHorizontal().left
                
            default: break
            }
            
        case .custom1:
            switch gameType
            {
            case .gba:
                frame = leftButtonArea.getShoulderRect(for: traits).getTwoButtonsHorizontal().right
                
            case .gbc:
                frame = leftButtonArea.getShoulderRect(for: traits).getTwoButtonsHorizontal().left
                
            default: break
            }
            
        case .custom2:
            switch gameType
            {
            case .gba:
                frame = rightButtonArea.getShoulderRect(for: traits).getTwoButtonsHorizontal().left
                
            case .gbc:
                frame = rightButtonArea.getShoulderRect(for: traits).getTwoButtonsHorizontal().right
                
            default: break
            }
            
        default: break
        }
        
        return frame
    }
    
    var edges: [String: CGFloat]
    {
        switch self
        {
        case .touchScreen, .toggleAltRepresentations, .thumbstick: return [:]
        default: return StandardControllerSkin.extendedEdges
        }
    }
    
    func assetName(_ gameType: GameType, isSplitView: Bool = false) -> String
    {
        switch self
        {
        case .dPad: return "dpad"
        case .a: return "a.circle"
        case .b: return "b.circle"
        case .l: return "l.square"
        case .r: return "r.square"
        case .thumbstick: return "circle"
        case .start: return "plus.circle"
        case .select: return "minus.circle"
        case .menu: return "ellipsis.circle"
        case .toggleAltRepresentations: return "arrow.up.arrow.down.circle"
        case .quickSettings:
            switch Settings.gameplayFeatures.quickSettings.buttonReplacement
            {
            case .fastForward: return "forward.circle"
            case .quickSave: return "arrow.down.to.line.circle"
            case .quickLoad: return "arrow.up.to.line.circle"
            case .screenshot: return "camera.circle"
            case .restart: return "backward.end.circle"
            default: return "gearshape.circle"
            }
            
        case .custom1:
            switch Settings.standardSkinFeatures.inputsAndLayout.customButton1
            {
            case .fastForward: return "forward.circle"
            case .quickSave: return "arrow.down.to.line.circle"
            case .quickLoad: return "arrow.up.to.line.circle"
            case .screenshot: return "camera.circle"
            case .restart: return "backward.end.circle"
            default: return ""
            }
            
        case .custom2:
            switch Settings.standardSkinFeatures.inputsAndLayout.customButton2
            {
            case .fastForward: return "forward.circle"
            case .quickSave: return "arrow.down.to.line.circle"
            case .quickLoad: return "arrow.up.to.line.circle"
            case .screenshot: return "camera.circle"
            case .restart: return "backward.end.circle"
            default: return ""
            }
            
        default: return ""
        }
    }
}

extension CGRect
{
    func getShoulderRect(for traits: DeltaCore.ControllerSkin.Traits) -> CGRect
    {
        switch (traits.orientation, Settings.standardSkinFeatures.inputsAndLayout.menuLocationPortrait, Settings.standardSkinFeatures.inputsAndLayout.menuLocationLandscape)
        {
        case (.portrait, .top, _), (.landscape, _, .top): return self.getSubRect(sections: 4, index: 2, size: 1)
        case (.portrait, .bottom, _), (.landscape, _, .bottom): return self.getSubRect(sections: 4, index: 1, size: 1)
        }
    }
    
    func getCompactShoulderRect(for traits: DeltaCore.ControllerSkin.Traits) -> CGRect
    {
        switch (traits.orientation, Settings.standardSkinFeatures.inputsAndLayout.menuLocationPortrait, Settings.standardSkinFeatures.inputsAndLayout.menuLocationLandscape)
        {
        case (.portrait, .top, _), (.landscape, _, .top): return self.getSubRect(sections: 5, index: 2, size: 1)
        case (.portrait, .bottom, _), (.landscape, _, .bottom): return self.getSubRect(sections: 5, index: 1, size: 1)
        }
    }
    
    func getFaceRect(for traits: DeltaCore.ControllerSkin.Traits) -> CGRect
    {
        switch (traits.orientation, Settings.standardSkinFeatures.inputsAndLayout.menuLocationPortrait, Settings.standardSkinFeatures.inputsAndLayout.menuLocationLandscape)
        {
        case (.portrait, .top, _), (.landscape, _, .top): return self.getSubRect(sections: 4, index: 3, size: 2)
        case (.portrait, .bottom, _), (.landscape, _, .bottom): return self.getSubRect(sections: 4, index: 2, size: 2)
        }
    }
    
    func getCompactFaceRect(for traits: DeltaCore.ControllerSkin.Traits) -> CGRect
    {
        switch (traits.orientation, Settings.standardSkinFeatures.inputsAndLayout.menuLocationPortrait, Settings.standardSkinFeatures.inputsAndLayout.menuLocationLandscape)
        {
        case (.portrait, .top, _), (.landscape, _, .top): return self.getSubRect(sections: 5, index: 3, size: 3)
        case (.portrait, .bottom, _), (.landscape, _, .bottom): return self.getSubRect(sections: 5, index: 2, size: 3)
        }
    }
    
    func getFaceSplitRect(for traits: DeltaCore.ControllerSkin.Traits) -> (top: CGRect, bottom: CGRect)
    {
        switch (traits.orientation, Settings.standardSkinFeatures.inputsAndLayout.menuLocationPortrait, Settings.standardSkinFeatures.inputsAndLayout.menuLocationLandscape)
        {
        case (.portrait, .top, _), (.landscape, _, .top):
            return (self.getSubRect(sections: 4, index: 3, size: 1), self.getSubRect(sections: 4, index: 4, size: 1))
            
        case (.portrait, .bottom, _), (.landscape, _, .bottom):
            return (self.getSubRect(sections: 4, index: 2, size: 1), self.getSubRect(sections: 4, index: 3, size: 1))
        }
    }
    
    func getMenuRect(for traits: DeltaCore.ControllerSkin.Traits) -> CGRect
    {
        switch (traits.orientation, Settings.standardSkinFeatures.inputsAndLayout.menuLocationPortrait, Settings.standardSkinFeatures.inputsAndLayout.menuLocationLandscape)
        {
        case (.portrait, .top, _), (.landscape, _, .top): return self.getSubRect(sections: 4, index: 1, size: 1)
        case (.portrait, .bottom, _), (.landscape, _, .bottom): return self.getSubRect(sections: 4, index: 4, size: 1)
        }
    }
    
    func getCompactMenuRect(for traits: DeltaCore.ControllerSkin.Traits) -> CGRect
    {
        switch (traits.orientation, Settings.standardSkinFeatures.inputsAndLayout.menuLocationPortrait, Settings.standardSkinFeatures.inputsAndLayout.menuLocationLandscape)
        {
        case (.portrait, .top, _), (.landscape, _, .top): return self.getSubRect(sections: 5, index: 1, size: 1)
        case (.portrait, .bottom, _), (.landscape, _, .bottom): return self.getSubRect(sections: 5, index: 5, size: 1)
        }
    }
}
