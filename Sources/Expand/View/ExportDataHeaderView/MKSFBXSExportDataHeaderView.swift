//
//  MKSFBXSExportDataHeaderView.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/7.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

protocol MKSFBXSExportDataHeaderViewDelegate: AnyObject {
    func mk_bxs_swf_syncButtonPressed(_ selected: Bool)
    func mk_bxs_swf_switchButtonPressed(_ selected: Bool)
    func mk_bxs_swf_deleteButtonPressed()
    func mk_bxs_swf_exportButtonPressed()
}

class MKSFBXSExportDataHeaderView: UIView {
    
    weak var delegate: MKSFBXSExportDataHeaderViewDelegate?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Super Methods
    override func layoutSubviews() {
        super.layoutSubviews()
        setupConstraints()
    }
    
    // MARK: - Public Methods
    
    func resetAllStatus() {
        syncButton.isSelected = false
        synIcon.layer.removeAnimation(forKey: "synIconAnimationKey")
        syncLabel.text = "Sync"
        
        switchButton.isEnabled = true
        switchButton.isSelected = false
        
        exportButton.isEnabled = true
        deleteButton.isEnabled = true
    }
    
    // MARK: - Event Methods
    
    @objc private func syncButtonPressed() {
        syncButton.isSelected = !syncButton.isSelected
        synIcon.layer.removeAnimation(forKey: "synIconAnimationKey")
        
        // If sync is enabled, disable list/curve switching
        switchButton.isEnabled = !syncButton.isSelected
        
        // If sync is enabled, disable delete and export
        exportButton.isEnabled = !syncButton.isSelected
        deleteButton.isEnabled = !syncButton.isSelected
        
        if syncButton.isSelected {
            // Start rotation animation
            let animation = CABasicAnimation(keyPath: "transform.rotation.z")
            animation.toValue = NSNumber(value: Double.pi * 2.0)
            animation.duration = 2.0
            animation.isCumulative = true
            animation.repeatCount = Float.greatestFiniteMagnitude
            synIcon.layer.add(animation, forKey: "synIconAnimationKey")
            
            syncLabel.text = "Stop"
            
            if switchButton.isSelected {
                // If curve view is shown, switch to list view when starting sync
                switchButtonPressed()
            }
        } else {
            syncLabel.text = "Sync"
        }
        
        delegate?.mk_bxs_swf_syncButtonPressed(syncButton.isSelected)
    }
    
    @objc private func switchButtonPressed() {
        switchButton.isSelected = !switchButton.isSelected
        let iconName = switchButton.isSelected ? "bxs_swf_exportHT_curveSelected" : "bxs_swf_exportHT_tableSelected"
        let icon = moduleIcon(name: iconName, in: .module)
        switchButton.setImage(icon, for: .normal)
        
        delegate?.mk_bxs_swf_switchButtonPressed(switchButton.isSelected)
    }
    
    @objc private func deleteButtonPressed() {
        delegate?.mk_bxs_swf_deleteButtonPressed()
    }
    
    @objc private func exportButtonPressed() {
        delegate?.mk_bxs_swf_exportButtonPressed()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        addSubview(syncButton)
        syncButton.addSubview(synIcon)
        addSubview(syncLabel)
        addSubview(switchButton)
        addSubview(switchLabel)
        addSubview(deleteButton)
        addSubview(deleteLabel)
        addSubview(exportButton)
        addSubview(exportLabel)
    }
    
    private func setupConstraints() {
        syncButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(30)
            make.top.equalToSuperview().offset(5)
            make.height.equalTo(30)
        }
        
        synIcon.snp.makeConstraints { make in
            make.centerX.equalTo(syncButton.snp.centerX)
            make.centerY.equalTo(syncButton.snp.centerY)
            make.width.height.equalTo(25)
        }
        
        syncLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(25)
            make.top.equalTo(syncButton.snp.bottom).offset(2)
            make.height.equalTo(UIFont.systemFont(ofSize: 10).lineHeight)
        }
        
        switchButton.snp.makeConstraints { make in
            make.left.equalTo(syncButton.snp.right).offset(20)
            make.width.equalTo(40)
            make.centerY.equalTo(syncButton.snp.centerY)
            make.height.equalTo(30)
        }
        
        switchLabel.snp.makeConstraints { make in
            make.left.right.equalTo(switchButton)
            make.top.equalTo(switchButton.snp.bottom).offset(2)
            make.height.equalTo(UIFont.systemFont(ofSize: 10).lineHeight)
        }
        
        deleteButton.snp.makeConstraints { make in
            make.right.equalTo(exportButton.snp.left).offset(-35)
            make.width.equalTo(40)
            make.centerY.equalTo(syncButton.snp.centerY)
            make.height.equalTo(30)
        }
        
        deleteLabel.snp.makeConstraints { make in
            make.centerX.equalTo(deleteButton.snp.centerX)
            make.width.equalTo(60)
            make.top.equalTo(deleteButton.snp.bottom).offset(2)
            make.height.equalTo(UIFont.systemFont(ofSize: 10).lineHeight)
        }
        
        exportButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-15)
            make.width.equalTo(40)
            make.centerY.equalTo(syncButton.snp.centerY)
            make.height.equalTo(30)
        }
        
        exportLabel.snp.makeConstraints { make in
            make.left.right.equalTo(exportButton)
            make.top.equalTo(exportButton.snp.bottom).offset(2)
            make.height.equalTo(UIFont.systemFont(ofSize: 10).lineHeight)
        }
    }
    
    // MARK: - Lazy Components
    
    private lazy var syncButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(syncButtonPressed), for: .touchUpInside)
        return button
    }()
    
    private lazy var synIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = moduleIcon(name: "bxs_swf_threeAxisAcceLoadingIcon", in: .module)
        return imageView
    }()
    
    private lazy var syncLabel: UILabel = {
        let label = UILabel()
        label.textColor = Color.defaultText
        label.textAlignment = .center
        label.font = Font.MKFont(10.0)
        label.text = "Sync"
        return label
    }()
    
    private lazy var switchButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = moduleIcon(name: "bxs_swf_exportHT_tableSelected", in: .module)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(switchButtonPressed), for: .touchUpInside)
        return button
    }()
    
    private lazy var switchLabel: UILabel = {
        let label = UILabel()
        label.textColor = Color.defaultText
        label.textAlignment = .center
        label.font = Font.MKFont(10.0)
        label.text = "Display"
        return label
    }()
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = moduleIcon(name: "bxs_swf_slotExportDeleteIcon", in: .module)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(deleteButtonPressed), for: .touchUpInside)
        return button
    }()
    
    private lazy var deleteLabel: UILabel = {
        let label = UILabel()
        label.textColor = Color.defaultText
        label.textAlignment = .center
        label.font = Font.MKFont(10.0)
        label.text = "Erase all"
        return label
    }()
    
    private lazy var exportButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = moduleIcon(name: "bxs_swf_slotExportEnableIcon", in: .module)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(exportButtonPressed), for: .touchUpInside)
        return button
    }()
    
    private lazy var exportLabel: UILabel = {
        let label = UILabel()
        label.textColor = Color.defaultText
        label.textAlignment = .center
        label.font = Font.MKFont(10.0)
        label.text = "Export"
        return label
    }()
}
