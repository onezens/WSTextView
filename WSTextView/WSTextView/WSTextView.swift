//
//  WSTextView.swift
//  Weibo
//
//  Created by WackoSix on 16/1/27.
//  Copyright © 2016年 WackoSix. All rights reserved.
//

import UIKit

/// 计算字体的size
func sizeOfText(text: String, font: UIFont, maxSize: CGSize) -> CGSize {
    
    return ((text as NSString)).boundingRectWithSize(maxSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil).size
}

@IBDesignable
class WSTextView: UITextView {
    
    @IBInspectable
    // 预读文本
    var placeHolderText: String? {
        
        didSet {
            
            placeHolderLbl.text = placeHolderText
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        
        didSet {
            
            self.layer.cornerRadius = cornerRadius
            self.layer.masksToBounds = true
        }
    }
    
    // 显示的文字
    override var text: String? {
        
        didSet {
            
            placeHolderLbl.hidden = self.hasText()
        }
    }
    
    // 字体
    override var font: UIFont? {
        
        didSet {
            
            placeHolderLbl.font = font
        }
    }
    
    //最大能够添加的图片个数
    var maxInsertImageCount = 0
    var textFrame: CGRect = CGRectZero
    
    // MARK: - init
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    override func insertText(text: String) {
        
        super.insertText(text)
        delegate?.textViewDidChange?(self)
    }
    override func deleteBackward() {
        
        super.deleteBackward()
        delegate?.textViewDidChange?(self)
    }
    
    // MARK: - private method
    private func setupUI() {
        
        // 添加通知，监听当前的文字编辑情况
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "valueChange", name: UITextViewTextDidChangeNotification, object: self)
        
        placeHolderText = "placeHolderText"
        addSubview(placeHolderLbl)
        let topMargin: CGFloat = 8
        let leadingMargin: CGFloat = 5
        placeHolderLbl.frame.origin = CGPoint(x: leadingMargin, y: topMargin)
        placeHolderLbl.frame.size = sizeOfText(placeHolderText!, font: placeHolderLbl.font, maxSize: CGSizeMake(self.frame.width - leadingMargin * 2, CGFloat(MAXFLOAT)))
        self.font = UIFont.systemFontOfSize(15)
        
    }
    
    @objc private func valueChange() {
        
        placeHolderLbl.hidden = self.hasText()
        let fixWidth = frame.width
        let newSize = sizeThatFits(CGSize(width: fixWidth, height: CGFloat(MAXFLOAT)))
        let newFrame = CGRect(origin: frame.origin, size: CGSize(width: fixWidth, height: newSize.height))
        self.textFrame = newFrame
        
    }
    deinit {
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - lazy loading
    
    private lazy var placeHolderLbl: UILabel = {
        
        let lbl = UILabel()
        lbl.textColor = UIColor.grayColor()
        lbl.numberOfLines = 0
        return lbl
    }()
    
    var imageAttachement: [UIImage] {
        
        var images = [UIImage]()
        
        self.attributedText.enumerateAttributesInRange(NSMakeRange(0, self.attributedText.length), options: .Reverse) { (attri, range, _) -> Void in
            
            if attri["NSAttachment"] != nil {
                
                let attachment = attri["NSAttachment"] as! WSTextAttachment
                if attachment.attachmentType == .Image {
                    
                    images.append(attachment.image!)
                }
            }
        }
        
        return images
    }
}


// MARK: - 文本操作 insertImage
extension WSTextView {
    
    ///  插入一个表情，图片可以是一个自定义表情，按当前的文字大小为尺寸来显示
    ///
    ///  - parameter image:表情图片
    func insertEmotionImage(image: UIImage) {
        
        let lineWidth = (self.font?.lineHeight)!
        insertImage(image, imageSize: CGSizeMake(lineWidth, lineWidth), isEmotion: true)
    }
    
    ///  添加一张图片，图片大小按宽度的96%来等比缩放（96%，图片在中间😂）
    ///
    ///  - parameter image: 要添加的图片
    func insertImage(image: UIImage) {
        
        if self.imageAttachement.count >= maxInsertImageCount {
            
            return
        }
        let width = self.bounds.width * 0.96
        self.insertImage(image, imageSize: CGSizeMake(width, (image.size.height / image.size.width) * width))
    }
    
    private func insertImage(image: UIImage, imageSize: CGSize, isEmotion: Bool = false) {
        
        let attachement = WSTextAttachment()
        attachement.attachmentType = isEmotion ? .Emotion : .Image
        attachement.image = image
        // let lineWidth = (self.font?.lineHeight)!
        attachement.bounds = CGRect(origin: CGPointZero, size: imageSize)
        
        //获取原始的富文本
        let originalAttr = NSMutableAttributedString(attributedString: self.attributedText)
        
        //后去当前光标的位置，并且替换文本
        var range = self.selectedRange
        originalAttr.replaceCharactersInRange(range, withAttributedString: NSAttributedString(attachment: attachement))
        
        //保持原先的文字的大小，没有这句话图片文字会在下次输入的时候变小
        originalAttr.addAttribute(NSFontAttributeName, value: self.font!, range: NSMakeRange(0, originalAttr.length))
        
        self.attributedText = originalAttr
        
        //让光标回到下一个位置
        range.location++
        range.length = 0
        selectedRange = range
        
        //发送通知和代理
        NSNotificationCenter.defaultCenter().postNotificationName(UITextViewTextDidChangeNotification, object: self)
        delegate?.textViewDidChange?(self)
        
        if !isEmotion {
            //添加一个换行
            self.insertText("\n")
        }
    }
    
}


/************************** NSTextAttachment *******************************/

enum WSTextAttachmentType: Int {
    case Default    =   0
    case Image      =   1
    case Emotion    =   2
}


class WSTextAttachment: NSTextAttachment {
    
    var attachmentType: WSTextAttachmentType = .Default
    
}
