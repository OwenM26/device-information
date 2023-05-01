//
//  DeviceViewModel.swift
//  Device
//
//  Created by Owen Moore on 01/05/2023.
//

import Foundation
import DataLayer
import DomainLayer
import Combine

final class DeviceViewModel: ObservableObject {
    
    @Published private(set) var deviceInformation: DomainLayer.DeviceInformation?
    @Published private(set) var deviceSupport: DomainLayer.DeviceSupport?
    @Published private(set) var batteryLevel: String?
    @Published private(set) var batteryState: DomainLayer.BatteryState?
    @Published private(set) var batteryLowPowerMode: DomainLayer.BatteryLowPowerMode?
    
    private var cancellables = Set<AnyCancellable>()
    
    private let calendar: Calendar
    private let deviceService: DeviceService
    
    init(
        calendar: Calendar = .current,
        deviceService: DeviceService = DeviceServiceImpl(
            uiDevice: .current,
            device: .current,
            processInformation: .processInfo,
            notificationCenter: .default
        )
    ) {
        self.calendar = calendar
        self.deviceService = deviceService
        
        fetchDeviceInformation()
        fetchDeviceSupport()
        fetchBatteryLevel()
        fetchBatteryState()
        fetchBatteryLowPowerMode()
    }
    
    private func fetchDeviceInformation() {
        deviceService
            .deviceInformation()
            .map {
                DomainLayer.DeviceInformation(
                    name: $0.name,
                    os: $0.os,
                    cpu: .init(
                        processor: $0.cpu.processor,
                        architecture: $0.cpu.architecture.uppercased()
                    ),
                    thermalState: self.mapToThermalState($0.thermalState),
                    uptime: self.mapDateToUptime(Date(timeIntervalSince1970: $0.uptime)),
                    lastReboot: Date() - $0.uptime
                )
            }
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in
                deviceInformation = $0
            }
            .store(in: &cancellables)
    }
    
    private func fetchDeviceSupport() {
        deviceService
            .deviceSupport()
            .map {
                DomainLayer.DeviceSupport(
                    applePencil: self.mapToApplePencilSupport($0.applePencil),
                    wirelessCharging: self.mapToSupport($0.wirelessCharging),
                    touchID: self.mapToSupport($0.touchID),
                    faceID: self.mapToSupport($0.faceID),
                    display: .init(
                        zoomed: self.mapToSupport($0.display.zoomed),
                        diagonal: "\($0.display.diagonal)\"",
                        roundedCorners: self.mapToSupport($0.display.roundedCorners),
                        ppi: "\($0.display.ppi) ppi",
                        has3dTouch: self.mapToSupport($0.display.has3dTouch)
                    ),
                    camera: .init(
                        lidarSensor: self.mapToSupport($0.camera.lidarSensor),
                        telephoto: self.mapToSupport($0.camera.telephoto),
                        wide: self.mapToSupport($0.camera.wide),
                        ultraWide: self.mapToSupport($0.camera.ultraWide),
                        torch: self.mapToSupport($0.camera.torch)
                    )
                )
            }
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in
                deviceSupport = $0
            }
            .store(in: &cancellables)
    }
    
    private func fetchBatteryLevel() {
        deviceService
            .batteryLevel()
            .map { "\($0 ?? 0)%" }
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in
                batteryLevel = $0
            }
            .store(in: &cancellables)
    }
    
    private func fetchBatteryState() {
        deviceService
            .batteryState()
            .map {
                self.mapToBatteryState($0)
            }
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in
                batteryState = $0
            }
            .store(in: &cancellables)
    }
    
    private func fetchBatteryLowPowerMode() {
        deviceService
            .batteryLowPowerMode()
            .map {
                self.mapToBatteryLowPowerModel($0)
            }
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in
                batteryLowPowerMode = $0
            }
            .store(in: &cancellables)
    }
    
}

extension DeviceViewModel {
    
    private func mapToApplePencilSupport(_ support: DataLayer.DeviceSupport.ApplePencilSupport) -> DomainLayer.DeviceSupport.ApplePencilSupport {
        switch support {
        case .firstGen:
            return DomainLayer.DeviceSupport.ApplePencilSupport.firstGen
        case .secondGen:
            return DomainLayer.DeviceSupport.ApplePencilSupport.secondGen
        case .none:
            return DomainLayer.DeviceSupport.ApplePencilSupport.none
        }
    }
    
    private func mapToThermalState(_ state: DataLayer.DeviceInformation.ThermalState) -> DomainLayer.DeviceInformation.ThermalState {
        switch state {
        case .nominal:
            return .normal
        case .fair:
            return .fair
        case .serious:
            return .serious
        case .critical:
            return .critical
        }
    }
    
    private func mapToSupport(_ value: Bool) -> Support {
        return value ? .yes : .no
    }
    
    private func mapDateToUptime(_ date: Date) -> String {
        let time = calendar.dateComponents([.day, .hour, .minute, .second], from: date)
        
        return "\(time.day ?? 0)d \(time.hour ?? 0)h \(time.minute ?? 0)m"
    }
    
    private func mapToBatteryState(_ state: DataLayer.BatteryState) -> DomainLayer.BatteryState {
        switch state {
        case .full:
            return .full
        case .charging:
            return .charging
        case .unplugged:
            return .unplugged
        case .none:
            return .unplugged
        }
    }
    
    private func mapToBatteryLowPowerModel(_ state: DataLayer.BatteryLowPowerMode) -> DomainLayer.BatteryLowPowerMode {
        switch state {
        case .on:
            return .on
        case .off:
            return .off
        }
    }
    
}
