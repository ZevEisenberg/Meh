//
//  ButtonHeaderView.swift
//  Meh
//
//  Created by Bradley Smith on 3/3/16.
//  Copyright © 2016 Brad Smith. All rights reserved.
//

import UIKit

protocol ButtonHeaderViewDelegate {
    func didSelectButton()
}

class ButtonHeaderView: UICollectionReusableView {

    // MARK: - Properties

    private let titleLabel = UILabel(frame: CGRect.zero)
    private let button = UIButton(type: .System)
    private var deal: Deal?

    var delegate: ButtonHeaderViewDelegate?

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureViews()
        configureLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        if let layoutAttributes = layoutAttributes as? HeaderCollectionViewLayoutAttributes {
            if layoutAttributes.isPinned {
                if backgroundColor == nil {
                    backgroundColor = deal?.theme.backgroundColor
                }
            }
            else {
                if backgroundColor != nil {
                    backgroundColor = nil
                }
            }
        }
    }

    // MARK: - Setup

    func configureViews() {
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        button.addTarget(self, action: "didSelectButton", forControlEvents: .TouchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
    }

    func configureLayout() {
        let titleLabelConstraints: [NSLayoutConstraint] = [
            titleLabel.topAnchor.constraintEqualToAnchor(topAnchor, constant: 10.0),
            titleLabel.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: 10.0),
            trailingAnchor.constraintEqualToAnchor(titleLabel.trailingAnchor, constant: 10.0)
        ]

        NSLayoutConstraint.activateConstraints(titleLabelConstraints)

        let buttonConstraints: [NSLayoutConstraint] = [
            button.heightAnchor.constraintEqualToConstant(64.0),
            button.topAnchor.constraintEqualToAnchor(titleLabel.bottomAnchor, constant: 10.0),
            button.leadingAnchor.constraintEqualToAnchor(leadingAnchor),
            trailingAnchor.constraintEqualToAnchor(button.trailingAnchor),
            bottomAnchor.constraintEqualToAnchor(button.bottomAnchor)
        ]

        NSLayoutConstraint.activateConstraints(buttonConstraints)
    }

    func configureWithDeal(deal: Deal?) {
        self.deal = deal

        button.backgroundColor = deal?.theme.accentColor

        let title = deal?.title ?? "No Name"

        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.lineBreakMode = .ByWordWrapping
        titleParagraphStyle.alignment = .Center

        let titleAttributes = [
            NSFontAttributeName: UIFont.dealTitleFont(),
            NSForegroundColorAttributeName: deal?.theme.foregroundColor ?? UIColor.blackColor(),
            NSParagraphStyleAttributeName: titleParagraphStyle
        ]

        titleLabel.attributedText = NSAttributedString(string: title, attributes: titleAttributes)

        var buttonTitle = ""
        if let price = deal?.price {
            buttonTitle = "$" + price
        }
        else {
            buttonTitle = "No Price"
        }

        let buttonParagraphStyle = NSMutableParagraphStyle()
        buttonParagraphStyle.alignment = .Center

        let buttonAttributes = [
            NSFontAttributeName: UIFont.buyCellFont(),
            NSForegroundColorAttributeName: deal?.theme.backgroundColor ?? UIColor.blackColor(),
            NSParagraphStyleAttributeName: buttonParagraphStyle
        ]

        let attributedTitle = NSAttributedString(string: buttonTitle, attributes: buttonAttributes)
        button.setAttributedTitle(attributedTitle, forState: .Normal)
    }

    // MARK: - Actions

    func didSelectButton() {
        delegate?.didSelectButton()
    }

    static func heightWithDeal(deal: Deal?, width: CGFloat) -> CGFloat {
        let constrainedWidth = width - 20.0
        let size = CGSize(width: constrainedWidth, height: CGFloat.max)
        let options: NSStringDrawingOptions = [.UsesLineFragmentOrigin, .UsesFontLeading]

        let title = deal?.title ?? "No Name"

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .ByWordWrapping
        paragraphStyle.alignment = .Center

        let attributes = [
            NSFontAttributeName: UIFont.dealTitleFont(),
            NSForegroundColorAttributeName: deal?.theme.foregroundColor ?? UIColor.blackColor(),
            NSParagraphStyleAttributeName: paragraphStyle
        ]

        let boundingRect = (title as NSString).boundingRectWithSize(size, options: options, attributes: attributes, context: nil)
        let titleLabelHeight = ceil(boundingRect.size.height)

        return titleLabelHeight + 20.0 + 64.0
    }
}
