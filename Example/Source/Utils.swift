import Foundation
import UIKit

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}

extension UIImage {
    var isPortrait:  Bool    { return size.height > size.width }
    var isLandscape: Bool    { return size.width > size.height }
    var breadth:     CGFloat { return min(size.width, size.height) }
    var breadthSize: CGSize  { return CGSize(width: breadth, height: breadth) }
    var breadthRect: CGRect  { return CGRect(origin: .zero, size: breadthSize) }
    
    func getCgImage() -> CGImage? {
        if (cgImage != nil) { return cgImage }
        return convertCIImageToCGImage(inputImage: ciImage!)
    }
    
    func circleMasked() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(breadthSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let cgImage = cgImage ?? convertCIImageToCGImage(inputImage: ciImage!) else {
            return nil
        }
    
        cgImage.cropping(to: CGRect(origin:
            CGPoint(
                x: isLandscape ? floor((size.width - size.height) / 2) : 0,
                y: isPortrait  ? floor((size.height - size.width) / 2) : 0),
            size: breadthSize))
        
        UIBezierPath(ovalIn: breadthRect).addClip()
        UIImage(cgImage: cgImage, scale: 1, orientation: imageOrientation).draw(in: breadthRect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

func convertCIImageToCGImage(inputImage: CIImage) -> CGImage? {
    let context = CIContext(options: nil)
    if let cgImage = context.createCGImage(inputImage, from: inputImage.extent) {
        return cgImage
    }
    return nil
}

extension UILabel {
    func addCharactersSpacing(spacing:CGFloat, text:String) {
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(NSAttributedString.Key.kern, value: spacing, range: NSMakeRange(0, text.count))
        self.attributedText = attributedString
    }
}

func smartCrop(image: CGImage, crop: CGRect) -> UIImage? {
    let cx = max(crop.minX, 0)
    let cy = max(crop.minY, 0)
    let cw = min(crop.width, CGFloat(image.width))
    let ch = min(crop.height, CGFloat(image.height))
    print(crop, CGRect(x: cx, y: cy, width: cw, height: ch))
    let cropped = UIImage(cgImage: (image.cropping(to: CGRect(x: cx, y: cy, width: cw, height: ch)))!)
    
    let x = (crop.width - cropped.size.width) / 2
    let y = (crop.height - cropped.size.height) / 2

    // Actually do the resizing to the rect using the ImageContext stuff
    UIGraphicsBeginImageContextWithOptions(CGSize(width: crop.width, height: crop.height), true, 1.0)
    cropped.draw(in: CGRect(x: x, y: y, width: cropped.size.width, height: cropped.size.height))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    UIGraphicsBeginImageContextWithOptions(CGSize(width: 512, height: 512), false, 1.0)
    newImage!.draw(in: CGRect(x: 0, y: 0, width: 512, height: 512))
    let resized = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return resized
}

func dataSize(_ data: Data) {
      print("There were \(data.count) bytes")
      let bcf = ByteCountFormatter()
      bcf.allowedUnits = [.useMB] // optional: restricts the units to MB only
      bcf.countStyle = .file
      let string = bcf.string(fromByteCount: Int64(data.count))
      print("formatted result: \(string)")
}
