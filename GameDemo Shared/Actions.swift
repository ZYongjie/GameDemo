//
//  Actions.swift
//  GameDemo
//
//  Created by yongjie on 2023/5/8.
//

import Foundation

let MessageDelimiterData = "---".data(using: .utf8)!

enum MessageKey: String {
    case actionName
    case messageTag
    case impulse
    case feedbackStyle
}

enum ClientAction: String {
    case accelerate
    case didTap
    case startLongPress
    case stopLongPress
}

enum SeverAction: String {
    case impactFeedback
}
