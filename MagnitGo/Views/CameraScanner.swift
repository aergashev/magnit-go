import SwiftUI
import AVFoundation

/// Live scanner. Reads retail barcodes (EAN-13/8, UPC-E, Code 128), the EAN-13 labels
/// printed by in-store scales, and the Data Matrix marking codes on drinks.
struct CameraScanner: UIViewControllerRepresentable {
    var torch: Bool
    var onCode: (String) -> Void
    var onUnavailable: () -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.onCode = onCode
        controller.onUnavailable = onUnavailable
        return controller
    }

    func updateUIViewController(_ controller: ScannerViewController, context: Context) {
        controller.onCode = onCode
        controller.onUnavailable = onUnavailable
        controller.setTorch(torch)
    }
}

final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCode: (String) -> Void = { _ in }
    var onUnavailable: () -> Void = {}

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "magnitgo.scanner.session")
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var configured = false

    /// A product held in front of the camera is read many times a second. The same code
    /// counts again only after it has been out of view for this long.
    private let repeatDelay: TimeInterval = 2
    private var lastCode = ""
    private var lastSeen = Date.distantPast

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        previewLayer = layer

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configure()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted { self?.configure() } else { self?.onUnavailable() }
                }
            }
        default:
            DispatchQueue.main.async { [weak self] in self?.onUnavailable() }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        start()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        setTorch(false)
        sessionQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    func setTorch(_ on: Bool) {
        guard configured,
              let device = AVCaptureDevice.default(for: .video),
              device.hasTorch,
              device.isTorchActive != on,
              (try? device.lockForConfiguration()) != nil else { return }
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }

    private func configure() {
        guard !configured else { return }
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            onUnavailable()
            return
        }

        // Marking codes are small and often on a bottle cap, so favour close focus.
        if (try? device.lockForConfiguration()) != nil {
            if device.isAutoFocusRangeRestrictionSupported { device.autoFocusRangeRestriction = .near }
            if device.isFocusModeSupported(.continuousAutoFocus) { device.focusMode = .continuousAutoFocus }
            device.unlockForConfiguration()
        }

        session.beginConfiguration()
        if session.canAddInput(input) { session.addInput(input) }

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            let wanted: [AVMetadataObject.ObjectType] = [.ean13, .ean8, .upce, .code128, .dataMatrix]
            output.metadataObjectTypes = wanted.filter { output.availableMetadataObjectTypes.contains($0) }
        }
        session.commitConfiguration()

        configured = true
        start()
    }

    private func start() {
        guard configured else { return }
        sessionQueue.async { [session] in
            if !session.isRunning { session.startRunning() }
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = object.stringValue else { return }

        let now = Date()
        if code == lastCode, now.timeIntervalSince(lastSeen) < repeatDelay {
            lastSeen = now
            return
        }
        lastCode = code
        lastSeen = now
        onCode(code)
    }
}
