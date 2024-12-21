// UNUSED

import AVKit
import AVFoundation
import UIKit

class BreatheViewController: UIViewController {

    @IBOutlet weak var micView: UIView! // Referencing outlet for the microphone graph view
    @IBOutlet weak var videoView: UIView! // Referencing outlet for the video view

    var micAudio: AudioModel? // Audio model for the microphone

    lazy var micGraph: MetalGraph? = {
        return MetalGraph(userView: self.micView)
    }()

    var updateTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize the microphone audio model
        micAudio = AudioModel(buffer_size: 1024 * 4)

        // Add a time-domain graph to the microphone graph view
        micGraph?.addGraph(withName: "mic",
                           shouldNormalizeForFFT: false,
                           numPointsInGraph: 1024 * 4)

        // Start microphone processing
        micAudio?.startMicrophoneProcessing(withFps: 10)
        micAudio?.play()

        // Update the microphone graph periodically
        updateTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self,
                                           selector: #selector(self.updateMicGraph),
                                           userInfo: nil, repeats: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Ensure the video is in the bundle
        guard let url = Bundle.main.url(forResource: "Breathing", withExtension: "mp4") else {
            print("Error: Could not find the video file in the bundle.")
            return
        }

        let player = AVPlayer(url: url)
        let layer = AVPlayerLayer(player: player)
        layer.frame = videoView.bounds
        videoView.layer.addSublayer(layer)

        player.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Stop the timer
        updateTimer?.invalidate()
        updateTimer = nil

        // Stop microphone processing
        micAudio?.stop()
        micAudio = nil
    }

    @objc
    func updateMicGraph() {
        guard let micAudio = self.micAudio else {
            return  // Exit if `micAudio` is nil
        }

        // Apply a scaling factor to the microphone data
        let scaledMicData = micAudio.timeData.map { $0 * 7.5 }
        self.micGraph?.updateGraph(
            data: scaledMicData,
            forKey: "mic"
        )
    }
}
