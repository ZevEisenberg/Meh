//
//  ImageViewController.swift
//  Meh
//
//  Created by Bradley Smith on 3/5/16.
//  Copyright © 2016 Brad Smith. All rights reserved.
//

import UIKit
import AlamofireImage
import pop

class ImageViewController: UIViewController {
    private let minimumZoom: CGFloat = 1.0
    private let maximumZoom: CGFloat = 3.0
    private let URL: NSURL
    private let originalRect: CGRect
    private let scrollView = UIScrollView(frame: .zero)
    private let imageView = UIImageView(frame: .zero)
    private let panGesture = UIPanGestureRecognizer(target: nil, action: nil)

    private var previousLocation: CGPoint = .zero
    private var animationController = FocusAnimationController(positive: true)
    private var interactionController: UIPercentDrivenInteractiveTransition?

    weak var delegate: FocusableViewControllerDelegate?

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    init(URL: NSURL, originalRect: CGRect) {
        self.URL = URL
        self.originalRect = originalRect

        super.init(nibName: nil, bundle: nil)

        transitioningDelegate = self
        modalPresentationStyle = .Custom
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = UIColor.clearColor()

        configureViews()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        panGesture.addTarget(self, action: #selector(ImageViewController.handlePan(_:)))
        scrollView.addGestureRecognizer(panGesture)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ImageViewController.handleTap))
        view.addGestureRecognizer(tapGesture)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        configureLayout()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let animations = { (context: UIViewControllerTransitionCoordinatorContext) in
            self.delegate?.viewControllerWillStartPresentAnimation(self)

            self.scrollView.center = self.view.center
        }

        let completion = { (context: UIViewControllerTransitionCoordinatorContext) in

        }

        transitionCoordinator()?.animateAlongsideTransition(animations, completion: completion)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        let animations = { (context: UIViewControllerTransitionCoordinatorContext) in
            if self.interactionController == nil {
                self.scrollView.center = CGPoint(x: self.originalRect.midX, y: self.originalRect.midY)
            }
        }

        let completion = { (context: UIViewControllerTransitionCoordinatorContext) -> Void in
            if !context.isCancelled() {
                self.delegate?.viewControllerDidFinishDismissAnimation(self)
            }
        }

        transitionCoordinator()?.animateAlongsideTransition(animations, completion: completion)
    }
}

// MARK: - Private

private extension ImageViewController {
    func configureViews() {
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.alwaysBounceVertical = true
        scrollView.bouncesZoom = true
        scrollView.backgroundColor = UIColor.clearColor()
        scrollView.delegate = self
        scrollView.minimumZoomScale = minimumZoom
        scrollView.maximumZoomScale = maximumZoom
        scrollView.zoomScale = minimumZoom
        view.addSubview(scrollView)

        imageView.contentMode = .ScaleAspectFill
        let width = UIScreen.mainScreen().bounds.width
        let height = width - 40.0
        let size = CGSize(width: width, height: height)
        let imageFilter = AspectScaledToFitSizeFilter(size: size)

        imageView.af_setImageWithURL(URL, placeholderImage: nil, filter: imageFilter, imageTransition: .None, runImageTransitionIfCached: false, completion: nil)
        scrollView.addSubview(imageView)
    }

    func configureLayout() {
        if CGRectEqualToRect(scrollView.frame, .zero) {
            scrollView.frame = CGRect(x: 0.0, y: 0.0, width: view.bounds.width, height: view.bounds.height)
            imageView.frame = CGRect(x: 0.0, y: 0.0, width: originalRect.width, height: originalRect.height)

            scrollView.contentSize = imageView.bounds.size

            centerScrollViewContents()

            scrollView.center = CGPoint(x: originalRect.midX, y: originalRect.midY)
        }
    }

    func centerScrollViewContents() {
        var horizontalInset: CGFloat = 0.0
        var verticalInset: CGFloat = 0.0

        if scrollView.contentSize.width < scrollView.bounds.width {
            horizontalInset = (scrollView.bounds.width - scrollView.contentSize.width) / 2.0
        }

        if scrollView.contentSize.height < scrollView.bounds.height {
            verticalInset = (scrollView.bounds.height - scrollView.contentSize.height) / 2.0
        }

        if scrollView.window?.screen.scale < 2.0 {
            horizontalInset = floor(horizontalInset)
            verticalInset = floor(verticalInset)
        }

        // Use `contentInset` to center the contents in the scroll view. Reasoning explained here: http://petersteinberger.com/blog/2013/how-to-center-uiscrollview/
        scrollView.contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
    }

    @objc func handleTap() {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)

        scrollView.setZoomScale(minimumZoom, animated: true)
    }

    @objc func handlePan(gesture: UIPanGestureRecognizer) {
        let location = gesture.locationInView(view)

        switch gesture.state {
        case .Began:
            interactionController = UIPercentDrivenInteractiveTransition()
            presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        case .Changed:
            scrollView.center.x += (location.x - previousLocation.x)
            scrollView.center.y += (location.y - previousLocation.y)

            let delta = fabs(scrollView.frame.midY - view.frame.midY)
            let percent = min(delta / view.frame.midY, 100.0)

            interactionController?.updateInteractiveTransition(percent)
        case .Ended: fallthrough
        case .Cancelled: fallthrough
        case .Failed:
            let velocity = gesture.velocityInView(gesture.view)
            let animation = POPSpringAnimation(propertyNamed: kPOPViewCenter)
            animation.velocity = NSValue(CGPoint: velocity)

            if fabs(velocity.x) > 150.0 || fabs(velocity.y) > 150.0 {
                let center = CGPoint(x: self.originalRect.midX, y: self.originalRect.midY)
                animation.toValue = NSValue(CGPoint: center)
                animation.completionBlock = { [weak self] (popAnimation: POPAnimation?, finished: Bool) in
                    self?.animationController.finishTransition()
                }

                scrollView.pop_addAnimation(animation, forKey: "spring")

                interactionController?.finishInteractiveTransition()
            }
            else {
                animation.toValue = NSValue(CGPoint: view.center)
                animation.completionBlock = { [weak self] (popAnimation: POPAnimation?, finished: Bool) in
                    self?.animationController.cancelTransition()
                }

                scrollView.pop_addAnimation(animation, forKey: "spring")

                interactionController?.cancelInteractiveTransition()
            }

            interactionController = nil
        default:
            break
        }

        previousLocation = location
    }
}

// MARK: - UIScrollViewDelegate

extension ImageViewController: UIScrollViewDelegate {
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(scrollView: UIScrollView) {
        centerScrollViewContents()

        panGesture.enabled = (scrollView.zoomScale == minimumZoom)
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension ImageViewController: UIViewControllerTransitioningDelegate {
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return animationController
    }

    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animationController.positive = false
        animationController.interactive = (interactionController != nil)

        return animationController
    }

    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController
    }
}
