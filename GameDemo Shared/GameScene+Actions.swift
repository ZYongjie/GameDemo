//
//  GameScene+Actions.swift
//  GameDemo
//
//  Created by yongjie on 2023/5/22.
//

import Foundation

extension GameScene {
    func hanle(client action: ClientAction) {
        switch action {
        case .startLongPress:
            speedUp()
        case .stopLongPress:
            resetSpeed()
        case .didTap:
            if state == .over || state == .passed {
                replay()
            }
        default:
            break
        }
    }
    
    
}
