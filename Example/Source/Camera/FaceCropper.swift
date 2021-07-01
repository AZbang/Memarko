
import UIKit
import Vision

public enum FaceCropResult<T> {
  case success([T])
  case notFound
  case failure(Error)
}

public struct FaceCropper<T> {
  let detectable: T
  init(_ detectable: T) {
    self.detectable = detectable
  }
}

public protocol FaceCroppable {
}

public extension FaceCroppable {
  var face: FaceCropper<Self> {
    return FaceCropper(self)
  }
}

public extension FaceCropper where T: CGImage {
  
  func crop(_ completion: @escaping (FaceCropResult<CGImage>) -> Void) {
    
    guard #available(iOS 11.0, *) else {
      return
    }
    
    let req = VNDetectFaceRectanglesRequest { request, error in
      guard error == nil else {
        completion(.failure(error!))
        return
      }
      
      let faceImages = request.results?.map({ result -> CGImage? in
        guard let face = result as? VNFaceObservation else { return nil }
        
        let width = face.boundingBox.width * CGFloat(self.detectable.width)
        let height = face.boundingBox.height * CGFloat(self.detectable.height)
        let x = face.boundingBox.origin.x * CGFloat(self.detectable.width)
        let y = (1 - face.boundingBox.origin.y) * CGFloat(self.detectable.height) - height
        let pad: CGFloat = max(width, height) * 0.5

        let croppingRect = CGRect(x: x - pad, y: y - pad*1.5, width: width + pad*2, height: height + pad*2)
        let image = smartCrop(image: self.detectable, crop: croppingRect)
        
        return image?.cgImage
      }).compactMap { $0 }
      
      guard let result = faceImages, result.count > 0 else {
        completion(.notFound)
        return
      }
      
      completion(.success(result))
    }
    
    do {
      try VNImageRequestHandler(cgImage: self.detectable, options: [:]).perform([req])
    } catch let error {
      completion(.failure(error))
    }
  }
}

public extension FaceCropper where T: UIImage {
  
  func crop(_ completion: @escaping (FaceCropResult<UIImage>) -> Void) {
    guard #available(iOS 11.0, *) else {
      return
    }
    
    guard let cgImage = self.detectable.getCgImage() else {
        completion(.notFound)
        return
    }
    
    cgImage.face.crop { result in
      switch result {
      case .success(let cgFaces):
        let faces = cgFaces.map { cgFace -> UIImage in
          return UIImage(cgImage: cgFace)
        }
        completion(.success(faces))
      case .notFound:
        completion(.notFound)
      case .failure(let error):
        completion(.failure(error))
      }
    }
    
  }
  
}

extension NSObject: FaceCroppable {}
extension CGImage: FaceCroppable {}
