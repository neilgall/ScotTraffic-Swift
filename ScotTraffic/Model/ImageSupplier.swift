//
//  ImageSupplier.swift
//  ScotTraffic
//
//  Created by ZBS on 14/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public protocol ImageSupplier {
    var dataSource: DataSource? { get }
}

extension ImageSupplier {

    var image: Observable<UIImage?> {
        guard let dataSource = dataSource else {
            return Const(value: nil)
        }
        
        let imageOrError = dataSource.value.map { (dataOrError: Either<NSData,NetworkError>) -> UIImage? in
            switch dataOrError {
            case .Value(let data):
                return UIImage(data: data)
            case .Error:
                return nil
            }
        }
        
        return imageOrError
    }
    
    func updateImage() {
        dataSource?.start()
    }
}
