//
//  MapItemCollectionViewController.swift
//  ScotTraffic
//
//  Created by ZBS on 11/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public class MapItemCollectionViewController: UIViewController, UICollectionViewDelegate {

    @IBOutlet var collectionView: UICollectionView?
    @IBOutlet var collectionViewLayout: UICollectionViewFlowLayout?
    @IBOutlet var pageControl: UIPageControl?
    @IBOutlet var weatherContainer: UIView?
    
    var observations = [Observation]()
    
    var viewModel: MapItemCollectionViewModel? {
        willSet {
            disconnectFromModel()
        }
        didSet {
            connectToModel()
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        if let collectionView = collectionView {
            MapItemCollectionViewCell.registerTypesWith(collectionView)
        }
        
        reload()
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        dispatch_async(dispatch_get_main_queue()) {
            self.connectToModel()
        }
    }
    
    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        disconnectFromModel()
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let size = collectionView?.bounds.size {
            collectionViewLayout?.itemSize = size
        }
    }
    
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embedWeather", let weatherViewController = segue.destinationViewController as? WeatherViewController {
            weatherViewController.weatherViewModel = viewModel?.weatherViewModel
        }
    }
    
    private func connectToModel() {
        if let viewModel = viewModel where isViewLoaded() {
            
            observations.append(viewModel.cellItems => { _ in
                self.reload()
            })
            
            observations.append(viewModel.selectedItemIndex => { index in
                if let index = index {
                    self.selectItemIndex(index)
                }
            })
        }
    }
    
    private func disconnectFromModel() {
        observations.removeAll()
    }
    
    private func reload() {
        pageControl?.numberOfPages = viewModel?.cellItems.pullValue?.count ?? 0
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
    
    // -- MARK: UIScrollViewDelegate --
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        pageControl?.currentPage = mostVisiblePageIndex()
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        pageControl?.currentPage = mostVisiblePageIndex()
    }    
}
