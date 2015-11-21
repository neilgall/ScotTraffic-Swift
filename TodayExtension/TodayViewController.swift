//
//  TodayViewController.swift
//  TodayExtension
//
//  Created by Neil Gall on 21/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit
import NotificationCenter

private let maxImageWidth:  CGFloat = 414
private let bottomMargin:   CGFloat = 10
private let controlsHeight: CGFloat = 44

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet var imageView: UIImageView?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var controls: UIView?
    @IBOutlet var errorLabel: UILabel?
    @IBOutlet var leftButton: UIButton?
    @IBOutlet var rightButton: UIButton?
    
    let model = TodayViewModel()
    var observations: [Observation] = []
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        errorLabel?.hidden = true
        
        observations.append(model.image => {
            self.imageView?.image = $0
        })
        observations.append(model.showError => {
            self.errorLabel?.hidden = !$0
        })
        observations.append(model.title => {
            self.titleLabel?.text = $0
        })
        observations.append(model.canMoveToPrevious => {
            self.leftButton?.enabled = $0
        })
        observations.append(model.canMoveToNext => {
            self.rightButton?.enabled = $0
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        observations.removeAll()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let width = self.view.frame.width
        imageView?.frame = imageViewFrameForWidth(width)
        controls?.frame = controlsFrameForWidth(width)
        view.frame = viewFrameForWidth(width)
        
        self.preferredContentSize = view.frame.size
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        model.refresh()
        completionHandler(NCUpdateResult.NewData)
    }
    
    @IBAction func leftButtonTapped() {
        model.moveToPreviousImage()
    }
    
    @IBAction func rightButtonTapped() {
        model.moveToNextImage()
    }
    
    
    private func imageViewFrameForWidth(width: CGFloat) -> CGRect {
        let imageWidth = min(maxImageWidth, width)
        let imageHeight = floor(imageWidth * 0.75)
        let imageX = floor(width - imageWidth) / 2
        return CGRect(
            origin: CGPoint(x: imageX, y: 0),
            size: CGSize(width: imageWidth, height: imageHeight))
    }
    
    private func controlsFrameForWidth(width: CGFloat) -> CGRect {
        let imageFrame = imageViewFrameForWidth(width)
        return CGRect(
            origin: CGPoint(x: imageFrame.minX, y: imageFrame.maxY),
            size: CGSize(width: imageFrame.width, height: controlsHeight))
    }
    
    private func viewFrameForWidth(width: CGFloat) -> CGRect {
        let imageFrame = imageViewFrameForWidth(width)
        let controlsFrame = controlsFrameForWidth(width)
        return CGRect(
            origin: CGPointZero,
            size: CGSize(width: width, height: imageFrame.height + controlsFrame.height))
    }
}
