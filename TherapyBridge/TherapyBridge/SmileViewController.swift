import AVFoundation
import UIKit
import Vision

class SmileViewController: UIViewController {
    
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var faceLayers: [CAShapeLayer] = []
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var scoreLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCamera()
        captureSession.startRunning()

        self.view.bringSubviewToFront(scoreLabel)
        scoreLabel.text = ""

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.cameraView.bounds
    }
    
    private func setupCamera() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
        if let device = deviceDiscoverySession.devices.first {
            if let deviceInput = try? AVCaptureDeviceInput(device: device) {
                if captureSession.canAddInput(deviceInput) {
                    captureSession.addInput(deviceInput)
                    
                    setupPreview()
                }
            }
        }
    }
    
    private func setupPreview() {
        self.previewLayer.videoGravity = .resizeAspectFill
        self.cameraView.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.cameraView.bounds
        
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]

        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera queue"))
        self.captureSession.addOutput(self.videoDataOutput)
        
        let videoConnection = self.videoDataOutput.connection(with: .video)
        videoConnection?.videoRotationAngle = 90.0
    }

    private func displayScore(score: Int) {
        self.scoreLabel.text = "Smile Score: \(score)"
        self.scoreLabel.isHidden = false
    }

    private func hideScore() {
        self.scoreLabel.isHidden = true
    }
}

// [3] Top, [7] RCorner, [10] Bottom, [13] LCorner

extension SmileViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                self.faceLayers.forEach({ drawing in drawing.removeFromSuperlayer() })

                if let observations = request.results as? [VNFaceObservation] {
                    self.handleFaceDetectionObservations(observations: observations)
                }
            }
        })

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .leftMirrored, options: [:])

        do {
            try imageRequestHandler.perform([faceDetectionRequest])
        } catch {
            print("Error performing face detection request: \(error.localizedDescription)")
        }
    }
    
    private func handleFaceDetectionObservations(observations: [VNFaceObservation]) {
        for observation in observations {
            let faceRectConverted = self.previewLayer.layerRectConverted(fromMetadataOutputRect: observation.boundingBox)
            let faceRectanglePath = CGPath(rect: faceRectConverted, transform: nil)
            
            let faceLayer = CAShapeLayer()
            faceLayer.path = faceRectanglePath
            faceLayer.fillColor = UIColor.clear.cgColor
            faceLayer.strokeColor = UIColor.yellow.cgColor
            
            self.faceLayers.append(faceLayer)
            self.cameraView.layer.addSublayer(faceLayer)
            
            // Face Landmarks
            if let landmarks = observation.landmarks {
                if let outerLips = landmarks.outerLips {
                    
                    let normalizedPoints = outerLips.normalizedPoints
                    guard normalizedPoints.count > 13 else {
                        continue
                    }
                    
                    let topPoint = CGPoint(
                        x: normalizedPoints[3].y * faceRectConverted.height + faceRectConverted.origin.x,
                        y: normalizedPoints[3].x * faceRectConverted.width + faceRectConverted.origin.y
                    )
                    let rightCornerPoint = CGPoint(
                        x: normalizedPoints[7].y * faceRectConverted.height + faceRectConverted.origin.x,
                        y: normalizedPoints[7].x * faceRectConverted.width + faceRectConverted.origin.y
                    )
                    let bottomPoint = CGPoint(
                        x: normalizedPoints[10].y * faceRectConverted.height + faceRectConverted.origin.x,
                        y: normalizedPoints[10].x * faceRectConverted.width + faceRectConverted.origin.y
                    )
                    let leftCornerPoint = CGPoint(
                        x: normalizedPoints[13].y * faceRectConverted.height + faceRectConverted.origin.x,
                        y: normalizedPoints[13].x * faceRectConverted.width + faceRectConverted.origin.y
                    )

                    let averageY = (rightCornerPoint.y + leftCornerPoint.y) / 2.0
                    let height = (topPoint.y - bottomPoint.y)
                    let difference = topPoint.y - averageY
                    let threshold = 0.9

                    let isSmiling = (difference >= 0 || ((averageY - bottomPoint.y) / height) >= threshold)
                    
                    if isSmiling {
                        let score = Int(((averageY - bottomPoint.y) / height) * 100.0)
                        displayScore(score: score)
                    } else {
                        hideScore()
                    }
                }
            }
        }
    }
    
    private func handleLandmark(_ eye: VNFaceLandmarkRegion2D, faceBoundingBox: CGRect) {
    }
}
