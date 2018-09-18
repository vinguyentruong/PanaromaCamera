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
    private var totalDegrees = 0.0
    private var locationManager = CLLocationManager()
    private var oldAngle: CLLocationDirection? = nil
    private var greenViewX: CGFloat = 100.0
    private var lastCenter: CGFloat = 0.0
    private var slideCenterYs = [CGFloat]()
    private var lineNumber = 0
    private var greenViewWidth: CGFloat {
        return view.bounds.width / 2
    }
    private var numOfHorizontalPic = 0
    private var progressViews = [UIProgressView]()
    
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
        
        setupViews()
        setupMagnetic()
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
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        captureSession.stopRunning()
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
    
    @IBAction func continueAction(_ sender: Any) {
        let slideCurrentCenterY = Double(slideView.center.y)
        let viewHeight = Double(view.bounds.height / 2)
        if isCaptured, abs(slideCurrentCenterY - viewHeight) <= 20.0 {
            continueButton.isHidden = true
            oldAngle = ((locationManager.heading!.trueHeading > 0) ?
                locationManager.heading?.trueHeading : locationManager.heading?.magneticHeading)!
            oldDegreeLabel.text = "old: \(oldAngle!)"
            takePicture()
        }
    }
    @IBAction func captureAction(_ sender: UIButton) {
        isCaptured = !isCaptured
        if isCaptured {
            sender.setImage(#imageLiteral(resourceName: "Stop_Camera"), for: .normal)
            oldAngle = ((locationManager.heading!.trueHeading > 0) ?
                locationManager.heading?.trueHeading : locationManager.heading?.magneticHeading)!
            oldDegreeLabel.text = "old: \(oldAngle!)"
            takePicture()
        } else {
            sender.setImage(#imageLiteral(resourceName: "Start_Camera"), for: .normal)
            resetSlideViews()
            numOfPicture = 0
            lineNumber = 0
            progressViews.forEach { (progressView) in
                progressView.progress = 0
            }
        }
    }
}

// MARK: Setup views

extension ViewController {
    
    private func setupViews() {
        continueButton.isHidden = true
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
    
    private func setupMagnetic() {
        locationManager.delegate = self
        //Start heading updating.
        if CLLocationManager.headingAvailable() {
            locationManager.headingFilter = 1
            locationManager.startUpdatingHeading()
        }
    }
}

// MARK: Actions

extension ViewController {
    
    private func takePicture() {
//        let settings = AVCapturePhotoSettings()
//        photoOutput?.capturePhoto(with: settings, delegate: self)
        let greenView = UIView(frame: CGRect(x: (previewCaptureView.bounds.width - greenViewWidth)/2 + greenViewWidth * CGFloat(numOfPicture), y: 0, width: greenViewWidth, height: previewCaptureView.bounds.height))
        greenView.backgroundColor = UIColor.green
        previewCaptureView.addSubview(greenView)
        numOfPicture += 1
        totalPicLabel.text = "\(numOfPicture)"
        if numOfPicture == numOfHorizontalPic, lineNumber == slideCenterYs.count - 1 {
            let alert = UIAlertController.init(title: "Success", message: "Capture completed", preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default, handler: {_ in
                self.captureAction(self.captureButton)
            }))
            self.present(alert, animated: true, completion: nil)
            return
        }
        progressViews[lineNumber].progress = Float(numOfPicture) / Float(numOfHorizontalPic)
        showInfor()
    }
    
    private func resetSlideViews() {
        previewCaptureView.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        slideView.transform = CGAffineTransform.identity
        previewCaptureView.transform = CGAffineTransform.identity
        oldAngle = nil
        oldDegreeLabel.text = "old: nil"
        lastCenter = 0.0
    }
    
    private func showInfor() {
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
        
        print(imageSpecification.toString())
    }
    
    private func saveImageToLibrary(data: Data){
        PHPhotoLibrary.requestAuthorization { (status:PHAuthorizationStatus) in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, data: data, options: nil)
                }, completionHandler: { (success, error) in
                    if let error = error {
                        print("There was an error saving to the photo library: \(error)")
                        return
                    }
                    print("image saved")
                })
            } else {
                print("Need authorisation to write to the photo library")
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

// MARK: CLLocationManagerDelegate

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let heading: CLLocationDirection = ((newHeading.trueHeading > 0) ?
            newHeading.trueHeading : newHeading.magneticHeading)
        var angle = CGFloat(heading)
        degreeLabel.text = "\(angle)"
        if let oldAngle = oldAngle {
            if angle > CGFloat(oldAngle), self.accelZ < 0.7 {
                angle -= 360
            }
            let diff = self.accelZ < 0.7 ? (angle - CGFloat(oldAngle)): -(angle - CGFloat(oldAngle))
            diffDegreeLabel.text = "diff: \(diff / CGFloat(numOfPicture))"
            let centerX = (diff * view.bounds.width / 2) / CGFloat(horizontalDegreeUnit)
            let slideCurrentCenterY = Double(slideView.center.y)
            let viewHeight = Double(view.bounds.height / 2)
            if centerX > 0 {
                self.oldAngle = CLLocationDirection(angle)
                return
            }
            self.previewCaptureView.transform = CGAffineTransform(translationX: centerX, y: 0)
            self.slideView.transform = CGAffineTransform(translationX: centerX, y: 0)
            
            if
                abs(diff) >= CGFloat(horizontalDegreeUnit * Double(numOfPicture)),
                lastCenter - centerX >= greenViewWidth - 10,
                abs(slideCurrentCenterY - viewHeight) <= 10.0 {
                print("take picture",oldAngle,angle,diff,lastCenter, abs(slideCurrentCenterY - viewHeight))
                lastCenter -= greenViewWidth
                takePicture()
                if numOfPicture != 0, numOfPicture % numOfHorizontalPic == 0 {
                    continueButton.isHidden = false
                    lineNumber = min(lineNumber + 1, slideCenterYs.count - 1)
                    numOfPicture = 0
                    resetSlideViews()
                }
            }
        }
    }
}

// MARK: AVCapturePhotoCaptureDelegate

extension ViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(){
            saveImageToLibrary(data: imageData)
        }
    }
    
}


