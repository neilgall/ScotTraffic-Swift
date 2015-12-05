//
//  ImageDataSource.swift
//  ScotTraffic
//
//  Created by ZBS on 14/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public enum ImageError: ErrorType {
    case CannotDecode
}

public protocol ImageDataSource {
    var dataSource: DataSource { get }
}

public typealias DataSourceImage = DataSourceValue<UIImage>

extension ImageDataSource {

    var imageValue: Observable<DataSourceImage> {
        return dataSource.value.map({
            $0.map({ (data: NSData) throws -> UIImage in
                if let image = UIImage(data: data) {
                    return image
                } else {
                    throw ImageError.CannotDecode
                }
            })
        })
    }
    
    var image: Observable<UIImage?> {
        return imageValue.map({
            switch $0 {
            case .Cached(let image, _):
                return image
            case .Fresh(let image):
                return image
            case .Error, .Empty:
                return nil
            }
        })
    }
    
    func updateImage() {
        dataSource.start()
    }
}
