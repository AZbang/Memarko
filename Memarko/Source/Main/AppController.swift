import UIKit
import SpriteKit
import GameplayKit
import Lottie
import Pastel

class AppController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    private var animationView = AnimationView(name: "AddAnimation")
    private var facesScene = FacesScene()
    private var pastelView = PastelView()
    private var camera = Camera()

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

        animationView.animation = Animation.named("add-button", bundle: Bundle.main)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .playOnce
        animationView.play(completion: { _ in self.animationView.play(fromProgress: 0.9, toProgress: 1, loopMode: .loop) })

        view.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            animationView.widthAnchor.constraint(equalToConstant: 200),
            animationView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.openCamera))
        animationView.addGestureRecognizer(gesture)

        let faces = SKView()
        faces.frame = view.frame
        facesScene.scaleMode = .resizeFill
        faces.presentScene(facesScene)
        faces.ignoresSiblingOrder = true
        faces.allowsTransparency = true
        view.insertSubview(faces, at: 2)
        
        self.camera.onCapture = { (image: UIImage, preview: UIImage) -> Void in
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            let memarko = Memarko(photo: image, preview: preview)
            self.facesScene.addDroplet(memarko: memarko)
        }
    }
    
    @objc func openCamera(_ sender: Any) {
        present(self.camera, animated: true)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
}
