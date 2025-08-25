//
//  MKSFBXSScanDeviceInfoCell.swift
//  MKSwiftBXPSeriesSlathf
//
//  Created by aa on 2025/6/28.
//

import UIKit
import CoreBluetooth
import SnapKit
import MKBaseSwiftModule

protocol MKSFBXSScanDeviceInfoCellDelegate: AnyObject {
    func mk_bxs_swf_connectPeripheral(_ dataModel: MKSFBXSScanInfoCellModel)
}

class MKSFBXSScanDeviceInfoCell: MKSwiftBaseCell {
    
    // MARK: - Properties
    
    weak var delegate: MKSFBXSScanDeviceInfoCellDelegate?
    
    var dataModel: MKSFBXSScanInfoCellModel? {
        didSet {
            updateContent()
        }
    }
    
    // MARK: - Public Methods
    class func initCell(with tableView: UITableView) -> MKSFBXSScanDeviceInfoCell {
        let identifier = "MKSFBXSScanDeviceInfoCellIdenty"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKSFBXSScanDeviceInfoCell
        if cell == nil {
            cell = MKSFBXSScanDeviceInfoCell(style: .default, reuseIdentifier: identifier)
        }
        return cell!
    }
    
    // MARK: - Constants
    
    private let offsetX: CGFloat = 15
    private let rssiIconWidth: CGFloat = 22
    private let rssiIconHeight: CGFloat = 11
    private let connectButtonWidth: CGFloat = 80
    private let connectButtonHeight: CGFloat = 30
    private let batteryIconWidth: CGFloat = 25
    private let batteryIconHeight: CGFloat = 25
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
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
        contentView.addSubview(topBackView)
        contentView.addSubview(centerBackView)
        contentView.addSubview(bottomBackView)
        
        topBackView.addSubview(rssiIcon)
        topBackView.addSubview(rssiLabel)
        topBackView.addSubview(nameLabel)
        topBackView.addSubview(connectButton)
        
        bottomBackView.addSubview(devieIDLabel)
        bottomBackView.addSubview(macLabel)
        centerBackView.addSubview(batteryIcon)
        
        bottomBackView.addSubview(batteryLabel)
        bottomBackView.addSubview(timeLabel)
        
        layer.masksToBounds = true
        layer.cornerRadius = 4
    }
    
    private func setupConstraints() {
        topBackView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(40)
        }
        
        rssiIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(10)
            make.width.equalTo(rssiIconWidth)
            make.height.equalTo(rssiIconHeight)
        }
        
        rssiLabel.snp.makeConstraints { make in
            make.centerX.equalTo(rssiIcon)
            make.width.equalTo(40)
            make.top.equalTo(rssiIcon.snp.bottom).offset(5)
            make.height.equalTo(UIFont.systemFont(ofSize: 10).lineHeight)
        }
        
        connectButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-offsetX)
            make.width.equalTo(connectButtonWidth)
            make.centerY.equalToSuperview()
            make.height.equalTo(connectButtonHeight)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(rssiIcon.snp.right).offset(20)
            make.centerY.equalTo(rssiIcon)
            make.right.equalTo(connectButton.snp.left).offset(-8)
        }
        
        centerBackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(topBackView.snp.bottom)
            make.height.equalTo(batteryIconHeight)
        }
        
        batteryIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(offsetX)
            make.width.equalTo(batteryIconWidth)
            make.centerY.equalToSuperview()
            make.height.equalTo(batteryIconHeight)
        }
        
        macLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.right.equalTo(timeLabel.snp.left).offset(-5)
            make.bottom.equalTo(batteryIcon.snp.centerY).offset(2)
            make.height.equalTo(UIFont.systemFont(ofSize: 12).lineHeight)
        }
        
        devieIDLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.right.equalTo(timeLabel.snp.left).offset(-5)
            make.top.equalTo(batteryIcon.snp.centerY).offset(2)
            make.height.equalTo(UIFont.systemFont(ofSize: 12).lineHeight)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-15)
            make.width.equalTo(70)
            make.centerY.equalTo(devieIDLabel)
            make.height.equalTo(UIFont.systemFont(ofSize: 10).lineHeight)
        }
        
        bottomBackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(centerBackView.snp.bottom)
            make.bottom.equalToSuperview()
        }
        
        batteryLabel.snp.makeConstraints { make in
            make.centerX.equalTo(batteryIcon)
            make.width.equalTo(45)
            make.top.equalToSuperview().offset(3)
            make.height.equalTo(UIFont.systemFont(ofSize: 15).lineHeight)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createLabel(font: UIFont) -> UILabel {
        let label = UILabel()
        label.textColor = Color.rgb(184, 184, 184)
        label.textAlignment = .left
        label.font = font
        return label
    }
    
    private func updateContent() {
        guard let dataModel = dataModel else { return }
        
        connectButton.isHidden = !dataModel.connectEnable
        timeLabel.text = dataModel.displayTime
        rssiLabel.text = "\(dataModel.rssi)dBm"
        nameLabel.text = (dataModel.deviceName.count == 0 ? "N/A" : dataModel.deviceName)
        
        if dataModel.battery.count > 0  {
            if let batteryInt = Int(dataModel.battery), batteryInt <= 100 {
                batteryLabel.text = "\(dataModel.battery)%"
            } else {
                batteryLabel.text = "\(dataModel.battery)mV"
            }
        } else {
            batteryLabel.text = "N/A"
        }
        
        if dataModel.tagID.count > 0 {
            devieIDLabel.text = "Tag ID:0x\(dataModel.tagID)"
        } else {
            devieIDLabel.text = ""
        }
        
        if dataModel.macAddress.count > 0 {
            macLabel.text = "MAC: \(dataModel.macAddress)"
        } else {
            macLabel.text = ""
        }
        
        setNeedsLayout()
    }
    
    // MARK: - Actions
    
    @objc private func connectButtonPressed() {
        guard let dataModel = dataModel, let _ = dataModel.peripheral else { return }
        delegate?.mk_bxs_swf_connectPeripheral(dataModel)
    }
    
    // MARK: - UI Components
    
    private lazy var topBackView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var centerBackView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var bottomBackView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var rssiIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = moduleIcon(name: "bxs_swf_signalIcon", in: .module)
        return imageView
    }()
    
    private lazy var rssiLabel: UILabel = {
        let label = createLabel(font: Font.MKFont(10.0))
        label.textAlignment = .center
        return label
    }()
    
    private lazy var nameLabel: UILabel = {
        return MKSwiftUIAdaptor.createNormalLabel()
    }()
    
    private lazy var connectButton: UIButton = {
        return MKSwiftUIAdaptor.createRoundedButton(title: "CONNECT",
                                                    target: self,
                                                    action: #selector(connectButtonPressed))
    }()
    
    private lazy var batteryIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = moduleIcon(name: "bxs_swf_batteryHighest", in: .module)
        return imageView
    }()
    
    private lazy var batteryLabel: UILabel = {
        let label = createLabel(font: Font.MKFont(10.0))
        label.textAlignment = .center
        return label
    }()
    
    private lazy var macLabel: UILabel = {
        return createLabel(font: Font.MKFont(12.0))
    }()
    
    private lazy var devieIDLabel: UILabel = {
        return createLabel(font: Font.MKFont(12.0))
    }()
    
    private lazy var timeLabel: UILabel = {
        let label = createLabel(font: Font.MKFont(10.0))
        label.textAlignment = .center
        return label
    }()
}
