//
//  Media.swift
//  GameDemo
//
//  Created by yongjie on 2023/5/19.
//

import Foundation
import AVFoundation

class AudioPlay {
    var audioPlayer: AVAudioPlayer?
    
    func play(character: Character) {
        play(source: .init(character), extension: "wav")
    }
    
    func play(mood: String) {
        play(source: mood, extension: "wav")
    }
    
    func play(source name: String, extension: String) {
        audioPlayer?.stop()
        
        let bundle = Bundle.main
        if let url = bundle.url(forResource: name, withExtension: "wav") {
            do {
                try playAudio(url: url)
            } catch let error {
                print("error", error)
            }
        }
    }
    
    private func playAudio(url: URL) throws {
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
    }
}
