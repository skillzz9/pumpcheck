import SwiftUI

class ImageCache {
    static let shared = NSCache<NSString, UIImage>()
    
    static func decode(base64: String) -> UIImage? {
        if base64.isEmpty { return nil }
        
        let key = base64 as NSString
        if let cached = shared.object(forKey: key) {
            return cached
        }
        
        if let data = Data(base64Encoded: base64), let img = UIImage(data: data) {
            shared.setObject(img, forKey: key)
            return img
        }
        return nil
    }
}
