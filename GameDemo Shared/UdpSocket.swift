//
//  UdpSocket.swift
//  GameDemo
//
//  Created by yongjie on 2023/5/8.
//

import Foundation
import CocoaAsyncSocket

protocol SocketProtocol {
    func sendMessage(_ msg: [String: Any])
}

protocol SocketDelegate: AnyObject {
    func socket(_ socket: SocketProtocol, didReceiveMessages messages: [[String: Any]])
}

class UdpSocket: NSObject, SocketProtocol {
    weak var delegate: SocketDelegate?
    
    func sendMessage(_ msg: [String : Any]) {
        let data = msg.merging([
            MessageKey.messageTag.rawValue: sendTag
        ]) { $1 }
        
        var json = try! JSONSerialization.data(withJSONObject: data)
        json.append(MessageDelimiterData)
        
//        print("udp will send", sendTag, data)
        sendImp(json, tag: sendTag)
        sendTag += 1
    }
    
    func handleReceiveData(_ data: Data) {
        let messages = data.split(separator: MessageDelimiterData)
            .compactMap({ d in
                try? JSONSerialization.jsonObject(with: d) as? [String: Any]
            })
        
        print("did receive", messages)
        DispatchQueue.main.async {
            self.delegate?.socket(self, didReceiveMessages: messages)
        }
    }
    
    fileprivate func sendImp(_ data: Data, tag: Int) {
        fatalError()
    }
    
    //TODO:: 连接失败后重试
    private(set) var sendTag = 0
    var receiveTag = 0
}

class UdpClientSocket: UdpSocket, GCDAsyncUdpSocketDelegate {
    let remoteHost: String
    let port: UInt16
    
    init(remoteHost: String, port: UInt16, delegate: SocketDelegate) {
        self.remoteHost = remoteHost
        self.port = port
        super.init()
        
        self.delegate = delegate
        do {
            sendImp("heart".data(using: .utf8)!, tag: -1)
            try socket.beginReceiving()
        } catch let error {
            print("udp init socket error", error)
        }
        
    }
    
    override func sendImp(_ data: Data, tag: Int) {
        socket.send(data, toHost: remoteHost, port: port, withTimeout: 1, tag: tag)
    }
    
    lazy var queue = DispatchQueue(label: "udpClientSocket_queue")
    lazy var socket: GCDAsyncUdpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: queue)
    
    //MARK: ---------- GCDAsyncUdpSocketDelegate ---------
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        print("udp close", error as Any)
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        print("did send")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        print("did not send")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        handleReceiveData(data)
    }
}

class UdpSeverSocket: UdpSocket, GCDAsyncUdpSocketDelegate {
    let port: UInt16
    init(port: UInt16, delegate: SocketDelegate) {
        self.port = port
        
        super.init()
        self.delegate = delegate
        _ = socket
    }
    
    override func sendImp(_ data: Data, tag: Int) {
        guard let address = connectedAddress else { return }
        socket.send(data, toAddress: address, withTimeout: 1, tag: tag)
//        socket.send(data, toHost: address.host, port: address.port, withTimeout: 1, tag: tag)
    }
    
    // 连接到服务器上的client地址.TODO::处理多个client
    var connectedAddress: Data?
    lazy var queue = DispatchQueue(label: "udpServerSocket_queue")
    lazy var socket: GCDAsyncUdpSocket = {
        let s = GCDAsyncUdpSocket(delegate: self, delegateQueue: queue)
        do {
            try s.bind(toPort: port)
            try s.beginReceiving()
        } catch let error {
            print("udp init socket error", error)
        }
        return s
    }()
    
    //MARK: ---------- GCDAsyncUdpSocketDelegate ---------
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        print("udp close", error as Any)
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
//        print("did send")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        print("did not send")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        // TODO:: 这里保存address会导致崩溃？？？使用.global()，不同并行线程导致的？？
        //        remoteAddress = address
        //        if remoteAddress == nil {
        //            remoteAddress = NSData.init(data: address) as Data
        //        }
        //        toHost = GCDAsyncUdpSocket.host(fromAddress: address)
        //        toPort = GCDAsyncUdpSocket.port(fromAddress: address)
        
        connectedAddress = address
        //        print(connectedAddress)
        
        handleReceiveData(data)
    }
}
