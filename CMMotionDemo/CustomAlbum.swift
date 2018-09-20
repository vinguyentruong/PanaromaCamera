//
//  CustomAlbum.swift
//  CMMotionDemo
//
//  Created by David Nguyen Truong on 9/20/18.
//  Copyright © 2018 David Nguyen Truong. All rights reserved.
//

import Foundation
import Photos

class CustomAlbum {
    
    static let albumName = "PanaromaApp"
    static let shared = CustomAlbum()
    
    var assetCollection: PHAssetCollection!
    
    init() {
        
    }
    
    func createAlbum() {
        func fetchAssetCollectionForAlbum() -> PHAssetCollection! {
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", CustomAlbum.albumName)
            let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
            
            if let firstObject: AnyObject = collection.firstObject {
                return collection.firstObject as! PHAssetCollection
            }
            return nil
        }
        
        if let assetCollection = fetchAssetCollectionForAlbum() {
            self.assetCollection = assetCollection
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: CustomAlbum.albumName)
        }) { success, _ in
            if success {
                self.assetCollection = fetchAssetCollectionForAlbum()
            }
        }
    }
    
    func saveImage(image: UIImage) {
        
        if assetCollection == nil {
            return   // If there was an error upstream, skip the save.
        }
        
        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            let assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection)
            let fastEnumeration = NSArray(array: [assetPlaceholder] as! [PHObjectPlaceholder])
            albumChangeRequest?.addAssets(fastEnumeration)
        }, completionHandler: nil)
    }
    
    func saveVideo(file url: URL,completion: @escaping (URL?,Error?)->()) {
        if assetCollection == nil {
            return   // If there was an error upstream, skip the save.
        }
        var data = Data()
        let newUrl: URL!
        do{
            data = try Data(contentsOf: url)
            let path = url.path.appending(".mov")
            newUrl = URL.init(fileURLWithPath: path)
            try data.write(to: newUrl)
            deleteFileUrl(url)
        }catch{
            print(error.localizedDescription)
            completion(nil,error)
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            let assetchangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: newUrl)
            let assetPlaceholder = assetchangeRequest?.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection)
            let fastEnumeration = NSArray(array: [assetchangeRequest?.placeholderForCreatedAsset] as! [PHObjectPlaceholder])
            albumChangeRequest?.addAssets(fastEnumeration)
        }, completionHandler: { (succes, err) in
            if err != nil {
                print(err?.localizedDescription)
            }
            completion(newUrl,err)
        })
    }
    
    func deleteFileUrl(_ url: URL){
        do {
            try FileManager.default.removeItem(at: url)
        }catch(let err){
            print(err.localizedDescription)
        }
    }
    
}
