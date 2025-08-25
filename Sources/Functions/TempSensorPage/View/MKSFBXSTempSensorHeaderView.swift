//
//  MKSFBXSTempSensorHeaderView.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/21.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSTempSensorHeaderViewModel {
    var temperature: String = ""
    var interval: String = ""
}

protocol MKSFBXSTempSensorHeaderViewDelegate: AnyObject {
    func bxs_swf_thSensorHeaderView_samplingIntervalChanged(interval: String)
}

class MKSFBXSTempSensorHeaderView: UIView {
    
    // MARK: - Properties
    var dataModel: MKSFBXSTempSensorHeaderViewModel? {
        didSet {
            guard let model = dataModel else { return }
            tempView.valueLabel.text = model.temperature
            textField.text = model.interval
        }
    }
    
    weak var delegate: MKSFBXSTempSensorHeaderViewDelegate?
    
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
        setupConstraints()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        addSubview(backView)
        backView.addSubview(msgLabel)
        backView.addSubview(tempView)
        backView.addSubview(samplingLabel)
        backView.addSubview(textField)
        backView.addSubview(unitLabel)
    }
    
    private func setupConstraints() {
        backView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(5)
            make.right.equalToSuperview().offset(-5)
            make.top.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-10)
        }
        
        msgLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(10)
            make.height.equalTo(30)
        }
        
        tempView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.top.equalTo(msgLabel.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
        
        samplingLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(45)
            make.width.equalTo(110)
            make.centerY.equalTo(textField)
            make.height.equalTo(UIFont.systemFont(ofSize: 13).lineHeight)
        }
        
        textField.snp.makeConstraints { make in
            make.left.equalTo(samplingLabel.snp.right).offset(5)
            make.width.equalTo(65)
            make.top.equalTo(tempView.snp.bottom).offset(10)
            make.height.equalTo(20)
        }
        
        unitLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-10)
            make.left.equalTo(textField.snp.right).offset(3)
            make.centerY.equalTo(textField)
            make.height.equalTo(UIFont.systemFont(ofSize: 13).lineHeight)
        }
    }
    
    // MARK: - UI Components
    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()
    
    private lazy var msgLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(text: "Real-time data")
    }()
    
    private lazy var tempView: MKSFBXSTempConfigValueView = {
        let tempView = MKSFBXSTempConfigValueView()
        tempView.leftIcon.image = moduleIcon(name: "bxs_swf_slotConfig_temperatureIcon", in: .module)
        tempView.msgLabel.text = "Temperature"
        tempView.valueLabel.text = "0.0"
        tempView.unitLabel.text = "℃"
        return tempView
    }()
    
    private lazy var samplingLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(13.0), text: "Sampling interval")
    }()
    
    private lazy var textField: MKSwiftTextField = {
        let field = MKSwiftTextField(textFieldType: .realNumberOnly)
        field.textColor = Color.defaultText
        field.textAlignment = .center
        field.font = Font.MKFont(12.0)
        field.borderStyle = .none
        field.text = "1"
        field.maxLength = 5
        field.placeholder = "1~65535"
        
        let lineView = UIView()
        lineView.backgroundColor = Color.defaultText
        field.addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        
        field.textChangedBlock = { [weak self] text in
            guard let self = self else { return }
            self.delegate?.bxs_swf_thSensorHeaderView_samplingIntervalChanged(interval: text)
        }
        
        return field
    }()
    
    private lazy var unitLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.attributedText = MKSwiftUIAdaptor.createAttributedString(strings: ["sec", "   (1 ~ 65535)"], fonts: [Font.MKFont(13.0),Font.MKFont(12.0)], colors: [Color.defaultText,Color.rgb(223, 223, 223)])
        
        return label
    }()
}

private class MKSFBXSTempConfigValueView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupConstraints()
    }
    
    private func setupUI() {
        addSubview(leftIcon)
        addSubview(msgLabel)
        addSubview(valueLabel)
        addSubview(unitLabel)
    }
    
    private func setupConstraints() {
        leftIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(5)
            make.width.equalTo(25)
            make.centerY.equalToSuperview()
            make.height.equalTo(25)
        }
        
        msgLabel.snp.makeConstraints { make in
            make.left.equalTo(leftIcon.snp.right).offset(5)
            make.right.equalTo(valueLabel.snp.left).offset(-5)
            make.centerY.equalToSuperview()
            make.height.equalTo(UIFont.systemFont(ofSize: 15).lineHeight)
        }
        
        valueLabel.snp.makeConstraints { make in
            make.right.equalTo(unitLabel.snp.left).offset(-10)
            make.width.equalTo(85)
            make.centerY.equalToSuperview()
            make.height.equalTo(UIFont.systemFont(ofSize: 28).lineHeight)
        }
        
        unitLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-5)
            make.width.equalTo(30)
            make.bottom.equalTo(valueLabel.snp.bottom)
            make.height.equalTo(UIFont.systemFont(ofSize: 12).lineHeight)
        }
    }
    // MARK: - UI Components
    lazy var leftIcon: UIImageView = {
        return UIImageView()
    }()
    lazy var msgLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel()
    }()
    lazy var valueLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(28.0))
    }()
    lazy var unitLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(12.0))
    }()
}
