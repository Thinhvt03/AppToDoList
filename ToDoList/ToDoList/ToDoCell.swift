//
//  ToDoCell.swift
//  ToDoList
//
//  Created by Hoàng Loan on 27/02/2023.
//

import UIKit

// MARK: - Protocol

protocol ToDoCellDelegate {
    func addCellDidTap(_ cell: ToDoCell)
    func todoCellBeginEditing(_ cell: ToDoCell)
    func todoCellDidChangeContent(_ cell: ToDoCell)
    func todoCellEndEditing(_ cell: ToDoCell)
    func checkmarkButtonDidTap(_ cell: ToDoCell)
    func todoCellDidSwipeRight(_ cell: ToDoCell)
}

class ToDoCell: UITableViewCell {

    enum ToDoCellStyle {
        case todo
        case add
    }
    
// MARK: - Properties

     var index: Int!
     let leftButton = UIButton()
     let textView = UITextView()
     var delegate: ToDoCellDelegate!
    
    public var style: ToDoCellStyle = .todo {
        didSet {
            switch style {
            case .add:
                let image = systemImage("plus")
                leftButton.setImage(image, for: .normal)
            case .todo:  
                let image = systemImage("square")
                leftButton.setImage(image, for: .normal)
            }
        }
    }
    
    public var isDone: Bool = false {
        didSet {
            let image = isDone ? systemImage("checkmark.square") : systemImage("square")
            leftButton.setImage(image, for: .normal)
            textView.isEditable = isDone ? false : true
            addAttributesToTextView()
        }
    }
    
    // Add Attribued strikethroughStyle for textView
    private func addAttributesToTextView() {
        let attributedText = NSMutableAttributedString(string: textView.text!)
        if isDone {
            attributedText.addAttributes([
                                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                                .strikethroughColor: UIColor.gray,
                                .font : UIFont.systemFont(ofSize: 20, weight: .medium),
                                .foregroundColor : UIColor.gray,
                            ],  range: NSMakeRange(0, attributedText.length))
        } else {
            attributedText.addAttributes([
                .font : UIFont.systemFont(ofSize: 20, weight: .medium),
                            ], range: NSMakeRange(0, attributedText.length))
        }
        textView.attributedText = attributedText
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupViews()
        setupGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Gesture and Views
        
    private func setupGesture() {
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeRight))
        swipeGesture.direction = .right
        contentView.addGestureRecognizer(swipeGesture)
    }
    
    private func setupViews() {
        leftButton.tintColor = .label
        leftButton.addTarget(self, action: #selector(toggleButton), for: .touchUpInside)
        
        textView.delegate = self
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
        textView.returnKeyType = .go
        textView.isScrollEnabled = false
        
        contentView.addSubview(leftButton)
        contentView.addSubview(textView)
        
        leftButton.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        leftButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        // Setup constrains using VFL
        let views: [String: Any] = ["leftButton": leftButton, "textView": textView]
        let metrics = ["leftButtonSize": NSNumber(36), "margin": NSNumber(8)]
        // Horizontal
        let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[leftButton(leftButtonSize)]-[textView]-|", metrics: metrics, views: views)
        // Vertical
        let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(margin)-[textView(>=40)]-(margin)-|", metrics: metrics, views: views)
        contentView.addConstraints(hConstraints)
        contentView.addConstraints(vConstraints)
        contentView.addConstraint(NSLayoutConstraint(item: leftButton, attribute: .centerY, relatedBy: .equal, toItem: textView, attribute: .centerY, multiplier: 1, constant: 0))
    }
    
    @objc private func toggleButton() {
        switch style {
        case .todo:
            isDone.toggle()
            delegate.checkmarkButtonDidTap(self)
        case .add:
            delegate.addCellDidTap(self)
        }
    }
        
    @objc private func swipeRight() {
        delegate.todoCellDidSwipeRight(self)
    }
}

//MARK: - TextView Delegate

extension ToDoCell: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        delegate.todoCellBeginEditing(self)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if !text.isEmpty {
            delegate.todoCellDidChangeContent(self)
        }
        if text == "\n" {
            delegate.todoCellEndEditing(self)
            return false
        }
        return true
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        delegate.todoCellEndEditing(self)
    }
}

// MARK: - Utilities

extension UIImage.Configuration {
    static let large = UIImage.SymbolConfiguration(scale: .large)
}

func systemImage(_ named: String, config: UIImage.Configuration = .large) -> UIImage? {
    UIImage(systemName: named, withConfiguration: config)
}
