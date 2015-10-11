//
//  MapItemCollectionViewController.swift
//  ScotTraffic
//
//  Created by ZBS on 11/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

class MapItemCollectionViewController: UIViewController {

    @IBOutlet var collectionView: UICollectionView?
    @IBOutlet var pageControl: UIPageControl?
    var viewModel = MapItemCollectionViewModel(mapItems: []) {
        didSet {
            reload()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    private func reload() {
        
    }
}
