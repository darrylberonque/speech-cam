//
//  ViewController.swift
//  SpeechCam
//
//  Created by Darryl Beronque on 3/6/18.
//  Copyright © 2018 Darryl Beronque. All rights reserved.
//

import UIKit
import Speech
import AVFoundation

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate, SFSpeechRecognizerDelegate {
    
    var captureSession = AVCaptureSession()
    
    // Camera Session Vars
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currDevice: AVCaptureDevice?
    
    var photoOutput: AVCapturePhotoOutput?
    var captureLayerOutput: AVCaptureVideoPreviewLayer?
    var image: UIImage?
    var doubleTap = UITapGestureRecognizer()
    
    var counter = 0
    
    // Speech Recognition Vars
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    
    @IBOutlet weak var spokenWord: UILabel!
    @IBOutlet weak var beginRecordBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup camera functionalities
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        runCaptureSession()
        
        
    }
    
    func setupCaptureSession() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    func setupDevice() {
        let deviceDiscoverSession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        
        let devices = deviceDiscoverSession.devices
        
        for device in devices {
            if(device.position == AVCaptureDevice.Position.back) {
                backCamera = device
            } else if(device.position == AVCaptureDevice.Position.front) {
                frontCamera = device
            }
        }
        
        currDevice?.focusMode = .continuousAutoFocus
        currDevice = backCamera
        
    }
    
    func setupInputOutput() {
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: currDevice!)
            captureSession.addInput(deviceInput)
            photoOutput = AVCapturePhotoOutput()
            photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
            captureSession.addOutput(photoOutput!)
        } catch {
            print(error)
        }
        
    }
    
    func setupPreviewLayer() {
        captureLayerOutput = AVCaptureVideoPreviewLayer(session: captureSession)
        captureLayerOutput?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        captureLayerOutput?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        captureLayerOutput?.frame = self.view.frame
        self.view.layer.insertSublayer(captureLayerOutput!, at: 0)
    }
    
    func runCaptureSession() {
        captureSession.startRunning()
        doubleTap.numberOfTapsRequired = 2
        doubleTap.addTarget(self, action: #selector(toggleCamera))
        view.addGestureRecognizer(doubleTap)
    }
    
    @objc func toggleCamera() {
        captureSession.beginConfiguration()
        
        let newDevice = (currDevice?.position == .back) ? frontCamera : backCamera
        
        for input in captureSession.inputs {
            captureSession.removeInput(input as! AVCaptureDeviceInput)
        }
        
        let cameraInput: AVCaptureDeviceInput
        do {
            cameraInput = try AVCaptureDeviceInput(device: newDevice!)
            if(captureSession.canAddInput(cameraInput)) {
                captureSession.addInput(cameraInput)
            }
        } catch {
            print("An error has occured while switching inputs\(error)")
        }
        
        currDevice = newDevice
        captureSession.commitConfiguration()
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            image = UIImage(data: imageData)
            UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
        }
    }
    
    @IBAction func takingPicture(_ sender: UIButton) {
        
        // Recording audio
        if(!audioEngine.isRunning) {
            beginRecordBtn.setImage(UIImage(named: "cameraButtonOn"), for: .normal)
            sender.animateCamBtn()
            beginRecordBtn.setTitle("Stop Recording", for: .normal)
            recognizeSpeech()
        } else {
            beginRecordBtn.setImage(UIImage(named: "cameraButtonOff"), for: .normal)
            sender.disableAnimation()
            beginRecordBtn.setTitle("Start Recording", for: .normal)
            audioEngine.stop()
            let node = audioEngine.inputNode
            node.removeTap(onBus: 0)
            recognitionTask?.cancel()
            print("Stopped recognizing incoming speech...")
        }
        
    }
    
    func recognizeSpeech() {
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            self.request.append(buffer)
        }
        
        audioEngine.prepare()

        do{
            try audioEngine.start()
        } catch {
            print("Error with the audio engine: \(error)")
        }
        
        guard let myRecognizer = SFSpeechRecognizer() else {
            print("Recognizer not compatible with locale")
            return
        }
        
        if(!myRecognizer.isAvailable) {
            print("Recognizer is currently unavailable")
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { (result, error) in
            if let result = result {
                print(result.bestTranscription.formattedString)
                let bestString = result.bestTranscription.formattedString
                
                var lastString: String = ""
                for segment in result.bestTranscription.segments {
                    let indexTo = bestString.index(bestString.startIndex, offsetBy: segment.substringRange.location)
                    lastString = bestString.substring(from: indexTo)
                }
                
                self.takePicture(with: lastString)
            } else {
                print("Error has occured with speech recognition: \(error)")
            }
        })
        
    }
    
    func takePicture(with: String) {
        counter = counter + 1
        if(counter == 3) {
            spokenWord.text = "''\(with.capitalized)''"
            if(with.lowercased() == "cheese") {
                UIView.animate(withDuration: 0.5, animations: {
                    self.view.alpha = 0.0
                    self.view.alpha = 100
                })
                let cameraSettings = AVCapturePhotoSettings()
                photoOutput?.capturePhoto(with: cameraSettings, delegate: self)
            } else {
                print("Unable to take picture")
            }
            counter = 0
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

