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
        self.scene = scene
        
        // Present the scene
        let skView = self.view as! SKView
        skView.presentScene(scene)
        
        skView.ignoresSiblingOrder = true
        
        skView.showsFPS = true
        skView.showsNodeCount = true
        
        setupSocket()
    }
    
    lazy var socket = GCDAsyncSocket(delegate: self, delegateQueue: .main)
    var newSockets = [GCDAsyncSocket]()
    func setupSocket() {
        do {
            try socket.accept(onPort: 4000)
        } catch let error {
            print("socket accept error", error)
        }
        
    }
}

extension GameViewController: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("socket accept new")
        
        newSockets.append(newSocket)
        newSocket.readData(to: "---".data(using: .utf8), withTimeout: -1, tag: 1)
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("disconnect", err)
        newSockets.removeAll(where: { $0 == sock})
    }
    
    func socketDidCloseReadStream(_ sock: GCDAsyncSocket) {
        print("close")
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        var d = data
        let t = "---".data(using: .utf8)!
//        //todo 保留最后一个有效数据
//        d.removeSubrange(d.range(of: t)!.startIndex..<d.count)
        
        data.split(separator: t)
            .forEach { d in
                let dic = try? JSONSerialization.jsonObject(with: d) as? [String: Any]
                print("read", dic?["tag"])
                newSockets.first?.readData(withTimeout: -1, tag: 1)
                if let x = dic?["xOffset"] as? CGFloat {
                    scene?.changePosition(offset: .init(x: x, y: 0))
                }
                
            }
    }
}

extension Data {
    func split(separator: Data) -> [Data] {
        var chunks: [Data] = []
        var pos = startIndex
        // Find next occurrence of separator after current position:
        while let r = self[pos...].range(of: separator) {
            // Append if non-empty:
            if r.lowerBound > pos {
                chunks.append(self[pos..<r.lowerBound])
            }
            // Update current position:
            pos = r.upperBound
        }
        // Append final chunk, if non-empty:
        if pos < endIndex {
            chunks.append(self[pos..<endIndex])
        }
        return chunks
    }
}
