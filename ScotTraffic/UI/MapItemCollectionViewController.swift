//
//  MapItemCollectionViewController.swift
//  ScotTraffic
//
//  Created by ZBS on 11/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public class MapItemCollectionViewController: UIViewController, UICollectionViewDelegate, MapItemCollectionViewModelDelegate {

    @IBOutlet var collectionView: UICollectionView?
    @IBOutlet var collectionViewLayout: UICollectionViewFlowLayout?
    @IBOutlet var pageControl: UIPageControl?
    
    var viewModel: MapItemCollectionViewModel? {
        willSet {
            if let oldModel = viewModel {
                oldModel.delegate = nil
            }
        }
        didSet {
            viewModel?.delegate = self
            reload()
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        if let collectionView = collectionView {
            MapItemCollectionViewCell.registerTypesWith(collectionView)
        }
        
        reload()
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionViewLayout?.itemSize = collectionView?.bounds.size ?? CGSizeZero
    }
    
    private func reload() {
        collectionView?.dataSource = viewModel
        pageControl?.numberOfPages = viewModel?.cellItems.count ?? 0
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
    
    // -- MARK: MapItemCollectionViewModelDelegate --
    
    public func mapItemCollectionViewModel(model: MapItemCollectionViewModel, didRequestShareItem item: SharableItem) {
        
    }
    
    public func mapItemCollectionViewModel(model: MapItemCollectionViewModel, didToggleFavouriteItem item: FavouriteTrafficCamera) {
        
    }
}
