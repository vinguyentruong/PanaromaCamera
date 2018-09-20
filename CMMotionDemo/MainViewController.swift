//
//  ViewController.swift
//  CMMotionDemo
//
//  Created by David Nguyen Truong on 9/16/18.
//  Copyright © 2018 David Nguyen Truong. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import CoreMotion
import CoreLocation
import Photos
import CoreGraphics
import CTPanoramaView
import SwiftyJSON

class ViewController: UIViewController {
    
    private var captureSession = AVCaptureSession()
    private var backCamera: AVCaptureDevice?
    private var frontCamera: AVCaptureDevice?
    private var currentCamera: AVCaptureDevice?
    private var photoOutput: AVCapturePhotoOutput?
    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    private let motionManager = CMMotionManager()
    private var isCaptured = false
    private var numOfPicture = 0
    private var greenViewX: CGFloat = 100.0
    private var slideCenterYs = [CGFloat]()
    private var lineNumber = 0
    private var numOfHorizontalPic = 0
    private var resetToNewLine = false
    private var progressViews = [UIProgressView]()
    private var panaromaView: CTPanoramaView!
    private var savedImagesJson = [JSON]()
    private var greenViewWidth: CGFloat {
        return view.bounds.width / 2
    }
    
    internal var horizontalDegreeUnit = 0.0
    internal var verticalDegreeUnit = 0.0
    
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var totalPicLabel: UILabel!
    @IBOutlet weak var degreeLabel: UILabel!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var noticeLable: UILabel!
    @IBOutlet weak var slideView: UIView!
    @IBOutlet weak var slideCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var slideCenterXConstraint: NSLayoutConstraint!
    @IBOutlet weak var previewCaptureViewCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var previewCaptureViewCenterXConstraint: NSLayoutConstraint!
    @IBOutlet weak var previewCaptureView: UIView!
    @IBOutlet weak var captureView: UIView!
    @IBOutlet weak var widthConstraintSlideView: NSLayoutConstraint!
    @IBOutlet weak var widthConstraintPreviewCapture: NSLayoutConstraint!
    @IBOutlet weak var progressContainerView: UIView!
    @IBOutlet weak var oldDegreeLabel: UILabel!
    @IBOutlet weak var diffDegreeLabel: UILabel!
    
    // MARK: Specification property
    
    internal var accelX: Double!
    internal var accelY: Double!
    internal var accelZ: Double!
    
    internal var gyroX: Double!
    internal var gyroY: Double!
    internal var gyroZ: Double!
    
    internal var magneticX: Double!
    internal var magneticY: Double!
    internal var magneticZ: Double!
    
    internal var roll: Double!
    internal var pitch: Double!
    internal var yaw: Double!
    
    //MARK: Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPanaromaView()
        setupSlideView()
        setupProgressView()
        setupCoreMotion()
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startRunningCaptureSession()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupPreviewLayer()
        resetHorizonScrollView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        captureSession.stopRunning()
        resetHorizonScrollView()
    }
    
    // MARK: IBAction
    
    @IBAction func backAction(_ sender: Any) {
        captureButton.setImage(#imageLiteral(resourceName: "Start_Camera"), for: .normal)
        resetSlideViews()
        numOfPicture = 0
        lineNumber = 0
        progressViews.forEach { (progressView) in
            progressView.progress = 0
        }
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func captureAction(_ sender: UIButton) {
        isCaptured = !isCaptured
        if isCaptured {
            sender.setImage(#imageLiteral(resourceName: "Stop_Camera"), for: .normal)
            resetToNewLine = true
            takePicture()
            startHorizonScrollSlideView()
        } else {
            sender.setImage(#imageLiteral(resourceName: "Start_Camera"), for: .normal)
            resetSlideViews()
            numOfPicture = 0
            lineNumber = 0
            progressViews.forEach { (progressView) in
                progressView.progress = 0
            }
            resetToNewLine = false
            resetHorizonScrollView()
        }
    }
}

// MARK: Setup views

extension ViewController {
    
    private func setupPanaromaView() {
        panaromaView = CTPanoramaView()
        view.addSubview(panaromaView)
        view.sendSubview(toBack: panaromaView)
        panaromaView.panoramaType = .spherical
        panaromaView.controlMethod = .touch  // Touch based control
        panaromaView.controlMethod = .motion
    }
    
    private func setupSlideView() {
        let verticalUnit = Int(180/verticalDegreeUnit) + 1
        let divider = view.bounds.height / CGFloat(verticalUnit)
        if verticalUnit == 5 {
            slideCenterYs = [divider * 2, divider, divider * 3, divider * 4]
        } else {
            for i in 1..<verticalUnit {
                slideCenterYs.append(divider * CGFloat(i))
            }
        }
        greenViewX = previewCaptureView.bounds.width
        slideView.backgroundColor = UIColor.clear
        previewCaptureView.backgroundColor = UIColor.clear
        numOfHorizontalPic =  Int(360 / horizontalDegreeUnit)
        var xPositionRedView: CGFloat = view.bounds.width / 2
        for _ in 1...numOfHorizontalPic {
            let redCircleView = UIImageView(frame:
                                            CGRect(x:       xPositionRedView - 50,
                                                   y:       slideView.bounds.height / 2 - 50,
                                                   width:   100,
                                                   height:  100))
            xPositionRedView += view.bounds.width / 2
            redCircleView.image = #imageLiteral(resourceName: "img_circle_red")
            slideView.addSubview(redCircleView)
            widthConstraintSlideView.constant += view.bounds.width
            widthConstraintPreviewCapture.constant += view.bounds.width
        }
    }
    
    private func setupProgressView() {
        let progressWidth = (progressContainerView.bounds.width - 8*3)/4
        let progressHeight: CGFloat = 10
        let verticalUnit = Int(180/verticalDegreeUnit)
        for i in 0..<verticalUnit {
            let progress = UIProgressView(frame:
                                        CGRect(x:      CGFloat(i%4)*(progressWidth + CGFloat(16)),
                                               y:      CGFloat(i/4)*(progressHeight + 2),
                                               width:  progressWidth,
                                               height: progressHeight))
            progress.progressTintColor = UIColor.green
            progress.clipsToBounds = true
            progress.layer.cornerRadius = 2
            progressContainerView.addSubview(progress)
            progressViews.append(progress)
        }
        progressViews.forEach { (progressView) in
            progressView.progress = 0
        }
    }
}

// MARK: Actions

extension ViewController {
    
    private func takePicture() {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
        let xFrameGreenView = (previewCaptureView.bounds.width - greenViewWidth)/2 + greenViewWidth * CGFloat(numOfPicture)
        let greenView = UIView(frame: CGRect(
                                            x       : xFrameGreenView,
                                            y       : 0,
                                            width   : greenViewWidth,
                                            height  : previewCaptureView.bounds.height))
        greenView.backgroundColor = UIColor.green
        previewCaptureView.addSubview(greenView)
        numOfPicture += 1
        totalPicLabel.text = "\(numOfPicture)"
        if numOfPicture == numOfHorizontalPic, lineNumber == slideCenterYs.count - 1 {
            let alert = UIAlertController.init(title: "Success", message: "Capture completed", preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default, handler: {_ in
                self.captureAction(self.captureButton)
                let vc = RawEXIFViewController()
                let json = JSON(self.savedImagesJson)
                vc.rawEXIF = json.rawString()
                self.navigationController?.pushViewController(vc, animated: true)
            }))
            self.present(alert, animated: true, completion: nil)
            return
        }
        progressViews[lineNumber].progress = Float(numOfPicture) / Float(numOfHorizontalPic)
        saveInfor()
    }
    
    private func moveToNewLine() {
        self.lineNumber = min(self.lineNumber + 1, self.slideCenterYs.count - 1)
        self.numOfPicture = 0
        self.resetSlideViews()
        self.resetToNewLine = true
    }
    
    private func resetSlideViews() {
        previewCaptureView.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        slideView.transform = CGAffineTransform.identity
        previewCaptureView.transform = CGAffineTransform.identity
    }
    
    private func saveInfor() {
        let imageSpecification = ImageSpecifications()
        imageSpecification.accelX = accelX
        imageSpecification.accelY = accelY
        imageSpecification.accelZ = accelZ
        imageSpecification.gyroX = gyroX
        imageSpecification.gyroY = gyroY
        imageSpecification.gyroZ = gyroZ
        imageSpecification.magneticX = magneticX
        imageSpecification.magneticY = magneticY
        imageSpecification.magneticZ = magneticZ
        imageSpecification.roll = roll
        imageSpecification.pitch = pitch
        imageSpecification.yaw = yaw
        
        self.savedImagesJson.append(imageSpecification.toJson())
    }
    
    private func resetHorizonScrollView() {
        panaromaView.movementHandler = nil
    }
    
    private func startHorizonScrollSlideView() {
        var totalAngle = 0
        var floorAngle = 0
        panaromaView.movementHandler = { [weak self] rotateAngle, _ in
            guard let sSelf = self else {
                return
            }
            let angle = rotateAngle.radiansToDegrees
            let slideCurrentCenterY = Double(sSelf.slideView.center.y)
            let viewHeight = Double(sSelf.view.bounds.height / 2)
            
            if sSelf.isCaptured, sSelf.resetToNewLine {
                sSelf.resetToNewLine = false
                floorAngle = Int(floor(Double(angle)))
            }
            
            if (Int(floor(Double(angle))) - floorAngle) >= 1 {
                totalAngle += 1
            } else if (Int(floor(Double(angle))) - floorAngle) <= -1 {
                totalAngle -= 1
            }
            floorAngle = Int(floor(Double(angle)))
            if totalAngle < 0 {
                totalAngle = 0
                return
            }
            sSelf.degreeLabel.text = "degree: \(Int(floor(Double(angle))))"
            let centerX = -CGFloat(Double(totalAngle) / sSelf.horizontalDegreeUnit) * sSelf.view.bounds.width / 2
            sSelf.previewCaptureView.transform = CGAffineTransform(translationX: centerX, y: 0)
            sSelf.slideView.transform = CGAffineTransform(translationX: centerX, y: 0)
            
            if
                Double(totalAngle) >= sSelf.horizontalDegreeUnit * Double(sSelf.numOfPicture),
                abs(slideCurrentCenterY - viewHeight) <= 10.0 {
                sSelf.takePicture()
                if sSelf.numOfPicture != 0, sSelf.numOfPicture % sSelf.numOfHorizontalPic == 0 {
                    sSelf.moveToNewLine()
                    totalAngle = 0
                }
            }
        }
    }
}

// MARK: Setup core motion

extension ViewController {
    
    private func setupCoreMotion() {
        motionManager.gyroUpdateInterval            = 0.0001
        motionManager.magnetometerUpdateInterval    = 0.00001
        motionManager.accelerometerUpdateInterval   = 0.00001
        motionManager.deviceMotionUpdateInterval    = 1
        let operation = OperationQueue.current!
        setupDeviceMotionUpdate(motionManager: motionManager, operation: operation)
        setupAccelerometerUpdate(motionManager: motionManager, operation: operation)
        setupGyroUpdate(motionManager: motionManager, operation: operation)
        setupMagnetometerUpdate(motionManager: motionManager, operation: operation)
    }
    
    private func setupDeviceMotionUpdate(motionManager: CMMotionManager, operation: OperationQueue) {
        motionManager.startDeviceMotionUpdates(to: operation) { [weak self] (data, error) in
            guard let sSelf = self else {
                return
            }
            if let err = error {
                print(err.localizedDescription)
                return
            }
            sSelf.roll = data?.attitude.roll ?? 0.0
            sSelf.pitch = data?.attitude.pitch ?? 0.0
            sSelf.yaw = data?.attitude.yaw ?? 0.0
        }
    }
    
    private func setupAccelerometerUpdate(motionManager: CMMotionManager, operation: OperationQueue) {
        let viewHeight = view.bounds.height
        motionManager.startAccelerometerUpdates(to: operation) { (data, error) in
            self.accelX = data?.acceleration.x ?? 0.0
            self.accelY = data?.acceleration.y ?? 0.0
            self.accelZ = data?.acceleration.z ?? 0.0
            
            let accelZ = data?.acceleration.z ?? 0.0
            let centerZ =  -(0.5 * viewHeight * CGFloat(1 - accelZ) - self.slideCenterYs[self.lineNumber])
            UIView.animate(withDuration: 0.33, animations: {
                self.slideCenterYConstraint.constant = centerZ
                self.previewCaptureViewCenterYConstraint.constant = centerZ
                self.view.layoutIfNeeded()
            }) {_ in
                let slideCurrentCenterY = Double(self.slideView.center.y)
                let viewHeight = Double(self.view.bounds.height / 2)
                if abs(slideCurrentCenterY - viewHeight) <= 30.0 {
                    self.noticeLable.isHidden = true
                    self.captureButton.isHidden = false
                } else {
                    self.noticeLable.isHidden = false
                    self.captureButton.isHidden = self.isCaptured ? false : true
                }
            }
        }
    }
    
    private func setupGyroUpdate(motionManager: CMMotionManager, operation: OperationQueue) {
        motionManager.startGyroUpdates(to: operation) { (data, error) in
            self.gyroX = data?.rotationRate.x ?? 0.0
            self.gyroY = data?.rotationRate.y ?? 0.0
            self.gyroZ = data?.rotationRate.z ?? 0.0
        }
    }
    
    private func setupMagnetometerUpdate(motionManager: CMMotionManager, operation: OperationQueue) {
        motionManager.startMagnetometerUpdates(to: operation) { (data, error) in
            self.magneticX = data?.magneticField.x ?? 0.0
            self.magneticY = data?.magneticField.y ?? 0.0
            self.magneticZ = data?.magneticField.z ?? 0.0
        }
    }
}

// MARK: Setup camera screen

extension ViewController {
    
    private func setupCaptureSession() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    private func setupDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.back)
        let devices = deviceDiscoverySession.devices
        
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                backCamera = device
            } else if device.position == AVCaptureDevice.Position.front {
                frontCamera = device
            }
        }
        currentCamera = backCamera
    }
    
    private func setupInputOutput() {
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera!)
            captureSession.addInput(captureDeviceInput)
            photoOutput = AVCapturePhotoOutput()
            photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
            captureSession.addOutput(photoOutput!)
        } catch {
            print(error)
        }
    }
    
    private func setupPreviewLayer() {
        if cameraPreviewLayer != nil {
            return
        }
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        cameraPreviewLayer?.frame = captureView.frame
        self.captureView.layer.insertSublayer(cameraPreviewLayer!, at: 0)
    }
    
    private func startRunningCaptureSession() {
        captureSession.startRunning()
    }
}

// MARK: AVCapturePhotoCaptureDelegate

extension ViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData){
            CustomAlbum.shared.saveImage(image: image)
        }
    }
    
}


