import UIKit
import SpriteKit
import GameplayKit
import Lottie
import Pastel

class AppController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    private var image = UIImageView(image: UIImage(named: "s-1.png"));
    private var animationView = AnimationView(name: "StarAnimation")
    private var facesScene = FacesScene()
    private var pastelView = PastelView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let title = UILabel(frame: CGRect(x: 0, y: 80, width: view.frame.size.width, height: 50))
        title.translatesAutoresizingMaskIntoConstraints = false
        title.textAlignment = .center
        title.addCharactersSpacing(spacing: -5, text: "memarko.")
        title.font = UIFont(name: "Futura", size: 60)
        self.view.addSubview(title)
    
        pastelView.frame = view.bounds
        pastelView.translatesAutoresizingMaskIntoConstraints = false
        pastelView.startPastelPoint = .bottomLeft
        pastelView.endPastelPoint = .topRight
        pastelView.animationDuration = 1.0
        pastelView.setColors([UIColor(red: 156/255, green: 39/255, blue: 176/255, alpha: 1.0),
                                UIColor(red: 255/255, green: 64/255, blue: 129/255, alpha: 1.0),
                                UIColor(red: 123/255, green: 31/255, blue: 162/255, alpha: 1.0),
                                UIColor(red: 32/255, green: 76/255, blue: 255/255, alpha: 1.0),
                                UIColor(red: 32/255, green: 158/255, blue: 255/255, alpha: 1.0),
                                UIColor(red: 90/255, green: 120/255, blue: 127/255, alpha: 1.0),
                                UIColor(red: 58/255, green: 255/255, blue: 217/255, alpha: 1.0)])
        pastelView.startAnimation()
        pastelView.mask = title
        view.insertSubview(pastelView, at: 0);
        
        let bg = PastelView()
        bg.frame = view.bounds
        bg.startPastelPoint = .topLeft
        bg.endPastelPoint = .bottomRight
        bg.animationDuration = 10.0
        bg.setColors([#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)])
        bg.startAnimation()
        view.insertSubview(bg, at: 0)

        image.translatesAutoresizingMaskIntoConstraints = false
        image.layer.masksToBounds = true
        image.layer.borderColor = #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1);
        image.layer.borderWidth = 10
        image.layer.cornerRadius = 20;
        image.isHidden = true
        view.addSubview(image)
        NSLayoutConstraint.activate([
            image.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            image.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            image.widthAnchor.constraint(equalToConstant: 200),
            image.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.animation = Animation.named("selfie-phone")
        animationView.contentMode = .scaleAspectFit
        animationView.play()
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.loopMode = .playOnce
        view.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            animationView.widthAnchor.constraint(equalToConstant: 200),
            animationView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.openCamera))
        animationView.addGestureRecognizer(gesture)
        
        let importSticksTap = UITapGestureRecognizer(target: self, action: #selector(self.importPack))
        pastelView.addGestureRecognizer(importSticksTap)

        
        let faces = SKView()
        faces.frame = view.frame
        facesScene.scaleMode = .resizeFill
        faces.presentScene(facesScene)
        faces.ignoresSiblingOrder = true
        faces.allowsTransparency = true
        view.insertSubview(faces, at: 2)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        pastelView.animationDuration = 1.0
        pastelView.startAnimation()
        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }
        
        self.facesScene.addDroplet(image: image)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        
        if let data = image.jpegData(compressionQuality: 0.9) {
            let memarko = Memarko(image: data)
            //self.facesScene.addDroplet(image: image)
            //print(memarko)
        }
    
        //self.animationView.isHidden = true
    }
    
    @objc func importPack() {
    }
    
    @objc func openCamera(_ sender: Any) {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.allowsEditing = true
        vc.cameraCaptureMode = .photo
        vc.cameraDevice = .front
        vc.delegate = self
        present(vc, animated: true)
    }
    
    func send(_ sender: Any) {
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
}
