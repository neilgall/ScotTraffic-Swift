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
    @IBOutlet var infoContainer: UIView!
    @IBOutlet var imageContainer: UIView!
    @IBOutlet var weatherContainer: UIView!
    
    let model = TodayViewModel()
    var receivers: [ReceiverType] = []

    let widgetLayoutGuide = UILayoutGuide()
    var widgetHeightConstraint: NSLayoutConstraint!
    var widgetWidthConstraint: NSLayoutConstraint!
    var expandedDisplayModeConstraints: [NSLayoutConstraint] = []
    var compactDisplayModeConstraints: [NSLayoutConstraint] = []
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        ensureConstraintsCreated()
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
        ensureConstraintsCreated()
        widgetWidthConstraint.constant = maxSize.width
        widgetHeightConstraint.constant = maxSize.height
        switch activeDisplayMode {
        case .Expanded:
            transitionFromConstraints(compactDisplayModeConstraints, toConstraints: expandedDisplayModeConstraints)
        case .Compact:
            transitionFromConstraints(expandedDisplayModeConstraints, toConstraints: compactDisplayModeConstraints)
        }
    }
    
    @IBAction func leftButtonTapped() {
        model.moveToPreviousImage()
    }
    
    @IBAction func rightButtonTapped() {
        model.moveToNextImage()
    }

    private func ensureConstraintsCreated() {
        guard widgetWidthConstraint == nil
            else { return }
        
        [infoContainer, imageContainer, imageView, titleLabel, leftButton, rightButton, errorLabel, weatherIconImageView, temperatureLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        view.addLayoutGuide(widgetLayoutGuide)
        
        NSLayoutConstraint.activateConstraints([
            // layout guide centred on view
            widgetLayoutGuide.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor),
            widgetLayoutGuide.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor),
            
            // Image view fills container with 4:3 aspect
            imageView.centerXAnchor.constraintEqualToAnchor(imageContainer.centerXAnchor),
            imageView.centerYAnchor.constraintEqualToAnchor(imageContainer.centerYAnchor),
            imageView.widthAnchor.constraintEqualToAnchor(imageContainer.widthAnchor),
            imageView.heightAnchor.constraintEqualToAnchor(imageContainer.heightAnchor),
            imageView.heightAnchor.constraintEqualToAnchor(imageView.widthAnchor, multiplier: 0.75),
            
            // Error label centred on image view
            errorLabel.centerXAnchor.constraintEqualToAnchor(imageContainer.centerXAnchor),
            errorLabel.centerYAnchor.constraintEqualToAnchor(imageContainer.centerYAnchor),
            errorLabel.widthAnchor.constraintLessThanOrEqualToAnchor(imageContainer.widthAnchor),
            
            // Left/right buttons cover image view equally
            leftButton.leadingAnchor.constraintEqualToAnchor(imageContainer.leadingAnchor),
            rightButton.leadingAnchor.constraintEqualToAnchor(leftButton.trailingAnchor),
            rightButton.trailingAnchor.constraintEqualToAnchor(imageContainer.trailingAnchor),
            leftButton.centerYAnchor.constraintEqualToAnchor(imageContainer.centerYAnchor),
            leftButton.centerYAnchor.constraintEqualToAnchor(imageContainer.centerYAnchor),
            rightButton.heightAnchor.constraintEqualToAnchor(imageContainer.heightAnchor),
            rightButton.heightAnchor.constraintEqualToAnchor(imageContainer.heightAnchor),
            leftButton.widthAnchor.constraintEqualToAnchor(rightButton.widthAnchor),
            
            // title label is at top of info
            titleLabel.topAnchor.constraintEqualToAnchor(infoContainer.topAnchor) ~ "title at top",

            // weather inside weather container
            temperatureLabel.topAnchor.constraintEqualToAnchor(weatherContainer.topAnchor),
            temperatureLabel.bottomAnchor.constraintEqualToAnchor(weatherContainer.bottomAnchor),
            weatherIconImageView.topAnchor.constraintEqualToAnchor(weatherContainer.topAnchor),
            weatherIconImageView.bottomAnchor.constraintEqualToAnchor(weatherContainer.bottomAnchor),
            temperatureLabel.leadingAnchor.constraintEqualToAnchor(weatherContainer.leadingAnchor),
            temperatureLabel.trailingAnchor.constraintEqualToAnchor(weatherIconImageView.trailingAnchor),
            weatherIconImageView.trailingAnchor.constraintEqualToAnchor(weatherContainer.trailingAnchor),

            // weather container is at bottom of info
            weatherContainer.bottomAnchor.constraintEqualToAnchor(infoContainer.bottomAnchor),
            
            // weather icon is square
            weatherIconImageView.heightAnchor.constraintLessThanOrEqualToConstant(44) ~ (UILayoutPriorityRequired-1) ~ "weather icon height",
            weatherIconImageView.widthAnchor.constraintEqualToAnchor(weatherIconImageView.heightAnchor) ~ "weather square",
        ])
        
        expandedDisplayModeConstraints = [
            // image container full width at top
            imageContainer.widthAnchor.constraintEqualToAnchor(widgetLayoutGuide.widthAnchor),
            imageContainer.centerXAnchor.constraintEqualToAnchor(widgetLayoutGuide.centerXAnchor),
            imageContainer.topAnchor.constraintEqualToAnchor(widgetLayoutGuide.topAnchor),
            
            // info container below image
            infoContainer.widthAnchor.constraintEqualToAnchor(widgetLayoutGuide.widthAnchor),
            infoContainer.centerXAnchor.constraintEqualToAnchor(widgetLayoutGuide.centerXAnchor),
            infoContainer.topAnchor.constraintEqualToAnchor(imageContainer.bottomAnchor),
            infoContainer.bottomAnchor.constraintEqualToAnchor(widgetLayoutGuide.bottomAnchor),

            // title, and weather in horizontal row
            titleLabel.leadingAnchor.constraintEqualToAnchor(infoContainer.leadingAnchor),
            titleLabel.bottomAnchor.constraintEqualToAnchor(infoContainer.bottomAnchor),
            weatherContainer.leadingAnchor.constraintEqualToAnchor(titleLabel.trailingAnchor),
            weatherContainer.topAnchor.constraintEqualToAnchor(infoContainer.topAnchor),
            weatherContainer.trailingAnchor.constraintEqualToAnchor(infoContainer.trailingAnchor),
        ]
        
        compactDisplayModeConstraints = [
            // image container full height on left
            imageContainer.heightAnchor.constraintEqualToAnchor(widgetLayoutGuide.heightAnchor),
            imageContainer.centerYAnchor.constraintEqualToAnchor(widgetLayoutGuide.centerYAnchor),
            imageContainer.leadingAnchor.constraintEqualToAnchor(widgetLayoutGuide.leadingAnchor),
            
            // info container centred in remaining space
            infoContainer.centerYAnchor.constraintEqualToAnchor(widgetLayoutGuide.centerYAnchor),
            infoContainer.leadingAnchor.constraintEqualToAnchor(imageContainer.trailingAnchor),
            infoContainer.trailingAnchor.constraintEqualToAnchor(widgetLayoutGuide.trailingAnchor),
            
            // title label centred in info
            titleLabel.centerXAnchor.constraintEqualToAnchor(infoContainer.centerXAnchor),
            titleLabel.widthAnchor.constraintLessThanOrEqualToAnchor(infoContainer.widthAnchor),
            
            // weather below title
            weatherContainer.centerXAnchor.constraintEqualToAnchor(infoContainer.centerXAnchor),
            weatherContainer.topAnchor.constraintEqualToAnchor(titleLabel.bottomAnchor),
        ]
        
        widgetWidthConstraint = widgetLayoutGuide.widthAnchor.constraintEqualToConstant(0)
        widgetHeightConstraint = widgetLayoutGuide.heightAnchor.constraintEqualToConstant(0)
        widgetWidthConstraint.active = true
        widgetHeightConstraint.active = true
        
        if #available(iOSApplicationExtension 10.0, *) {
            guard let extensionContext = extensionContext else {
                return
            }
            
            extensionContext.widgetLargestAvailableDisplayMode = .Expanded

            switch extensionContext.widgetActiveDisplayMode {
            case .Expanded:
                NSLayoutConstraint.activateConstraints(expandedDisplayModeConstraints)
            case .Compact:
                NSLayoutConstraint.activateConstraints(compactDisplayModeConstraints)
            }
        } else {
            // pre iOS-10 only has expanded display mode
            NSLayoutConstraint.activateConstraints(expandedDisplayModeConstraints)
        }
    }
    
    private func transitionFromConstraints(fromConstraints: [NSLayoutConstraint], toConstraints: [NSLayoutConstraint]) {
        NSLayoutConstraint.deactivateConstraints(fromConstraints)
        NSLayoutConstraint.activateConstraints(toConstraints)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        NSLog("view \(view.frame)")
        NSLog("layoutGuide \(widgetLayoutGuide.layoutFrame)")
        NSLog("imageContainer \(imageContainer!.frame)")
        NSLog("infoContainer \(infoContainer!.frame)")
        NSLog("titleLabel \(titleLabel!.frame)")
    }
}

infix operator ~ { associativity left precedence 150 }
private func ~ (constraint: NSLayoutConstraint, name: String) -> NSLayoutConstraint {
    constraint.identifier = name
    return constraint
}

private func ~ (constraint: NSLayoutConstraint, priority: UILayoutPriority) -> NSLayoutConstraint {
    constraint.priority = priority
    return constraint
}
