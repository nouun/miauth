# MiAuth

Xiaomi M365/Mi Authentication library written in Swift.

## Features

- [x] M365 Authentication
- [x] Mi Authentication (WIP - Login doesn't work reliably yet)
- [ ] Ninebot Authentication


## Installation


### Swift Package Manager

MiAuth currently only supports Swift Package Manager.

```swift
dependencies: [
    .package(url: "https://github.com/nouun/MiAuth.git", .upToNextMajor(from: "0.1.0"))
]
```


## Example


### MiClient

Below is a small example using `MiClient` to connect to a scooter
named "MIScooter4565", register, print the token, and then get the serial number.


```swift
class MiClientTest {
    let client: MiClient

    init() {
        self.client = MiClient()
        self.client.delegate = self
    }
}

extension MiClientTest: MiDeviceDelegate {
    func didDiscover(device: CBPeripheral) {
        if device.name == "MIScooter4565" {
            self.client.connect(to: device)
        }
    }

    func didRecieve(value: MiValue) {
        switch value {
        case .serial(number: let serial): print("Serial Number: " + serial)
        default: return
        }
    }

    func didUpdate(miState: MiState) {
        switch miState {
        case .authenticationReady:
            self.client.register()
        case .waitingForButtonPress:
            print("Press power button within 5 seconds")
        case .registered(token: let token):
            let tokenHex = toxen
                .map { String(format: "%02hhX", $0) }
                .joined(separator: " ")
            print("Token: \(tokenHex)")

            client.login(withToken: token)
        case .authenticated:
            self.client.write(payload: MiPayload.escSerialNumber)
        default: return
        }
    }
}
```


### M365Client

Below is a small example using `M365Client` to connect to a scooter
named "MIScooter4565", authenticate, and then get the serial number.

```swift
class M365ClientTest {
    let client: M365Client

    init() {
        self.client = M365Client()
        self.client.delegate = self
    }
}

extension M365ClientTest: MiDeviceDelegate {
    func didDiscover(device: CBPeripheral) {
        if device.name == "MIScooter4565" {
            self.client.connect(to: device)
        }
    }

    func didRecieve(value: MiValue) {
        switch value {
        case .serial(number: let serial): print("Serial Number: " + serial)
        default: return
        }
    }

    func didUpdate(miState: MiState) {
        switch miState {
        case .authenticated:
            self.client.write(payload: MiPayload.escSerialNumber)
        default: return
        }
    }
}
```


## Support

For any support regarding MiAuth feel free to contact me on Discord at `nouun#0246`.


## Credits

This would not have been possible without help from dnandra
and his [MiAuth](https://github.com/dnandha/miauth) documentation.

Also [VPCCMCrypt](https://github.com/billp/vpccmcrypt) for AES/CCM
encryption implementation in Objective-C which is what
[AESCCM.swift](Sources/MiAuth/Utils/AESCCM.swift) is based on. 
