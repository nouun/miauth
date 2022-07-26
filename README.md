# MiAuth

Xiaomi M365/Mi Authentication library written in Swift.

## Features

- [x] M365 Authentication
- [ ] Mi Authentication (WIP)
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

Below is a small example using `M365Client` to connect to a scooter
named "MIScooter4565", authenticate, and then get the serial number.

```swift
class MiAuthTest {
    let client: M365Client
    
    init() {
        self.client = M365Client()
        self.client.deviceDelegate = self
    }
}

extension MiAuthTest: MiDeviceDelegate {
    func didDiscover(device: CBPeripheral) {
        if device.name == "MIScooter4565" {
            self.client.connect(to: device)
        }
    }
    
    func didRecieve(value: MiValue) {
        switch value {
        case .serial(number: let serial): print("serial: " + serial)
        default: return
        }
    }
    
    func didDeviceUpdate(state: MiState) {
        switch state {
        case .authenticated:
            self.client?.write(payload: .serialNumber)
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
