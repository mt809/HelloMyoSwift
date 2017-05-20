//
//  SpeechT.swift
//  cc
//
//  Created by mt on 3/20/17.
//  Copyright © 2017 mt. All rights reserved.
//

import Speech
import AVFoundation

class SpeechT{
    
    private(set) var isTranscribing: Bool = false
    var onTranscriptionCompletion: ((String) -> ())?
    var extmov = false
    private let speechRecognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    init() {
        SFSpeechRecognizer.requestAuthorization() {
            status in
            if status == .authorized {
                print("(Y)")
            }
            else {
                fatalError("(N)")
            }
        }
    }
    
    func start() {
        
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        do {
            try createAudioSession() {
                buffer in
                recognitionRequest.append(buffer)
            }
        }
        catch {
            fatalError("Error setting up microphone input listener!")
        }
        
        speechRecognizer?.recognitionTask(with: recognitionRequest) {
            [weak self]
            result, error in
            guard let result = result else {
                print(error?.localizedDescription as Any)
                return
            }
            
            if result.isFinal {
                self?.onTranscriptionCompletion?(result.bestTranscription.formattedString)
            }
        }
        
        
        self.recognitionRequest = recognitionRequest
        
        isTranscribing = true
    }
    
    func stop() {
        recognitionRequest?.endAudio()
        audioEngine.stop()
        audioEngine.inputNode?.removeTap(onBus: 0)
        isTranscribing = false
    }
    
    
    private func createAudioSession(onNewBufferReceived: @escaping (AVAudioPCMBuffer) -> ()) throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        guard let inputNode = audioEngine.inputNode else { fatalError("Audio engine has no input node") }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            onNewBufferReceived(buffer)
        }
        
        audioEngine.prepare()
        
        try audioEngine.start()
    }
    
}
