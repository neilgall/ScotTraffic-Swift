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
    @IBOutlet var collectionViewLayout: UICollectionViewFlowLayout?
    @IBOutlet var pageControl: UIPageControl?
    @IBOutlet var weatherContainer: UIView?
    
    var receivers = [ReceiverType]()
    
    var viewModel: MapItemCollectionViewModel? {
        willSet {
            disconnectFromModel()
        }
        didSet {
            connectToModel()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let collectionView = collectionView {
            MapItemCollectionViewItemType.registerTypesWith(collectionView)
        }
        
        reload()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        dispatch_async(dispatch_get_main_queue()) {
            self.connectToModel()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        disconnectFromModel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let size = collectionView?.bounds.size {
            collectionViewLayout?.itemSize = size
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embedWeather", let weatherViewController = segue.destinationViewController as? WeatherViewController {
            weatherViewController.weatherViewModel = viewModel?.weatherViewModel
        }
    }
    
    private func connectToModel() {
        if let viewModel = viewModel where isViewLoaded() {
            
            receivers.append(viewModel.cellItems --> { _ in
                self.reload()
            })
            
            receivers.append(viewModel.selectedItemIndex --> { index in
                if let index = index {
                    self.selectItemIndex(index)
                }
            })
        }
    }
    
    private func disconnectFromModel() {
        receivers.removeAll()
    }
    
    private func reload() {
        pageControl?.numberOfPages = viewModel?.cellItems.latestValue.get?.count ?? 0
        collectionView?.dataSource = viewModel
        collectionView?.reloadData()
    }
    
    private func selectItemIndex(index: Int) {
        let indexPath = NSIndexPath(forItem: index, inSection: 0)
        collectionView?.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: false)
        pageControl?.currentPage = index
    }
    
    private func mostVisiblePageIndex() -> Int {
        guard let collectionView = self.collectionView else {
            return 0
        }
        
        let scrollOffset = collectionView.contentOffset.x
        var closestCell: UICollectionViewCell? = nil
        var closestSq = CGFloat.max
        
        for cell in collectionView.visibleCells() {
            let distance = CGRectGetMinX(cell.frame) - scrollOffset
            let distanceSq = distance * distance
            if distanceSq < closestSq {
                closestCell = cell
                closestSq = distanceSq
            }
        }
        
        guard let cell = closestCell else {
            return 0
        }
        return collectionView.indexPathForCell(cell)?.item ?? 0
    }
    
    
    // -- MARK: Actions --
    
    @IBAction func pageControlChanged() {
        guard let currentPage = pageControl?.currentPage else {
            return
        }
        let indexPath = NSIndexPath(forItem: currentPage, inSection: 0)
        collectionView?.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: true)
    }
}

extension MapItemCollectionViewController: UICollectionViewDelegate {
    // -- MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if let item = viewModel?.cellItems.latestValue.get?[indexPath.item] {
            switch item {
            case .TrafficCameraItem(let location, let index):
                analyticsEvent(.ViewTrafficCamera, ["location": location.name, "camera": String(index)])
            case .SafetyCameraItem(let safetyCamera):
                analyticsEvent(.ViewSafetyCamera, ["name": safetyCamera.name])
            case .IncidentItem(let incident):
                analyticsEvent(.ViewIncident, ["road": incident.road])
            case .BridgeStatusItem(let bridgeStatus, _):
                analyticsEvent(.ViewBridgeStatus, ["identifier": bridgeStatus.identifier])
            }
        }
    }
}

extension MapItemCollectionViewController: UIScrollViewDelegate {
    // -- MARK: UIScrollViewDelegate
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        pageControl?.currentPage = mostVisiblePageIndex()
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        pageControl?.currentPage = mostVisiblePageIndex()
    }    
}
