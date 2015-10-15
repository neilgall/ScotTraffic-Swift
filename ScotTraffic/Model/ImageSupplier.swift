//
//  ImageSupplier.swift
//  ScotTraffic
//
//  Created by ZBS on 14/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

protocol ImageSupplier {
    var imageName: String? { get }
}

extension ImageSupplier {

    func image(fetcher: HTTPFetcher) -> Observable<UIImage?> {
        guard let imageName = imageName else {
            return Never()
        }
        
        let dataSource = HTTPDataSource(fetcher: fetcher, path: imageName)
        let imageOrError = dataSource.map { (dataOrError: Either<NSData,NetworkError>) -> UIImage? in
            switch dataOrError {
            case .Value(let data):
                return UIImage(data: data)
            case .Error:
                return nil
            }
        }
        
        dataSource.start()
        return imageOrError
    }
}
