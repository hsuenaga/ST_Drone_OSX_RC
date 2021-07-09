//
//  ContentView.swift
//  ST_Drone_OSX_RC
//
//  Created by SUENAGA Hiroki on 2021/07/08.
//

import SwiftUI
import STDroneOSX

struct ValueView: View {
    var label = ""
    var value = ""

    init(label: String, value: UInt16) {
        self.label = label
        self.value = String(value)
    }

    init(label: String, value: UInt32) {
        self.label = label
        self.value = String(value)
    }

    init(label: String, value: Int16) {
        self.label = label
        self.value = String(value)
    }

    init(label: String, value: Int32) {
        self.label = label
        self.value = String(value)
    }

    init(label: String, value: Bool) {
        self.label = label
        self.value = value ? "YES" : "NO"
    }

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
        }
    }
}

struct EnvironmentView: View {
    var environment:W2STTelemetry.W2STEnvironment

    init(environment:W2STTelemetry.W2STEnvironment) {
        self.environment = environment
    }

    var body: some View {
        ValueView(label: "Tick", value: environment.tick)
        ValueView(label: "Pressure", value:environment.pressure)
        ValueView(label: "Battery", value:environment.battery)
        ValueView(label: "Temprature", value: environment.temprature)
        ValueView(label: "RSSI", value:environment.RSSI)
    }
}

struct AHRSView: View {
    var ahrs:W2STTelemetry.W2STAHRS

    init(ahrs:W2STTelemetry.W2STAHRS) {
        self.ahrs = ahrs
    }

    var body: some View {
        ValueView(label: "Tick", value:ahrs.tick)
        ValueView(label: "Acceleration.X", value: ahrs.acceleration.x)
        ValueView(label: "Acceleration.Y", value: ahrs.acceleration.y)
        ValueView(label: "Acceleration.Z", value: ahrs.acceleration.z)
        ValueView(label: "Gyrometer.X", value: ahrs.gyrometer.x)
        ValueView(label: "Gyrometer.Y", value: ahrs.gyrometer.y)
        ValueView(label: "Gyrometer.Z", value: ahrs.gyrometer.z)
        ValueView(label: "Axis.X", value: ahrs.axis.x)
        ValueView(label: "Axis.Y", value: ahrs.axis.y)
        ValueView(label: "Axis.Z", value: ahrs.axis.z)
    }
}

struct ArmingView: View {
    var arming:W2STTelemetry.W2STArming

    init(arming:W2STTelemetry.W2STArming) {
        self.arming = arming
    }

    var body: some View {
        ValueView(label: "Tick", value: arming.tick)
        ValueView(label: "Armed", value: arming.enabled)
    }
}

struct ContentView: View {
    @EnvironmentObject var model: W2STModel

    var body: some View {
        VStack {
            Text("Telemetry Data").font(.title)
            HStack {
                Toggle(isOn: $model.enableConnect) {
                    Text(model.enableConnect ? "Connected": "Disconnected")
                }.toggleStyle(SwitchToggleStyle())
                Toggle(isOn: $model.calibrate) {
                    Text("Calibrate")
                }.disabled(!model.enableConnect)
            }
            Divider()
            ArmingView(arming: model.telemetry.arming)
            Divider()
            EnvironmentView(environment:model.telemetry.environment)
            Divider()
            AHRSView(ahrs:model.telemetry.AHRS)
            Divider()
        }.padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(W2STModel())
    }
}
