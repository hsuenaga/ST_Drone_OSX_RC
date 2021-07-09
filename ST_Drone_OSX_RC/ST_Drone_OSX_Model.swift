//
//  ST_Drone_OSX_Model.swift
//  ST_Drone_OSX_RC
//
//  Created by SUENAGA Hiroki on 2021/07/08.
//

import Foundation
import Combine
import STDroneOSX

final class W2STModel: ObservableObject {
    let central:STDroneCentralManager = STDroneCentralManager()
    var peripheral:STDronePeripheral?
    var controlData: Data = Data.init(count: 7)
    @Published var telemetry: W2STTelemetry = W2STTelemetry()
    @Published var rudder: UInt8 = 128 {
        didSet {
            updateControlData()
        }
    }
    @Published var throttle: UInt8 = 0 {
        didSet {
            updateControlData()
        }
    }
    @Published var aileron: UInt8 = 128 {
        didSet {
            updateControlData()
        }
    }
    @Published var elevator: UInt8 = 128 {
        didSet {
            updateControlData()
        }
    }
    @Published var takeoff: Bool = false {
        didSet {
            updateControlData()
        }
    }
    @Published var calibrate: Bool = false {
        didSet {
            updateControlData()
        }
    }
    @Published var arm: Bool = false {
        didSet {
            updateControlData()
        }
    }
    @Published var enableConnect: Bool = false {
        didSet {
            if enableConnect {
                if let peripheral = self.peripheral {
                    connectPeripheral(peripheral)
                    return
                }
                print("start scanning")
                central.start {devices in
                    print("got peripheral list")
                    self.peripheral = devices[0]
                    self.connectPeripheral(self.peripheral!)
                }
            }
            else {
                if self.peripheral != nil {
                    self.peripheral?.disconnect()
                }
                print("disconnected")
            }
        }
    }

    private func connectPeripheral(_ peripheral: STDronePeripheral) {
        peripheral.connect {error in
            if error != nil {
                self.enableConnect = false
                return
            }
            peripheral.discoverAll() {
                peripheral.onUpdate {telemetry in
                    self.telemetry = telemetry
                }
            }
        }
    }

    private func updateControlData() {
        if enableConnect {
            guard let peripheral = self.peripheral else {
                print("No peripheral found.")
                return
            }
            controlData[0] = 0 // not used
            controlData[1] = rudder
            controlData[2] = throttle
            controlData[3] = aileron
            controlData[4] = elevator
            controlData[5] = 0 // not used
            controlData[6] = 0 // flags. see below.
            if takeoff {
                controlData[6] |= 0x01
            }
            if calibrate {
                controlData[6] |= 0x01 << 1
            }
            if arm {
                controlData[6] |= 0x01 << 2
            }
            print("send controlData")
            peripheral.writeJoydata(data: controlData)
        }
    }
}
