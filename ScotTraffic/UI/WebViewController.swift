//
//  WebViewController.swift
//  ScotTraffic
//
//  Created by Neil Gall on 02/12/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

class WebViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet var webView: UIWebView?

    var url: NSURL? {
        didSet {
            reload()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        reload()
    }
    
    func reload() {
        if let url = url {
            let urlRequest = NSURLRequest(URL: url)
            webView?.loadRequest(urlRequest)
        }
    }

}
