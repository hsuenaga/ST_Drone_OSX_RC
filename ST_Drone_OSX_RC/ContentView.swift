//
//  ContentView.swift
//  ST_Drone_OSX_RC
//
//  Created by SUENAGA Hiroki on 2021/07/08.
//

import SwiftUI
import STDroneOSX
import GameController

struct ValueView: View {
    var label = ""
    var value = ""

    init<T:BinaryInteger>(label: String, value: T) {
        self.label = label
        self.value = String(value)
    }

    init<T:BinaryInteger>(label: String, value:T, divider:Int) {
        let fvalue = Float(value) / Float(divider)

        self.label = label
        self.value = String(format:"%+04.3f", fvalue)
    }

    init(label: String, rad:Int16) {
        self.label = label
        self.value = String(Float(rad) / Float.pi * 180.0) // rad to degree.
    }

    init(label: String, value:Int16, FS:Int16) {
        self.label = label;
        let fvalue = Float(FS) / Float(Int16.max) * Float(value);
        self.value = String(format:"%+04.3f", fvalue)
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
        ValueView(label: "Pressure [hpa]", value:environment.pressure, divider: 100)
        ValueView(label: "Battery [%]", value:environment.battery, divider: 10)
        ValueView(label: "Temprature [C]", value: environment.temprature, divider: 10)
        ValueView(label: "RSSI [dbm]", value:environment.RSSI,
                  divider: 10)
    }
}

struct AHRSView: View {
    var ahrs:W2STTelemetry.W2STAHRS

    init(ahrs:W2STTelemetry.W2STAHRS) {
        self.ahrs = ahrs
    }

    var body: some View {
        ValueView(label: "Tick", value:ahrs.tick)
        ValueView(label: "Acceleration.X [g]", value: ahrs.acceleration.x, divider:1000)
        ValueView(label: "Acceleration.Y [g]", value: ahrs.acceleration.y, divider:1000)
        ValueView(label: "Acceleration.Z [g]", value: ahrs.acceleration.z, divider:1000)
        ValueView(label: "Gyrometer.X [dps]", value: ahrs.gyrometer.x, divider:1000)
        ValueView(label: "Gyrometer.Y [dps]", value: ahrs.gyrometer.y, divider:1000)
        ValueView(label: "Gyrometer.Z [dps]", value: ahrs.gyrometer.z, divider:1000)
        ValueView(label: "Magneto.X [gauss]", value: ahrs.mag.x, divider:1000)
        ValueView(label: "Magneto.Y [gauss]", value: ahrs.mag.y, divider:1000)
        ValueView(label: "Magneto.Z [gauss]", value: ahrs.mag.z, divider:1000)
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

struct GCView: View {
    @EnvironmentObject var model: W2STModel

    var body: some View {
        VStack {
            Text("Controller").font(.title)
            Text(model.controllerName)
            Divider()
            ValueView(label: "Ailron", value: model.aileron)
            ValueView(label: "Elevator", value: model.elevator)
            ValueView(label: "Throttle", value: model.throttle)
            ValueView(label: "Rudder", value: model.rudder)
            ValueView(label: "Armed", value: model.arm)
            ValueView(label: "Calibrate", value: model.calibrate)
            Spacer()
        }
    }
}

struct TelemetryView: View {
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
			Toggle(isOn: $model.arm) {
			    Text("Armed")
			}.disabled(!model.enableConnect)
		    }
		    Text(model.peripheral?.identifier.uuidString ?? "NO Drone ID")
		    Divider()
		    ArmingView(arming: model.telemetry.arming)

		    Divider()
		    EnvironmentView(environment:model.telemetry.environment)

		    Divider()
		    AHRSView(ahrs:model.telemetry.AHRS)
		    Spacer()
		}
	}
}

struct ConsoleView: View {
	@EnvironmentObject var model:W2STModel

	var body: some View {
		VStack {
			Divider()
			Text("STDOUT").font(.title)
			Divider()
			ScrollView(/*@START_MENU_TOKEN@*/.vertical/*@END_MENU_TOKEN@*/, showsIndicators: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/, content: {
				HStack() {
					Text(model.telemetry.stdout)
						.multilineTextAlignment(.leading)
					Spacer()
				}
			})
			Divider()
			Text("STDERR").font(.title)
			Divider()
			ScrollView(/*@START_MENU_TOKEN@*/.vertical/*@END_MENU_TOKEN@*/, showsIndicators: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/, content: {
				HStack() {
					Text(model.telemetry.stderr)
						.multilineTextAlignment(.leading)
					Spacer()
				}
			})
		}
	}
}

struct ContentView: View {
    @EnvironmentObject var model: W2STModel

    var body: some View {
        HStack {
		TelemetryView()
		GCView()
		ConsoleView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(W2STModel())
    }
}
