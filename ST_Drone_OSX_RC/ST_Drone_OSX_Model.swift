//
//  ST_Drone_OSX_Model.swift
//  ST_Drone_OSX_RC
//
//  Created by SUENAGA Hiroki on 2021/07/08.
//

import Foundation
import Combine
import STDroneOSX
import GameController

struct FlightControlHandler {
	var description: (_:String) -> Void

	var ailron: (_:UInt8) -> Void
	var elevator: (_:UInt8) -> Void
	var throttle: (_:UInt8) -> Void
	var rudder: (_:UInt8) -> Void

	var armed: (_:Bool) -> Void
	var calibrate: (_:Bool) -> Void
}

final class GameController {
	var controller:GCController?
	var handler: FlightControlHandler?

	init(_ handler:FlightControlHandler) {
		self.handler = handler
		NotificationCenter.default.addObserver(self, selector: #selector(self.handleDidConnect(_:)), name: NSNotification.Name.GCControllerDidConnect, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.handleDidDisconnect(_:)), name: NSNotification.Name.GCControllerDidDisconnect, object: nil)
		GCController.shouldMonitorBackgroundEvents = true
	}

	@objc
	func handleDidConnect(_ notification:Notification) {
		guard let gameController = notification.object as? GCController else {
			print("broken notification?")
			return
		}
		guard gameController.extendedGamepad != nil else {
			print("the controller is not extendedGamepad. ignore.")
			return
		}
		if self.controller != nil {
			print("controller is already connected.")
		}
		handler?.description(gameController.vendorName ?? "NO NAME")
		self.controller = gameController
		gameController.playerIndex = GCControllerPlayerIndex.indexUnset
		registerEvents()
	}

	@objc
	func handleDidDisconnect(_ notification:Notification) {
		print("disconnected.")
		if self.controller != nil {
			self.controller?.playerIndex = GCControllerPlayerIndex.indexUnset
			self.controller = nil
		}
		self.handler?.description("No Controller")
		self.handler?.ailron(128)
		self.handler?.elevator(128)
		self.handler?.throttle(1)
		self.handler?.rudder(0)
		self.handler?.calibrate(false)
		self.handler?.armed(false)
	}

	func calcAxis(_ value:Float) -> UInt8 {
		let pos = 128.0 + 64.0 * value

		if (pos < 0.0) {
			return 0
		}
		else if (pos > 255.0) {
			return 255
		}
		else {
			return UInt8(pos)
		}
	}

	func calcThrottle(_ value:Float) -> UInt8 {
		let pos = 25.0 * value + 1.0

		if (pos < 0.0) {
			return 0
		}
		if (pos > 26.0) {
			return 26
		}
		return UInt8(pos)
	}

	func registerEvents() {
		guard let pad = self.controller?.extendedGamepad else {
			return
		}
		pad.leftThumbstick.valueChangedHandler = {(_ dpad:GCControllerDirectionPad, _ x:Float, _ y:Float) -> Void in
			self.handler?.rudder(self.calcAxis(x))
			self.handler?.throttle(self.calcThrottle(y))
		}
		pad.rightThumbstick.valueChangedHandler = {(_ dpad: GCControllerDirectionPad, _ x:Float, _ y:Float) -> Void in
			self.handler?.ailron(self.calcAxis(x))
			self.handler?.elevator(self.calcAxis(y))
		}
		pad.rightShoulder.valueChangedHandler = {(_ button: GCControllerButtonInput, _ value:Float, _ pressed:Bool) -> Void in
			self.handler?.armed(pressed)
		}
		pad.leftShoulder.valueChangedHandler = {(_ button: GCControllerButtonInput, _ value:Float, _ pressed:Bool) -> Void in
			self.handler?.calibrate(pressed)
		}
		print("events registered.")
	}
}

final class W2STModel: ObservableObject {
	let central:STDroneCentralManager = STDroneCentralManager()
	var peripheral:STDronePeripheral?
	var controlData: Data = Data.init(count: 7)

	var gameController: GameController!
	var controlHandler: FlightControlHandler!

	@Published var telemetry: W2STTelemetry = W2STTelemetry()
	@Published var controllerName: String = "No Controller"
	@Published var rudder: UInt8 = 128 {
		didSet {
			updateControlData()
		}
	}
	@Published var throttle: UInt8 = 1 {
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
				self.arm = false
				self.calibrate = false
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

	init() {
		self.controlHandler = FlightControlHandler(
			description: { name in
				self.controllerName = name
			},
			ailron: { value in
				self.aileron = value
			},
			elevator: { value in
				self.elevator = value
			},
			throttle: { value in
				self.throttle = value
			},
			rudder: { value in
				self.rudder = value
			},
			armed: { value in
				if value {
					self.arm.toggle()
				}
			},
			calibrate: { value in
				self.calibrate = value
			})
		self.gameController = GameController(self.controlHandler)
	}

	private func connectPeripheral(_ peripheral: STDronePeripheral) {
		peripheral.connect {error in
			if error != nil {
				self.enableConnect = false
				return
			}
			peripheral.discoverAll() {
				peripheral.onDisconnect {
					self.enableConnect = false
					return
				}
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
			peripheral.writeJoydata(data: controlData)
		}
	}
}
