
import UIKit
import AVFoundation
import Vision

class Camera: UIViewController {
    //MARK:- Vars
    var captureSession: AVCaptureSession!
    
    var backCamera: AVCaptureDevice!
    var frontCamera: AVCaptureDevice!
    var backInput: AVCaptureInput!
    var frontInput: AVCaptureInput!
    
    var previewLayer: AVCaptureVideoPreviewLayer!
    var videoOutput: AVCaptureVideoDataOutput!
    
    var sequenceHandler = VNSequenceRequestHandler()
    var faceBox: CGRect?
    
    var takePicture = false
    var backCameraOn = false
    var isDetectFace = false {
        didSet {
            DispatchQueue.main.async {
                self.captureImageButton.alpha = self.isDetectFace ? 1 : 0.4
                self.captureImageButton.setTitle(self.isDetectFace ? "LET'S GO 🔥" : "SHOW ME 👤", for: .normal)

            }
        }
    }
    
    var onCapture: ((_ image: UIImage, _ preview: UIImage) -> Void)?
    
    //MARK:- View Components
    let switchCameraButton: UIButton = {
        let button = UIButton()
        let image = UIImage(named: "switchcamera")?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let captureImageButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.tintColor = .white
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("SHOW ME 👤", for: .normal)
        button.setTitleColor(#colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1), for: .normal)
        button.titleLabel?.font = UIFont(name: "Futura", size: 20)
        return button
    }()
    
    let openPhotoLibraryButton: UIButton = {
        let button = UIButton()
        let image = UIImage(named: "gallery")?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
        
    //MARK:- Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    var isInit = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (isInit) { return }
        
        checkPermissions()
        setupAndStartCaptureSession()
        isInit = true
    }
    
    //MARK:- Camera Setup
    func setupAndStartCaptureSession(){
        DispatchQueue.global(qos: .userInitiated).async{
            //init session
            self.captureSession = AVCaptureSession()
            self.captureSession.beginConfiguration()
            if self.captureSession.canSetSessionPreset(.photo) {
                self.captureSession.sessionPreset = .photo
            }

            self.captureSession.automaticallyConfiguresCaptureDeviceForWideColor = true
            self.setupInputs()
            
            DispatchQueue.main.async {
                self.setupPreviewLayer()
            }
            
            //setup output
            self.setupOutput()
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
        }
    }
    
    func setupInputs(){
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            backCamera = device
        } else {
            //handle this appropriately for production purposes
            fatalError("no back camera")
        }
        
        //get front camera
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            frontCamera = device
        } else {
            fatalError("no front camera")
        }
        
        //now we need to create an input objects from our devices
        guard let bInput = try? AVCaptureDeviceInput(device: backCamera) else {
            fatalError("could not create input device from back camera")
        }
        backInput = bInput
        if !captureSession.canAddInput(backInput) {
            fatalError("could not add back camera input to capture session")
        }
        
        guard let fInput = try? AVCaptureDeviceInput(device: frontCamera) else {
            fatalError("could not create input device from front camera")
        }
        frontInput = fInput
        if !captureSession.canAddInput(frontInput) {
            fatalError("could not add front camera input to capture session")
        }
        
        //connect back camera input to session
        captureSession.addInput(frontInput)
    }
    
    func setupOutput(){
        videoOutput = AVCaptureVideoDataOutput()
        let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            fatalError("could not add video output")
        }
        
        videoOutput.connections.first?.videoOrientation = .portrait
    }
    
    func setupPreviewLayer(){
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.insertSublayer(previewLayer, below: switchCameraButton.layer)
        previewLayer.frame = self.view.layer.frame
    }
    
    func switchCameraInput(){
        //don't let user spam the button, fun for the user, not fun for performance
        switchCameraButton.isUserInteractionEnabled = false
        
        //reconfigure the input
        captureSession.beginConfiguration()
        if backCameraOn {
            captureSession.removeInput(backInput)
            captureSession.addInput(frontInput)
            backCameraOn = false
        } else {
            captureSession.removeInput(frontInput)
            captureSession.addInput(backInput)
            backCameraOn = true
        }
        
        //deal with the connection again for portrait mode
        videoOutput.connections.first?.videoOrientation = .portrait
        videoOutput.connections.first?.isVideoMirrored = !backCameraOn
        captureSession.commitConfiguration()
        
        //acitvate the camera button again
        switchCameraButton.isUserInteractionEnabled = true
    }
    
    //MARK:- Actions
    @objc func captureImage(_ sender: UIButton?){
        takePicture = self.isDetectFace
    }
    
    @objc func switchCamera(_ sender: UIButton?){
        switchCameraInput()
    }
    
    @objc func openPhoto(_ sender: UIButton?){
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        present(vc, animated: true)
    }
}

extension Camera: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }
        self.pushPhoto(image: image, {
            picker.dismiss(animated: true)
            self.dismiss(animated: true, completion: nil)
        })
    }
}


extension Camera: AVCaptureVideoDataOutputSampleBufferDelegate {
    //MARK:- View Setup
    func setupView(){
        view.backgroundColor = .black
        view.addSubview(switchCameraButton)
        view.addSubview(captureImageButton)
        view.addSubview(openPhotoLibraryButton)

        NSLayoutConstraint.activate([
            openPhotoLibraryButton.widthAnchor.constraint(equalToConstant: 30),
            openPhotoLibraryButton.heightAnchor.constraint(equalToConstant: 30),
            openPhotoLibraryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            openPhotoLibraryButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 40),
            
            switchCameraButton.widthAnchor.constraint(equalToConstant: 30),
            switchCameraButton.heightAnchor.constraint(equalToConstant: 30),
            switchCameraButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            switchCameraButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -40),
           
            captureImageButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            captureImageButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            captureImageButton.widthAnchor.constraint(equalToConstant: 150),
            captureImageButton.heightAnchor.constraint(equalToConstant: 50),
        ])
       
        switchCameraButton.addTarget(self, action: #selector(switchCamera(_:)), for: .touchUpInside)
        captureImageButton.addTarget(self, action: #selector(captureImage(_:)), for: .touchUpInside)
        openPhotoLibraryButton.addTarget(self, action: #selector(openPhoto(_:)), for: .touchUpInside)
    }
    
    //MARK:- Permissions
    func checkPermissions() {
        let cameraAuthStatus =  AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch cameraAuthStatus {
          case .authorized:
            return
          case .denied:
            abort()
          case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:
            { (authorized) in
              if(!authorized){
                abort()
              }
            })
          case .restricted:
            abort()
          @unknown default:
            fatalError()
        }
    }
    
    func convert(rect: CGRect) -> CGRect {
        let origin = previewLayer.layerPointConverted(fromCaptureDevicePoint: rect.origin)
        let size = previewLayer.layerPointConverted(fromCaptureDevicePoint: CGPoint(x: rect.size.width, y: rect.size.height))
        return CGRect(origin: origin, size: CGSize(width: size.x, height: size.y))
    }

    func detectedFace(request: VNRequest, error: Error?) {
      guard
        let results = request.results as? [VNFaceObservation],
        let result = results.first
        else {
            self.isDetectFace = false
            return
      }
    
        self.isDetectFace = true
        self.faceBox = convert(rect: result.boundingBox)
    }
    
    func pushPhoto(image: UIImage, _ onComplete: (() -> Void)?) {
        self.takePicture = false
        image.face.crop { result in
            switch result {
                case .success(let faces):
                    DispatchQueue.main.async {
                        if (self.onCapture != nil && faces.first != nil) {
                            self.onCapture!(image, faces.first!)
                            self.dismiss(animated: true, completion: nil)
                            if (onComplete != nil) { onComplete!() }
                        }
                    }
    
            case .notFound:
                self.isDetectFace = false
                
            case .failure(_):
                self.isDetectFace = false
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //try and get a CVImageBuffer out of the sample buffer
        guard let cvBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let detectFaceRequest = VNDetectFaceRectanglesRequest(completionHandler: detectedFace)
        try? sequenceHandler.perform([detectFaceRequest], on: cvBuffer, orientation: .leftMirrored)
        
        if !takePicture {
            return //we have nothing to do with the image buffer
        }
        
        //get a CIImage out of the CVImageBuffer
        let ciImage = CIImage(cvImageBuffer: cvBuffer)
        self.pushPhoto(image: UIImage(ciImage: ciImage), nil)
    }
}
