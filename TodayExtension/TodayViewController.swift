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
    
    @IBOutlet var imageView: UIImageView?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var temperatureLabel: UILabel?
    @IBOutlet var weatherIconImageView: UIImageView?
    @IBOutlet var controls: UIView?
    @IBOutlet var errorLabel: UILabel?
    @IBOutlet var leftButton: UIButton?
    @IBOutlet var rightButton: UIButton?
    
    let model = TodayViewModel()
    var receivers: [ReceiverType] = []
    
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
        
        model.refresh()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        receivers.removeAll()
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
}
