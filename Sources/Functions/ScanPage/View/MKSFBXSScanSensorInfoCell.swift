//
//  MKSFBXSScanSensorInfoCell.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/6/27.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftBeaconXCustomUI

class MKSFBXSScanSensorInfoCellModel: MKSwiftBXScanBaseModel {
    var magneticStatus: Bool = false
    var magneticCount: String = ""
    var triaxialSensor: Bool = false
    var motionStatus: Bool = false
    var motionCount: String = ""
    var xData: String = ""
    var yData: String = ""
    var zData: String = ""
    var supportTemp: Bool = false
    var temperature: String = ""
    var supportHumidity: Bool = false
    var humidity: String = ""
    
    func fetchCellHeight() -> CGFloat {
        if triaxialSensor {
            //支持三轴
            if supportTemp && supportHumidity {
                //支持温湿度
                return 170
            }
            if (supportTemp && !supportHumidity) || (!supportTemp && supportHumidity) {
                //支持温度或者湿度
                return 155
            }
            //不支持温湿度
            return 130
        }
        //不支持三轴
        if supportTemp && supportHumidity {
            //支持温湿度
            return 110
        }
        if (supportTemp && !supportHumidity) || (!supportTemp && supportHumidity) {
            //支持温度或者湿度
            return 115
        }
        //都不支持
        return 70
    }
    
    override init() {}
}

class MKSFBXSScanSensorInfoCell: MKSwiftBaseCell {
    var dataModel: MKSFBXSScanSensorInfoCellModel? {
        didSet {
            updateContent()
        }
    }
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    class func initCell(with tableView: UITableView) -> MKSFBXSScanSensorInfoCell {
        let identifier = "MKSFBXSScanSensorInfoCellIdenty"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKSFBXSScanSensorInfoCell
        if cell == nil {
            cell = MKSFBXSScanSensorInfoCell(style: .default, reuseIdentifier: identifier)
        }
        return cell!
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupConstraints()
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        contentView.addSubview(icon)
        contentView.addSubview(msgLabel)
        contentView.addSubview(msLabel)
        contentView.addSubview(msValueLabel)
        contentView.addSubview(mtcLabel)
        contentView.addSubview(mtcValueLabel)
        contentView.addSubview(humidityLabel)
        contentView.addSubview(humidityValueLabel)
    }
    
    private func setupConstraints() {
        icon.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(7)
            make.centerY.equalTo(msgLabel)
            make.height.equalTo(7)
        }
        
        msgLabel.snp.remakeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(2)
            make.right.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(10)
            make.height.equalTo(18) // Approximate line height for 15pt font
        }
        
        msLabel.snp.remakeConstraints { make in
            make.left.equalTo(msgLabel)
            make.right.equalTo(contentView.snp.centerX).offset(-2)
            make.top.equalTo(msgLabel.snp.bottom).offset(5)
            make.height.equalTo(14) // Approximate line height for 12pt font
        }
        
        msValueLabel.snp.remakeConstraints { make in
            make.left.equalTo(contentView.snp.centerX)
            make.right.equalToSuperview().offset(-15)
            make.centerY.equalTo(msLabel)
            make.height.equalTo(msLabel)
        }
        
        mtcLabel.snp.remakeConstraints { make in
            make.left.equalTo(msgLabel)
            make.right.equalTo(contentView.snp.centerX).offset(-2)
            make.top.equalTo(msLabel.snp.bottom).offset(5)
            make.height.equalTo(msLabel)
        }
        
        mtcValueLabel.snp.remakeConstraints { make in
            make.left.equalTo(contentView.snp.centerX)
            make.right.equalToSuperview().offset(-15)
            make.centerY.equalTo(mtcLabel)
            make.height.equalTo(mtcLabel)
        }
    }
    
    private func createLabel(text: String = "") -> UILabel {
        let label = UILabel()
        label.textColor = Color.rgb(184, 184, 184)
        label.textAlignment = .left
        label.font = Font.MKFont(12.0)
        label.text = text
        return label
    }
    
    private func updateContent() {
        guard let dataModel = dataModel else { return }
        
        msValueLabel.text = dataModel.magneticStatus ? "Open" : "Closed"
        mtcValueLabel.text = dataModel.magneticCount
        
        setupTriaxialSensor()
        setupTemperatureSensor()
        setupHumiditySensor()
    }
    
    private func setupTriaxialSensor() {
        guard let dataModel = dataModel else { return }
        
        [mosLabel, mosValueLabel, motcLabel, motcValueLabel, accLabel, accValueLabel].forEach {
            $0.removeFromSuperview()
        }
        
        if !dataModel.triaxialSensor { return }
        
        contentView.addSubview(mosLabel)
        contentView.addSubview(mosValueLabel)
        contentView.addSubview(motcLabel)
        contentView.addSubview(motcValueLabel)
        contentView.addSubview(accLabel)
        contentView.addSubview(accValueLabel)
        
        mosLabel.snp.remakeConstraints { make in
            make.left.equalTo(msgLabel)
            make.right.equalTo(contentView.snp.centerX).offset(-2)
            make.top.equalTo(mtcLabel.snp.bottom).offset(5)
            make.height.equalTo(msLabel)
        }
        
        mosValueLabel.snp.remakeConstraints { make in
            make.left.equalTo(contentView.snp.centerX)
            make.right.equalToSuperview().offset(-15)
            make.centerY.equalTo(mosLabel)
            make.height.equalTo(mosLabel)
        }
        
        motcLabel.snp.remakeConstraints { make in
            make.left.equalTo(msgLabel)
            make.right.equalTo(contentView.snp.centerX).offset(-2)
            make.top.equalTo(mosLabel.snp.bottom).offset(5)
            make.height.equalTo(msLabel)
        }
        
        motcValueLabel.snp.remakeConstraints { make in
            make.left.equalTo(contentView.snp.centerX)
            make.right.equalToSuperview().offset(-15)
            make.centerY.equalTo(motcLabel)
            make.height.equalTo(motcLabel)
        }
        
        accLabel.snp.remakeConstraints { make in
            make.left.equalTo(msgLabel)
            make.right.equalTo(contentView.snp.centerX).offset(-2)
            make.top.equalTo(motcLabel.snp.bottom).offset(5)
            make.height.equalTo(msLabel)
        }
        
        accValueLabel.snp.remakeConstraints { make in
            make.left.equalTo(contentView.snp.centerX)
            make.right.equalToSuperview().offset(-15)
            make.centerY.equalTo(accLabel)
            make.height.equalTo(accLabel)
        }
        
        mosValueLabel.text = dataModel.motionStatus ? "Moving" : "Stationary"
        motcValueLabel.text = dataModel.motionCount
        accValueLabel.text = "X: \(dataModel.xData)mg;Y: \(dataModel.yData)mg;Z: \(dataModel.zData)mg"
    }
    
    private func setupTemperatureSensor() {
        guard let dataModel = dataModel else { return }
        
        [tempLabel, tempValueLabel].forEach { $0.removeFromSuperview() }
        
        if !dataModel.supportTemp { return }
        
        contentView.addSubview(tempLabel)
        contentView.addSubview(tempValueLabel)
        
        tempValueLabel.text = "\(dataModel.temperature)℃"
        
        if !dataModel.triaxialSensor {
            //不支持三轴
            tempLabel.snp.remakeConstraints { make in
                make.left.equalTo(msgLabel)
                make.right.equalTo(contentView.snp.centerX).offset(-2)
                make.top.equalTo(mtcLabel.snp.bottom).offset(5)
                make.height.equalTo(msLabel)
            }
            
            tempValueLabel.snp.remakeConstraints { make in
                make.left.equalTo(contentView.snp.centerX)
                make.right.equalToSuperview().offset(-15)
                make.centerY.equalTo(tempLabel)
                make.height.equalTo(tempLabel)
            }
        } else {
            //带三轴
            tempLabel.snp.remakeConstraints { make in
                make.left.equalTo(msgLabel)
                make.right.equalTo(contentView.snp.centerX).offset(-2)
                make.top.equalTo(accLabel.snp.bottom).offset(5)
                make.height.equalTo(msLabel)
            }
            
            tempValueLabel.snp.remakeConstraints { make in
                make.left.equalTo(contentView.snp.centerX)
                make.right.equalToSuperview().offset(-15)
                make.centerY.equalTo(tempLabel)
                make.height.equalTo(tempLabel)
            }
        }
    }
    
    private func setupHumiditySensor() {
        guard let dataModel = dataModel else { return }
        
        [humidityLabel, humidityValueLabel].forEach { $0.removeFromSuperview() }
        
        if !dataModel.supportHumidity { return }
        
        contentView.addSubview(humidityLabel)
        contentView.addSubview(humidityValueLabel)
        
        humidityValueLabel.text = "\(dataModel.humidity)%RH"
        
        if dataModel.supportTemp {
            //支持温度
            humidityLabel.snp.remakeConstraints { make in
                make.left.equalTo(msgLabel)
                make.right.equalTo(contentView.snp.centerX).offset(-2)
                make.top.equalTo(tempLabel.snp.bottom).offset(5)
                make.height.equalTo(msLabel)
            }
            
            humidityValueLabel.snp.remakeConstraints { make in
                make.left.equalTo(contentView.snp.centerX)
                make.right.equalToSuperview().offset(-15)
                make.centerY.equalTo(humidityLabel)
                make.height.equalTo(humidityLabel)
            }
        } else if !dataModel.triaxialSensor {
            //不支持三轴
            humidityLabel.snp.remakeConstraints { make in
                make.left.equalTo(msgLabel)
                make.right.equalTo(contentView.snp.centerX).offset(-2)
                make.top.equalTo(mtcLabel.snp.bottom).offset(5)
                make.height.equalTo(msLabel)
            }
            
            humidityValueLabel.snp.remakeConstraints { make in
                make.left.equalTo(contentView.snp.centerX)
                make.right.equalToSuperview().offset(-15)
                make.centerY.equalTo(humidityLabel)
                make.height.equalTo(humidityLabel)
            }
        } else if dataModel.triaxialSensor {
            //支持三轴
            humidityLabel.snp.remakeConstraints { make in
                make.left.equalTo(msgLabel)
                make.right.equalTo(contentView.snp.centerX).offset(-2)
                make.top.equalTo(accLabel.snp.bottom).offset(5)
                make.height.equalTo(msLabel)
            }
            
            humidityValueLabel.snp.remakeConstraints { make in
                make.left.equalTo(contentView.snp.centerX)
                make.right.equalToSuperview().offset(-15)
                make.centerY.equalTo(humidityLabel)
                make.height.equalTo(humidityLabel)
            }
        }
    }
    
    // MARK: - UI Components
    private lazy var icon: UIImageView = {
        let view = UIImageView()
        view.image = moduleIcon(name: "bxs_swf_littleBluePoint", in: .module)
        return view
    }()
    
    private lazy var msgLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel(text: "Sensor info")
    }()
    
    private lazy var msLabel: UILabel = createLabel(text: "Door magnetic status")
    private lazy var msValueLabel: UILabel = createLabel()
    private lazy var mtcLabel: UILabel = createLabel(text: "Magnetic trigger count")
    private lazy var mtcValueLabel: UILabel = createLabel()
    private lazy var mosLabel: UILabel = createLabel(text: "Motion status")
    private lazy var mosValueLabel: UILabel = createLabel()
    private lazy var motcLabel: UILabel = createLabel(text: "Motion trigger count")
    private lazy var motcValueLabel: UILabel = createLabel()
    private lazy var accLabel: UILabel = createLabel(text: "Acceleration")
    private lazy var accValueLabel: UILabel = createLabel()
    private lazy var tempLabel: UILabel = createLabel(text: "Temperature")
    private lazy var tempValueLabel: UILabel = createLabel()
    private lazy var humidityLabel: UILabel = createLabel(text: "Humidity")
    private lazy var humidityValueLabel: UILabel = createLabel()
}
