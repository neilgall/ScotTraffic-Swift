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
    @IBOutlet var spinner: UIActivityIndicatorView?
    
    var loadFromWeb: Bool = false

    var page: String? {
        didSet {
            if isViewLoaded() {
                reload()
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        reload()
    }
    
    func reload() {
        var url: NSURL? = nil
        if loadFromWeb, let page = page {
            url = NSURL(string: "support/\(page).html", relativeToURL: ScotTrafficBaseURL)
        } else {
            if let path = NSBundle.mainBundle().pathForResource(page, ofType: "html", inDirectory: "www") {
                url = NSURL(fileURLWithPath: path)
            }
        }
        if let url = url {
            let urlRequest = NSURLRequest(URL: url)
            webView?.loadRequest(urlRequest)
            spinner?.startAnimating()
        } else {
            spinner?.stopAnimating()
        }
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        spinner?.stopAnimating()
    }

    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        if loadFromWeb {
            loadFromWeb = false
            reload()
        }
    }
}
