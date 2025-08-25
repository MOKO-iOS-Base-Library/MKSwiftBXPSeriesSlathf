//
//  MKSFBXSAccelerationHeaderView.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/5.
//

import UIKit
import MKBaseSwiftModule

protocol MKSFBXSAccelerationHeaderViewDelegate: AnyObject {
    func updateThreeAxisNotifyStatus(_ notify: Bool)
    func clearMotionTriggerCountButtonPressed()
}

class MKSFBXSAccelerationHeaderView: UIView {
    weak var delegate: MKSFBXSAccelerationHeaderViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Super methods
    override func layoutSubviews() {
        super.layoutSubviews()
        setupConstraints()
    }
    
    //MARK: - Public methods
    func updateTriggerCount(_ count: String) {
        mtCountValueLabel.text = count
    }
    
    func updateDataWith(xData: String, yData: String, zData: String) {
        let xString = "X-axis:\(xData)mg"
        let yString = "Y-axis:\(yData)mg"
        let zString = "Z-axis:\(zData)mg"
        dataLabel.text = "\(xString);\(yString);\(zString)"
    }
    
    //MARK: - Private methods
    private func setupUI() {
        backgroundColor = Color.rgb(242, 242, 242)
        
        addSubview(backView)
        backView.addSubview(syncButton)
        syncButton.addSubview(synIcon)
        backView.addSubview(syncLabel)
        backView.addSubview(dataLabel)
        
        addSubview(bottomView)
        bottomView.addSubview(mtCountLabel)
        bottomView.addSubview(mtCountValueLabel)
        bottomView.addSubview(clearButton)
    }
    
    private func setupConstraints() {
        backView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(5)
            make.right.equalToSuperview().offset(-5)
            make.top.equalToSuperview().offset(15)
            make.height.equalTo(60)
        }
        
        syncButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(30)
            make.top.equalToSuperview().offset(5)
            make.height.equalTo(30)
        }
        
        synIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(25)
        }
        
        syncLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(25)
            make.top.equalTo(syncButton.snp.bottom).offset(2)
            make.height.equalTo(Font.MKFont(10.0).lineHeight)
        }
        
        dataLabel.snp.makeConstraints { make in
            make.left.equalTo(syncButton.snp.right).offset(5)
            make.right.equalToSuperview().offset(-15)
            make.centerY.equalTo(syncButton.snp.centerY).offset(2)
            make.height.equalTo(Font.MKFont(12.0).lineHeight)
        }
        
        bottomView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(5)
            make.right.equalToSuperview().offset(-5)
            make.top.equalTo(backView.snp.bottom).offset(15)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        clearButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-15)
            make.width.equalTo(45)
            make.centerY.equalToSuperview()
            make.height.equalTo(30)
        }
        
        mtCountLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(150)
            make.centerY.equalToSuperview()
            make.height.equalTo(Font.MKFont(15.0).lineHeight)
        }
        
        mtCountValueLabel.snp.makeConstraints { make in
            make.left.equalTo(mtCountLabel.snp.right).offset(10)
            make.right.equalTo(clearButton.snp.left).offset(-5)
            make.centerY.equalToSuperview()
            make.height.equalTo(Font.MKFont(12.0).lineHeight)
        }
    }
    
    @objc private func syncButtonPressed() {
        syncButton.isSelected = !syncButton.isSelected
        synIcon.layer.removeAnimation(forKey: "bxs_swf_synIconAnimationKey")
        delegate?.updateThreeAxisNotifyStatus(syncButton.isSelected)
        
        if syncButton.isSelected {
            let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
            rotation.toValue = NSNumber(value: Double.pi * 2)
            rotation.duration = 2
            rotation.isCumulative = true
            rotation.repeatCount = .infinity
            synIcon.layer.add(rotation, forKey: "bxs_swf_synIconAnimationKey")
            syncLabel.text = "Stop"
        } else {
            syncLabel.text = "Sync"
        }
    }
    
    @objc private func clearButtonPressed() {
        delegate?.clearMotionTriggerCountButtonPressed()
    }
    
    //MARK: - Lazy
    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var syncButton: UIButton = {
        let button = UIButton()
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
    
    private lazy var dataLabel: UILabel = {
        let label = UILabel()
        label.textColor = Color.defaultText
        label.textAlignment = .left
        label.font = Font.MKFont(12.0)
        label.text = "X-axis:N/A;Y-axis:N/A;Z-axis:N/A"
        return label
    }()
    
    private lazy var bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var mtCountLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(text: "Motion trigger count")
    }()
    
    private lazy var mtCountValueLabel: UILabel = {
        let label = UILabel()
        label.textColor = Color.defaultText
        label.textAlignment = .center
        label.font = Font.MKFont(12.0)
        label.text = "0"
        return label
    }()
    
    private lazy var clearButton: UIButton = {
        let button = UIButton()
        button.setTitle("Clear", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = Font.MKFont(15.0)
        button.addTarget(self, action: #selector(clearButtonPressed), for: .touchUpInside)
        return button
    }()
}
