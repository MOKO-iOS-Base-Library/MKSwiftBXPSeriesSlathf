//
//  MKSFBXSTHSensorHeaderView.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/7/23.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

class MKSFBXSTHSensorHeaderViewModel {
    var temperature: String = "0.0"
    var humidity: String = "0.0"
    var interval: String = "0"
}

protocol MKSFBXSTHSensorHeaderViewDelegate: AnyObject {
    func bxs_swf_thSensorHeaderView_samplingIntervalChanged(interval: String)
}

class MKSFBXSTHSensorHeaderView: UIView {
    
    weak var delegate: MKSFBXSTHSensorHeaderViewDelegate?
    
    var dataModel: MKSFBXSTHSensorHeaderViewModel? {
        didSet {
            guard let dataModel = dataModel else { return }
            tempView.valueLabel.text = dataModel.temperature
            humidityView.valueLabel.text = dataModel.humidity
            textField.text = dataModel.interval
        }
    }
    
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
        
        humidityView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.top.equalTo(tempView.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
        
        samplingLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(45.0)
            make.width.lessThanOrEqualTo(110.0)
            make.centerY.equalTo(textField.snp.centerY)
            make.height.equalTo(Font.MKFont(13.0).lineHeight)
        }
        
        textField.snp.makeConstraints { make in
            make.left.equalTo(samplingLabel.snp.right).offset(5)
            make.width.equalTo(65)
            make.top.equalTo(humidityView.snp.bottom).offset(10)
            make.height.equalTo(20)
        }
        
        unitLabel.snp.makeConstraints { make in
            make.right.equalTo(-10.0)
            make.left.equalTo(textField.snp.right).offset(3.0)
            make.centerY.equalTo(textField.snp.centerY)
            make.height.equalTo(Font.MKFont(13.0).lineHeight)
        }
    }
    
    private func setupUI() {
        addSubview(backView)
        backView.addSubview(msgLabel)
        backView.addSubview(tempView)
        backView.addSubview(humidityView)
        backView.addSubview(samplingLabel)
        backView.addSubview(textField)
        backView.addSubview(unitLabel)
    }
    
    //MARK: - lazy
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
    
    private lazy var tempView: MKSFBXSHTConfigValueView = {
        let view = MKSFBXSHTConfigValueView()
        view.leftIcon.image = moduleIcon(name: "bxs_swf_slotConfig_temperatureIcon", in: .module)
        view.msgLabel.text = "Temperature"
        view.valueLabel.text = "0.0"
        view.unitLabel.text = "℃"
        return view
    }()
    
    private lazy var humidityView: MKSFBXSHTConfigValueView = {
        let view = MKSFBXSHTConfigValueView()
        view.leftIcon.image = moduleIcon(name: "bxs_swf_slotConfig_humidityIcon", in: .module)
        view.msgLabel.text = "Humidity"
        view.valueLabel.text = "0.0"
        view.unitLabel.text = "%RH"
        return view
    }()
    
    private lazy var samplingLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(font: Font.MKFont(13.0),text: "Sampling interval")
    }()
    
    private lazy var textField: MKSwiftTextField = {
        let textField = MKSwiftTextField.init(textFieldType: .realNumberOnly)
        textField.textColor = Color.defaultText
        textField.textAlignment = .center
        textField.font = Font.MKFont(12.0)
        textField.borderStyle = .none
        textField.text = "1"
        textField.maxLength = 5
        textField.placeholder = "1~65535"
        
        let lineView = UIView()
        lineView.backgroundColor = Color.defaultText
        textField.addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        
        textField.textChangedBlock = { [weak self] text in
            guard let self = self else { return }
            self.delegate?.bxs_swf_thSensorHeaderView_samplingIntervalChanged(interval: text)
        }
        
        return textField
    }()
    
    private lazy var unitLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.attributedText = MKSwiftUIAdaptor.createAttributedString(strings: ["sec", "   (1 ~ 65535)"], fonts: [Font.MKFont(13.0),Font.MKFont(12.0)], colors: [Color.defaultText,Color.rgb(223, 223, 223)])
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()
}

private class MKSFBXSHTConfigValueView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(leftIcon)
        addSubview(msgLabel)
        addSubview(valueLabel)
        addSubview(unitLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        leftIcon.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(5)
            make.width.equalTo(25)
            make.centerY.equalToSuperview()
            make.height.equalTo(25)
        }
        
        msgLabel.snp.remakeConstraints { make in
            make.left.equalTo(leftIcon.snp.right).offset(5)
            make.right.equalTo(valueLabel.snp.left).offset(-5.0)
            make.centerY.equalToSuperview()
            make.height.equalTo(Font.MKFont(15.0).lineHeight)
        }
        
        valueLabel.snp.remakeConstraints { make in
            make.right.equalTo(unitLabel.snp.left).offset(-10.0)
            make.width.equalTo(85.0)
            make.centerY.equalToSuperview()
            make.height.equalTo(Font.MKFont(28.0).lineHeight)
        }
        
        unitLabel.snp.remakeConstraints { make in
            make.right.equalToSuperview().offset(-5)
            make.width.equalTo(30.0)
            make.bottom.equalTo(valueLabel.snp.bottom)
            make.height.equalTo(Font.MKFont(12.0).lineHeight)
        }
    }
    
    //MARK: - lazy
    lazy var leftIcon: UIImageView = {
        let view = UIImageView()
        return view
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
