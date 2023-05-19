//
//  GameViewController.swift
//  GameDemo macOS
//
//  Created by yongjie on 2023/4/28.
//

import Cocoa
import SpriteKit
import GameplayKit
import CocoaAsyncSocket

class GameViewController: NSViewController {

    weak var scene: GameScene?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = GameScene.newGameScene()
        scene.carDelegate = self
        self.scene = scene
        
        // Present the scene
        let skView = self.view as! SKView
        skView.presentScene(scene)
        
//        skView.ignoresSiblingOrder = true
        
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsPhysics = true
        
        _ = udpSocket
    }
    
    lazy var udpSocket = UdpSeverSocket(port: 4002, delegate: self)
    
    //MARK: ---------- handle actions ---------
    func handleAction(_ dic: [String: Any]) {
        switch ClientAction(rawValue: dic[MessageKey.actionName.rawValue] as! String) {
        case .accelerate:
            scene?.applyImpulse(dx: dic[MessageKey.impulse.rawValue] as! CGFloat)
        case .didTap:
            if scene?.state == .over {
                scene?.replay()
            }
            
        default:
            break
        }
    }
}

extension GameViewController: SocketDelegate {
    func socket(_ socket: SocketProtocol, didReceiveMessages messages: [[String : Any]]) {
        messages.forEach { msg in
            handleAction(msg)
        }
    }
}

extension GameViewController: CarGameSceneDelegate {
    func scene(didContactTrack scene: GameScene) {
        udpSocket.sendMessage([
            MessageKey.actionName.rawValue: SeverAction.impactFeedback.rawValue,
            MessageKey.feedbackStyle.rawValue: 0
        ])
    }

    func scene(didContactObstacle scene: GameScene) {
        udpSocket.sendMessage([
            MessageKey.actionName.rawValue: SeverAction.impactFeedback.rawValue,
            MessageKey.feedbackStyle.rawValue: 1
        ])
    }
    
}
