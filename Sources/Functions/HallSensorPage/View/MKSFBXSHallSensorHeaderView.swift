//
//  MKSFBXSHallSensorHeaderView.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/19.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSHallSensorHeaderViewModel {
    var count: String = ""
}

protocol MKSFBXSHallSensorHeaderViewDelegate: AnyObject {
    func bxs_swf_hallSensorHeaderView_clearPressed()
}

class MKSFBXSHallSensorHeaderView: UIView {
    var dataModel: MKSFBXSHallSensorHeaderViewModel? {
        didSet {
            updateContent()
        }
    }
    
    weak var delegate: MKSFBXSHallSensorHeaderViewDelegate?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Color.rgb(242, 242, 242)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(5)
            make.right.equalToSuperview().offset(-5)
            make.top.equalToSuperview().offset(15)
            make.height.equalTo(44)
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
            make.height.equalTo(UIFont.systemFont(ofSize: 15).lineHeight)
        }
        
        mtCountValueLabel.snp.makeConstraints { make in
            make.left.equalTo(mtCountLabel.snp.right).offset(10)
            make.right.equalTo(clearButton.snp.left).offset(-5)
            make.centerY.equalToSuperview()
            make.height.equalTo(UIFont.systemFont(ofSize: 12).lineHeight)
        }
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        addSubview(backView)
        backView.addSubview(mtCountLabel)
        backView.addSubview(mtCountValueLabel)
        backView.addSubview(clearButton)
    }
    
    private func updateContent() {
        guard let model = dataModel else { return }
        mtCountValueLabel.text = model.count
    }
    
    @objc private func clearButtonPressed() {
        delegate?.bxs_swf_hallSensorHeaderView_clearPressed()
    }
    
    // MARK: - UI Components
    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
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
        return MKSwiftUIAdaptor.createRoundedButton(title: "Clear",target: self,action: #selector(clearButtonPressed))
    }()
}
