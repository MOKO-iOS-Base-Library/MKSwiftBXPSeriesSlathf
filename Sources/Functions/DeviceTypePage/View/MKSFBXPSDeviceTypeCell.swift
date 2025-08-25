//
//  MKBXPSDeviceTypeCell.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/6/17.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKBXPSDeviceTypeCellModel {
    var msg: String = ""
    var iconName: String = ""
    var contentMsg: String = ""
    
    init() {}
}

class MKBXPSDeviceTypeCell: MKSwiftBaseCell {
    
    var dataModel: MKBXPSDeviceTypeCellModel? {
        didSet {
            updateContent()
        }
    }
    
    class func initCellWithTableView(_ tableView: UITableView) -> MKBXPSDeviceTypeCell {
        let identifier = "MKBXPSDeviceTypeCellIdenty"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKBXPSDeviceTypeCell
        if cell == nil {
            cell = MKBXPSDeviceTypeCell(style: .default, reuseIdentifier: identifier)
        }
        return cell!
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addContent()
    }
    
    //MARK: - Super method
    override func layoutSubviews() {
        super.layoutSubviews()
        msgLabel.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(-15)
            make.top.equalTo(10)
            make.height.equalTo(Font.MKFont(15).lineHeight)
        }
        icon.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(40)
            make.top.equalTo(msgLabel.snp.bottom).offset(5)
            make.height.equalTo(40)
        }
        let noteSize = contentLabel.text!.size(withFont: Font.MKFont(13), maxSize: CGSize(width: (contentView.frame.size.width - 2 * 15 - 40 - 5), height: .greatestFiniteMagnitude))
        contentLabel.snp.remakeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(5)
            make.right.equalTo(-15)
            make.centerY.equalTo(icon.snp.centerY)
            make.height.equalTo(noteSize.height)
        }
    }
    
    //MARK: - Private method
    
    private func updateContent() {
        guard let dataModel = dataModel else { return }
        
        msgLabel.text = dataModel.msg
        contentLabel.text = dataModel.contentMsg
        icon.image = loadImage(name: dataModel.iconName,ext: "png")
        setNeedsLayout()
    }
    
    private func addContent() {
        contentView.addSubview(msgLabel)
        contentView.addSubview(icon)
        contentView.addSubview(contentLabel)
    }
    
    //MARK: - Lazy
    private lazy var msgLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel()
    }()
    private lazy var icon: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    private lazy var contentLabel: UILabel = {
        let contentLabel = UILabel()
        contentLabel.textAlignment = .left
        contentLabel.textColor = Color.rgb(175, 175, 175)
        contentLabel.font = Font.MKFont(13)
        contentLabel.numberOfLines = 0
        return contentLabel
    }()
}
