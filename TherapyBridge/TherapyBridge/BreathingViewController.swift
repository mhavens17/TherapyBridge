import UIKit
import Metal
import AVFoundation

let AUDIO_BUFFER_SIZE = 1024*4

// Timer
var updateTimer: Timer?

class BreathingViewController: UIViewController {
    
    @IBOutlet weak var graphView: UIView! // Referencing outlet for the graph view
    @IBOutlet weak var micView: UIView! // Referencing outlet for the microphone graph view

    var audio: AudioModel? // Make the audio model optional so it can be set to nil
    var micAudio: AudioModel? // Second audio model for the microphone

    lazy var graph: MetalGraph? = {
        return MetalGraph(userView: self.graphView)
    }()

    lazy var micGraph: MetalGraph? = {
        return MetalGraph(userView: self.micView)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure audio session to observe phone volume
        configureAudioSession()

        // Add in the time-domain graph for display
        graph?.addGraph(withName: "time",
                        shouldNormalizeForFFT: false,
                        numPointsInGraph: AUDIO_BUFFER_SIZE)

        micGraph?.addGraph(withName: "mic",
                           shouldNormalizeForFFT: false,
                           numPointsInGraph: AUDIO_BUFFER_SIZE)

        // Start audio processing
        audio?.startProcessingAudioFile()
        audio?.play()

        // Start microphone processing
        micAudio?.startMicrophoneProcessing(withFps: 10)
        micAudio?.play()

        // Update the graph periodically
        updateTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self,
                                           selector: #selector(self.updateGraph),
                                           userInfo: nil,
                                           repeats: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Initialize the audio models
        audio = AudioModel(buffer_size: AUDIO_BUFFER_SIZE)
        micAudio = AudioModel(buffer_size: AUDIO_BUFFER_SIZE)
        
        // Start processing audio from the file
        audio?.startProcessingAudioFile()
        audio?.play()

        // Start microphone processing
        micAudio?.startMicrophoneProcessing(withFps: 10)
        micAudio?.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop the timer
        updateTimer?.invalidate()
        updateTimer = nil

        // Stop any audio processing and set the audio models to nil
        audio?.stop()
        audio = nil

        micAudio?.stop()
        micAudio = nil
    }

    func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true)

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleVolumeChange),
                name: AVAudioSession.silenceSecondaryAudioHintNotification,
                object: audioSession
            )
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    @objc func handleVolumeChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reason = userInfo[AVAudioSessionSilenceSecondaryAudioHintTypeKey] as? UInt else { return }

        if reason == AVAudioSession.SilenceSecondaryAudioHintType.begin.rawValue {
            print("Secondary audio silenced")
            // Adjust audio playback volume or behavior accordingly
        } else {
            print("Secondary audio resumed")
        }
    }

    @objc
    func updateGraph() {
        guard let audio = self.audio, let micAudio = self.micAudio else {
            return  // Exit if `audio` or `micAudio` is nil
        }

        // Apply a scaling factor to the audio data
        let scaledData = audio.timeData.map { $0 * 8.0 }
        self.graph?.updateGraph(
            data: scaledData,
            forKey: "time"
        )

        // Apply a scaling factor to the microphone data
        let scaledMicData = micAudio.timeData.map { $0 * 7.5 }
        self.micGraph?.updateGraph(
            data: scaledMicData,
            forKey: "mic"
        )
    }
}
