//
//  MKSFBXSOptionsCell.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/19.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSOptionsCellModel {
    var msg: String = ""
    var noteMsg: String = ""
    var iconName: String = ""
}

class MKSFBXSOptionsCell: MKSwiftBaseCell {
    
    // MARK: - Properties
    var dataModel: MKSFBXSOptionsCellModel? {
        didSet {
            updateContent()
        }
    }
    
    // MARK: - Class Methods
    class func initCell(with tableView: UITableView) -> MKSFBXSOptionsCell {
        let identifier = "MKSFBXSOptionsCellIdenty"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKSFBXSOptionsCell
        if cell == nil {
            cell = MKSFBXSOptionsCell(style: .default, reuseIdentifier: identifier)
        }
        return cell!
    }
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(msgLabel)
        contentView.addSubview(noteLabel)
        contentView.addSubview(icon)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupUI()
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        msgLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(-15)
            make.top.equalTo(10)
            make.height.equalTo(Font.MKFont(15.0).lineHeight)
        }
        
        icon.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(40)
            make.top.equalTo(msgLabel.snp.bottom).offset(5)
            make.height.equalTo(40)
        }
        
        // Update note label constraints based on content
        let maxWidth = contentView.frame.width - 2 * 15 - 40 - 5
        let noteSize = noteLabel.text?.size(withFont: noteLabel.font, maxSize: CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
                
        noteLabel.snp.remakeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(5)
            make.right.equalTo(-15)
            make.centerY.equalTo(icon.snp.centerY)
            make.height.equalTo(noteSize?.height ?? 0)
        }
    }
    
    private func updateContent() {
        guard let model = dataModel else { return }
        
        msgLabel.text = model.msg
        noteLabel.text = model.noteMsg
        icon.image = moduleIcon(name: model.iconName, in: .module)
    }
    
    // MARK: - UI Components
    private lazy var msgLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel()
    }()
    
    private lazy var noteLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = Font.MKFont(13.0)
        label.textColor = Color.rgb(175, 175, 175)
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var icon: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
}
