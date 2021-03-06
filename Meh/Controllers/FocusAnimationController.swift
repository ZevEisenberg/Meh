//
//  FocusAnimationController.swift
//  Meh
//
//  Created by Bradley Smith on 6/13/16.
//  Copyright © 2016 Brad Smith. All rights reserved.
//

import UIKit

private struct AssociatedKeys {
    static var tintViewAssociatedKey = "tint_view"
}

protocol FocusableViewControllerDelegate: NSObjectProtocol {
    func viewControllerWillStartPresentAnimation(viewController: UIViewController)
    func viewControllerDidFinishDismissAnimation(viewController: UIViewController)
}

class FocusAnimationController: NSObject {
    private let duration = 0.5

    var positive: Bool
    var interactive = false
    var context: UIViewControllerContextTransitioning?

    init(positive: Bool) {
        self.positive = positive

        super.init()
    }
}

// MARK: - Public

extension FocusAnimationController {
    func finishTransition() {
        context?.completeTransition(true)
    }

    func cancelTransition() {
        context?.completeTransition(false)
    }
}

// MARK: - Private

private extension FocusAnimationController {
    func tintViewFromObject(object: NSObject?) -> UIView {
        if let tintView = objc_getAssociatedObject(object, &AssociatedKeys.tintViewAssociatedKey) as? UIView {
            return tintView
        }
        else {
            let tintView = UIView(frame: .zero)
            tintView.backgroundColor = UIColor.blackColor()
            objc_setAssociatedObject(object, &AssociatedKeys.tintViewAssociatedKey, tintView, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

            return tintView
        }
    }

    func removeTintViewFromObject(object: NSObject?) {
        objc_setAssociatedObject(object, &AssociatedKeys.tintViewAssociatedKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

// MARK: - UIViewControllerAnimatedTransitioning

extension FocusAnimationController: UIViewControllerAnimatedTransitioning {
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        context = transitionContext

        if let container = transitionContext.containerView(),
               fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey),
               toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) {

            let object = positive ? toViewController : fromViewController
            let tintView = self.tintViewFromObject(object)

            if positive {
                tintView.alpha = 0.0
                tintView.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(tintView)

                toViewController.view.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(toViewController.view)

                let constraints: [NSLayoutConstraint] = [
                    tintView.topAnchor.constraintEqualToAnchor(container.topAnchor),
                    tintView.leadingAnchor.constraintEqualToAnchor(container.leadingAnchor),
                    container.trailingAnchor.constraintEqualToAnchor(tintView.trailingAnchor),
                    container.bottomAnchor.constraintEqualToAnchor(tintView.bottomAnchor),

                    toViewController.view.topAnchor.constraintEqualToAnchor(container.topAnchor),
                    toViewController.view.leadingAnchor.constraintEqualToAnchor(container.leadingAnchor),
                    container.trailingAnchor.constraintEqualToAnchor(toViewController.view.trailingAnchor),
                    container.bottomAnchor.constraintEqualToAnchor(toViewController.view.bottomAnchor),
                ]

                NSLayoutConstraint.activateConstraints(constraints)

                toViewController.view.setNeedsLayout()
                toViewController.view.layoutIfNeeded()
            }

//            let presenter = positive ? fromViewController : toViewController
//            let transform = positive ? CGAffineTransformMakeScale(0.95, 0.95) : CGAffineTransformIdentity

            let animations = {
//                presenter.view.transform = transform
                tintView.alpha = self.positive ? 1.0 : 0.0
            }

            let completion = { (finished: Bool) in
                let completed = !transitionContext.transitionWasCancelled()
                if completed && !self.positive {
                    tintView.removeFromSuperview()
                    self.removeTintViewFromObject(object)
                }

                if !self.interactive {
                    transitionContext.completeTransition(completed)
                }
            }

            UIView.animateWithDuration(duration, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: animations, completion: completion)
        }
        else {
            transitionContext.completeTransition(true)
        }
    }

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return duration
    }
}
