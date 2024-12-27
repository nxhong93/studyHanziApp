//
//  File.swift
//  
//
//  Created by Morten Bertz on 2020/07/03.
//

import Foundation
import SwiftUI

#if canImport(UIKit)
import PencilKit

internal extension Color{
    static let quaternaryLabel = Color(UIColor.quaternaryLabel)
}


public class CanvasConfiguration:ObservableObject{
    @Published var backgroundColor = Color.black
    @Published var foregroundColor = Color.red
    @Published var strokeColor = UIColor.green
    @Published var strokeWidth : CGFloat = 5
    @Published var toolType:PKInkingTool.InkType = .pen
    @Published var showStandardButtons = true
    @Published var isDarkMode: Bool = true
    
    public init(){}
}



#else

internal extension Color{
    static let quaternaryLabel = Color(NSColor.quaternaryLabelColor)
}

#endif
