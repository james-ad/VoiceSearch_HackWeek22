//
//  ViewController.swift
//  VoiceSearch
//
//  Created by James Dunn on 3/1/21.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    let button = UIButton()
    let label = UILabel()
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var timer: Timer?
    var wordCount: Int = 0 {
        didSet {
            print("Speech count currently at: \(wordCount)")
            DispatchQueue.main.async {
                self.timer?.invalidate()
                self.timer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(self.stopRecording), userInfo: nil, repeats: false)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        speechRecognizer?.delegate = self
        SFSpeechRecognizer.requestAuthorization {
            status in
            var buttonState = false
            switch status {
            case .authorized:
                buttonState = true
                print("Permission received")
            case .notDetermined:
                buttonState = false
                print("Speech recognition not allowed by user")
            case .denied:
                buttonState = false
                print("User did not give permission to use speech recognition")
            case .restricted:
                buttonState = false
                print("Speech recognition not supported on this device")
            @unknown default:
                print("Error: Uknown authorization status")
            }
            DispatchQueue.main.async {
                self.button.isEnabled = buttonState
            }
        }
    }
    
    override func loadView() {
        super.loadView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        layoutPage()
    }
    
    func recordAndRecognizeSpeech() {
        if !speechRecognizer!.isAvailable {
            print("Speech Recognizer Not Available")
            return
        }
        if recognitionTask != nil {
            if recognitionTask?.isFinishing != nil {
            stopRecording()
                return
            }
        }
        let audioSession = AVAudioSession.sharedInstance()
        do {
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Could Not Start Audio Session")
            print("/nAudio Session Error: \(error)")
        }
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat, block: { buffer, _ in
            self.request.append(buffer)
        })
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("ERROR: \(error)")
        }
        
        guard let myRecognizer = SFSpeechRecognizer() else {
            // A recognizer is not supported for the current locale
            return
        }
        if !myRecognizer.isAvailable {
            // A recognizer is not available right now
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            if let result = result {
                let bestString = result.bestTranscription.formattedString
                let resultsWordCount = result.bestTranscription.segments.count
                self.label.text = bestString
                
                if self.recognitionTask?.state.rawValue == 1 && self.wordCount != resultsWordCount {
                    print("Running")
                    self.wordCount = resultsWordCount
                }
                print("Results count: \(result.bestTranscription.segments.count)")
                
                if result.isFinal {
                    print("TASK IS Final")
                    self.request.endAudio()
                    self.stopRecording()
                }
            } else if let error = error {
                print("RECOGNITION ERROR: \(error)")
            }
        })
    }
    
    @objc func stopRecording() {
        print("STOP RECORDING")
        timer?.invalidate()
        recognitionTask?.finish()
        recognitionTask = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        sleep(1)
    }
    
    func layoutPage() {
        button.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        
        button.setTitle("Voice Search", for: .normal)
        button.setTitleColor(UIColor.blue, for: .normal)
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.layer.borderWidth = 2
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.numberOfLines = 0
        button.contentEdgeInsets = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10)
        
        label.text = "Voice Results"
        label.textColor = UIColor.black
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        
        view.addSubview(button)
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 20)
        ])
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        print("Voice Search Activated!")
        self.recordAndRecognizeSpeech()
    }
    
    
}

