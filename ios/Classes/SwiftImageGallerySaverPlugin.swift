import Flutter
import UIKit
import Photos

public class SwiftImageGallerySaverPlugin: NSObject, FlutterPlugin {
    var result: FlutterResult?;
    var localId:String = "";

    public static func register(with registrar: FlutterPluginRegistrar) {
      let channel = FlutterMethodChannel(name: "image_gallery_saver", binaryMessenger: registrar.messenger())
      let instance = SwiftImageGallerySaverPlugin()
      registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      self.result = result
      if call.method == "saveImageToGallery" {
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()
        guard let imageData = (arguments["imageBytes"] as? FlutterStandardTypedData)?.data,
            let image = UIImage(data: imageData),
            let quality = arguments["quality"] as? Int ,
            let name = arguments["name"]
            else { return }
        let newImage = image.jpegData(compressionQuality: CGFloat(quality / 100))!
        saveImageInAlbum(image: image)
//        UIImageWriteToSavedPhotosAlbum(UIImage(data: newImage) ?? image , self, #selector(didFinishSavingImage(image:error:contextInfo:)), nil)
      } else if (call.method == "saveFileToGallery") {
        guard let path = call.arguments as? String else { return }
        if (isImageFile(filename: path)) {
            if let image = UIImage(contentsOfFile: path) {
                saveImageInAlbum(image: image)
//                 UIImageWriteToSavedPhotosAlbum(image, self, #selector(didFinishSavingImage(image:error:contextInfo:)), nil)
            }
        } else {
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)) {
                UISaveVideoAtPathToSavedPhotosAlbum(path, self, #selector(didFinishSavingVideo(videoPath:error:contextInfo:)), nil)
            }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    /// finish saving，if has error，parameters error will not nill
    @objc func didFinishSavingImage(image: UIImage, error: NSError?, contextInfo: UnsafeMutableRawPointer?) {
        result?(error == nil)
    }
    
    @objc func didFinishSavingVideo(videoPath: String, error: NSError?, contextInfo: UnsafeMutableRawPointer?) {
        result?(error == nil)
    }
    
    func isImageFile(filename: String) -> Bool {
        return filename.hasSuffix(".jpg")
            || filename.hasSuffix(".png")
            || filename.hasSuffix(".JPEG")
            || filename.hasSuffix(".JPG")
            || filename.hasSuffix(".PNG")
    }
    
    func isAuthored()->Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized || PHPhotoLibrary.authorizationStatus() == .notDetermined
    }
    
    
    func saveVideoInAlbum(path:String){
        if !isAuthored() {
            result?(nil)
            return
        }
        PHPhotoLibrary.shared().performChanges({
            let result = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: path))
            let assetPlaceholder = result?.placeholderForCreatedAsset
            self.localId = assetPlaceholder?.localIdentifier as! String
        }){(isSuccess:Bool,error:Error?) in
            if isSuccess {
                print("save picture ok;")
                let assetResult = PHAsset.fetchAssets(withLocalIdentifiers: [self.localId], options: nil)
                let asset = assetResult[0]
                let options = PHContentEditingInputRequestOptions()
                options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData)
                    -> Bool in
                    return true
                }
                //获取保存视频的路径
                asset.requestContentEditingInput(with: options, completionHandler: {
                    (contentEditingInput:PHContentEditingInput?, info: [AnyHashable : Any]) in
                    print("地址：",contentEditingInput!.fullSizeImageURL!)
                    self.result?(contentEditingInput!.fullSizeImageURL!)
                })
                
            }else{
                print("save failed;")
            }
        }
    }
    
    
    func saveImageInAlbum(image:UIImage) {
        if !isAuthored() {
            result?(nil)
            return
        }
        PHPhotoLibrary.shared().performChanges({
            let result = PHAssetChangeRequest.creationRequestForAsset(from: image)
            let assetPlaceholder = result.placeholderForCreatedAsset
            self.localId = assetPlaceholder?.localIdentifier as! String
            print(self.localId)
        }){(isSuccess:Bool,error:Error?) in
            if isSuccess {
                print("save picture ok;")
                let assetResult = PHAsset.fetchAssets(withLocalIdentifiers: [self.localId], options: nil)
                let asset = assetResult[0]
                let options = PHContentEditingInputRequestOptions()
                options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData)
                    -> Bool in
                    return true
                }
                //获取保存的图片路径
                asset.requestContentEditingInput(with: options, completionHandler: {
                    (contentEditingInput:PHContentEditingInput?, info: [AnyHashable : Any]) in
                    print("地址：",contentEditingInput!.fullSizeImageURL!)
                    self.result?(contentEditingInput!.fullSizeImageURL!.absoluteString)
                })
                
            }else{
                print("save failed;")
            }
        }
    }
    
}
