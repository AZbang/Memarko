//
//  MemarkoManager.swift
//  Example
//
//  Created by Andrey Zhevlakov on 29.06.2021.
//

import UIKit
import Foundation
import Alamofire
import TelegramStickersImport
import Emoji

enum Status: String {
    case PROCESSING = "processing";
    case NOT_EXIST = "not_exist";
}

enum MemarkoError: Int {
    case ServerNotRespose = 0
    case ServerTimeout = 1
    case ProcessingError = 2

}

struct SendFondResponse: Decodable {
    let task_id: String
}

struct StickersResponse: Decodable {
    let status: String
    let download_links: [String]?
}

class Memarko {
    private let endpoint = "http://84.201.175.166:8080"
    private var sticketSet = StickerSet(software: "Memarko", isAnimated: true)

    var photo: UIImage
    var loading = false
    var taskId: String?
    var links: [String] = []
    var stickerIndex = 0
    var error: MemarkoError?
    
    var photoProgress: Double = 0
    var processCount: Int = 0
    var stickersProgress: Double = 0
    
    var progress: Int {
        get {
            let step1 = Double(20 * photoProgress)
            let step2 = Double(min(60, Double(processCount) / 25 * 60))
            let total = step1 + step2
            return min(Int(total + (100 - total) * stickersProgress), 100)
        }
    }

    init(photo: UIImage, preview: UIImage) {
        self.photo = preview
        self.sendPhoto(image: photo.jpegData(compressionQuality: 0.9)!)
    }
    
    private func sendPhoto(image: Data) {
        self.loading = true
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(image, withName: "photo", fileName: "photo.jpg", mimeType: "image/jpeg")
        }, to: self.endpoint + "/send_photo")
            .uploadProgress { progress in
                self.photoProgress = progress.fractionCompleted
            }
            .responseDecodable(of: SendFondResponse.self) { response in
                self.loading = false
                if let taskId = response.value?.task_id {
                    self.taskId = taskId
                    self.loadStickers(id: taskId)
                }
            }
    }
    
    private func loadStickers(id: String) {
        AF.request(self.endpoint + "/get_stickers/" + id).responseDecodable(of: StickersResponse.self) { response in
            guard let status = response.value?.status else {
                self.error = .ServerNotRespose
                return
            }
        
            self.processCount += 1
            if (self.processCount > 60) {
                self.error = .ServerTimeout
                return
            }
            
            if (status == "error") {
                self.error = .ProcessingError
                return
            }

            if (status == "processing") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.loadStickers(id: id)
                }
            }
            
            if (status == "done") {
                guard let download_links = response.value?.download_links else { return }
                self.links = download_links;
                self.stickerIndex = 0;
                self.loadStickerData()
            }
        }
    }
    
    
    private func loadStickerData() {
        if (self.stickerIndex >= self.links.count) {
            try? self.sticketSet.import()
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            return
        }
        
        let stickerUrl = self.links[self.stickerIndex];
        let part = 100 / Double(self.links.count)
        let prev = self.stickersProgress
    
        AF.download(stickerUrl)
            .downloadProgress { progress in
                self.stickersProgress = prev + progress.fractionCompleted * part
            }
            .responseData { response in
                if let data = response.value {
                    let name = URL(fileURLWithPath: stickerUrl).deletingPathExtension().lastPathComponent
                    let keys = name.components(separatedBy: "~")[2...]
                    let emojis = keys.map { (emoji) -> String in ":\(emoji):".emojiUnescapedString }

                    try? self.sticketSet.addSticker(data: .animation(data), emojis: emojis)
                    self.stickerIndex += 1
                    self.loadStickerData()
                }
        }
    }
}
