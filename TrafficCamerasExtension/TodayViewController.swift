//
//  TodayViewController.swift
//  TodayExtension
//
//  Created by Neil Gall on 21/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var temperatureLabel: UILabel!
    @IBOutlet var weatherIconImageView: UIImageView!
    @IBOutlet var errorLabel: UILabel!
    @IBOutlet var leftButton: UIButton!
    @IBOutlet var rightButton: UIButton!
    @IBOutlet var mainStackView: UIStackView!
    @IBOutlet var infoStackView: UIStackView!
    
    let model = TodayViewModel()
    var receivers: [ReceiverType] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOSApplicationExtension 10.0, *) {
            extensionContext?.widgetLargestAvailableDisplayMode = .Expanded
            titleLabel.textColor = .blackColor()
            temperatureLabel.textColor = .blackColor()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        errorLabel?.hidden = true
        
        receivers.append(model.image --> {
            self.imageView?.image = $0
        })
        receivers.append(model.showError --> {
            self.errorLabel?.hidden = !$0
        })
        receivers.append(model.title --> {
            self.titleLabel?.text = $0
        })
        receivers.append(model.canMoveToPrevious --> {
            self.leftButton?.hidden = !$0
        })
        receivers.append(model.canMoveToNext --> {
            self.rightButton?.hidden = !$0
        })
        receivers.append(model.weatherViewModel.weatherHidden --> {
            self.temperatureLabel?.hidden = $0
            self.weatherIconImageView?.hidden = $0
        })
        receivers.append(model.weatherViewModel.temperatureText --> {
            self.temperatureLabel?.text = $0
        })
        receivers.append(model.weatherViewModel.weatherIconName --> {
            self.weatherIconImageView?.image = UIImage(named: $0)
        })
        
        model.refresh({ _ in })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        receivers.removeAll()
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        model.refresh(completionHandler)
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        switch activeDisplayMode {
        case .Expanded:
            layoutForExpandedDisplayMode(maxSize: maxSize)
        case .Compact:
            layoutForCompactDisplayMode(maxSize: maxSize)
        }
    }
    
    @IBAction func leftButtonTapped() {
        model.moveToPreviousImage()
    }
    
    @IBAction func rightButtonTapped() {
        model.moveToNextImage()
    }

    private func layoutForExpandedDisplayMode(maxSize maxSize: CGSize) {
        mainStackView.axis = .Vertical
        infoStackView.axis = .Horizontal
        titleLabel.textAlignment = .Left
    }
    
    private func layoutForCompactDisplayMode(maxSize maxSize: CGSize) {
        mainStackView.axis = .Horizontal
        infoStackView.axis = .Vertical
        titleLabel.textAlignment = .Center
    }
}
