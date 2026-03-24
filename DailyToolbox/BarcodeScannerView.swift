/*

Copyright 2020-2026 Marcus Deuß

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

//
//  BarcodeScannerView.swift
//  DailyToolbox
//

import SwiftUI
import AVFoundation

// MARK: - BarcodeEntry

struct BarcodeEntry: Codable, Identifiable, Sendable {
    var id   = UUID()
    let value: String
    let type:  String
    let date:  Date
}

// MARK: - FoodProduct

struct FoodProduct: Sendable {
    let name:       String
    let brand:      String
    let quantity:   String
    let nutriScore: String?

    var nutriScoreGrade: String { (nutriScore ?? "").uppercased() }

    var nutriScoreColor: Color {
        switch nutriScore?.lowercased() {
        case "a": return Color(red: 0.15, green: 0.65, blue: 0.25)
        case "b": return Color(red: 0.55, green: 0.78, blue: 0.20)
        case "c": return Color(red: 1.00, green: 0.80, blue: 0.10)
        case "d": return Color(red: 1.00, green: 0.55, blue: 0.10)
        case "e": return Color(red: 0.90, green: 0.20, blue: 0.15)
        default:  return Color.secondary
        }
    }
}

// MARK: - CameraPreview (UIViewRepresentable)

private final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session      = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

// MARK: - BarcodeScannerModel

@Observable
@MainActor
final class BarcodeScannerModel: NSObject {
    // nonisolated(unsafe): AVFoundation objects accessed on dedicated session queue
    nonisolated(unsafe) let session        = AVCaptureSession()
    nonisolated(unsafe) let metadataOutput = AVCaptureMetadataOutput()
    /// Dedicated serial queue required by AVFoundation for all session operations.
    private let sessionQueue = DispatchQueue(label: "barcode.session", qos: .userInitiated)

    var scannedValue: String?               = nil
    var scannedType:  String?               = nil
    var authStatus:   AVAuthorizationStatus = .notDetermined
    var product:      FoodProduct?          = nil
    var productState: ProductLookupState    = .idle

    enum ProductLookupState: Equatable {
        case idle, loading, found, notFound, error(String)
    }

    private var isConfigured = false

    override init() {
        super.init()
        authStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    // MARK: - Public interface

    func checkAndStart() {
        switch authStatus {
        case .authorized:
            prepareAndStart()
        case .notDetermined:
            Task {
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                authStatus  = granted ? .authorized : .denied
                if granted { prepareAndStart() }
            }
        default:
            break
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    func lookupProduct(_ barcode: String) {
        guard barcode.count == 13, barcode.allSatisfy(\.isNumber) else {
            product = nil
            productState = .idle
            return
        }
        productState = .loading
        product = nil
        Task {
            let urlStr = "https://world.openfoodfacts.org/api/v2/product/\(barcode).json?fields=product_name,brands,quantity,nutriscore_grade"
            guard let url = URL(string: urlStr) else { productState = .error("Invalid URL"); return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? Int, status == 1,
                   let p = json["product"] as? [String: Any] {
                    let name     = (p["product_name"] as? String ?? "").trimmingCharacters(in: .whitespaces)
                    let brand    = (p["brands"]       as? String ?? "").trimmingCharacters(in: .whitespaces)
                    let quantity = (p["quantity"]     as? String ?? "").trimmingCharacters(in: .whitespaces)
                    let nutri    = p["nutriscore_grade"] as? String
                    if !name.isEmpty {
                        product = FoodProduct(name: name, brand: brand, quantity: quantity, nutriScore: nutri)
                        productState = .found
                    } else {
                        productState = .notFound
                    }
                } else {
                    productState = .notFound
                }
            } catch {
                productState = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - Session setup — all AVFoundation work on sessionQueue

    private func prepareAndStart() {
        if isConfigured {
            sessionQueue.async { [weak self] in
                guard let self, !self.session.isRunning else { return }
                self.session.startRunning()
            }
            return
        }
        isConfigured = true
        // Delegate callbacks delivered on sessionQueue (same queue as config)
        metadataOutput.setMetadataObjectsDelegate(self, queue: sessionQueue)
        sessionQueue.async { [weak self] in
            self?._configureAndRun()
        }
    }

    // MARK: - AVFoundation config (runs on sessionQueue)

    nonisolated private func _configureAndRun() {
        session.beginConfiguration()

        guard let device = AVCaptureDevice.default(for: .video),
              let input  = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.metadataObjectTypes = [
                .ean13, .ean8, .upce, .qr, .code128,
                .code39, .pdf417, .dataMatrix, .itf14
            ]
        }

        session.commitConfiguration()
        session.startRunning()
    }

    // MARK: - Helpers

    nonisolated static func humanReadableType(_ type: AVMetadataObject.ObjectType) -> String {
        switch type {
        case .ean13:      "EAN-13"
        case .ean8:       "EAN-8"
        case .upce:       "UPC-E"
        case .qr:         "QR Code"
        case .code128:    "Code 128"
        case .code39:     "Code 39"
        case .pdf417:     "PDF-417"
        case .dataMatrix: "Data Matrix"
        case .itf14:      "ITF-14"
        default:          "Barcode"
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension BarcodeScannerModel: @preconcurrency AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let obj   = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue else { return }
        let typeName = BarcodeScannerModel.humanReadableType(obj.type)
        Task { @MainActor [weak self] in
            guard let self, scannedValue != value else { return }
            scannedValue = value
            scannedType  = typeName
            lookupProduct(value)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - BarcodeScannerView

struct BarcodeScannerView: View {
    @State private var model                 = BarcodeScannerModel()
    @AppStorage("barcode.history") private var historyData = ""
    @State private var showClearConfirmation = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    // MARK: - History helpers

    private var history: [BarcodeEntry] {
        guard !historyData.isEmpty,
              let data    = historyData.data(using: .utf8),
              let entries = try? JSONDecoder().decode([BarcodeEntry].self, from: data)
        else { return [] }
        return entries
    }

    private func addToHistory(_ entry: BarcodeEntry) {
        var entries = history
        guard entries.first?.value != entry.value else { return }
        entries.insert(entry, at: 0)
        if entries.count > 20 { entries = Array(entries.prefix(20)) }
        if let data   = try? JSONEncoder().encode(entries),
           let string = String(data: data, encoding: .utf8) {
            historyData = string
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            background
            GeometryReader { geo in
                VStack(spacing: 0) {
                    cameraSection(height: geo.size.height * 0.52, width: geo.size.width)
                    ScrollView {
                        VStack(spacing: 16) {
                            if model.authStatus == .denied || model.authStatus == .restricted {
                                GlassEffectContainer { permissionCard }
                            }
                            if let value = model.scannedValue {
                                GlassEffectContainer {
                                    resultCard(value: value, type: model.scannedType ?? "Barcode")
                                }
                                if model.productState != .idle {
                                    productCard
                                }
                            }
                            if !history.isEmpty {
                                GlassEffectContainer { historySection }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                }
            }
        }
        .navigationTitle("Barcode Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear    { model.checkAndStart() }
        .onDisappear { model.stopSession()   }
        .onChange(of: model.scannedValue) { _, newValue in
            guard let value = newValue, let type = model.scannedType else { return }
            addToHistory(BarcodeEntry(value: value, type: type, date: .now))
        }
        .confirmationDialog(
            "Clear scan history?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) { historyData = "" }
        } message: {
            let n = history.count
            Text("This will remove all \(n) scan\(n == 1 ? "" : "s").")
        }
    }

    // MARK: - Background

    private var background: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                Color(red: 0.04, green: 0.14, blue: 0.26),
                Color(red: 0.05, green: 0.18, blue: 0.32),
                Color(red: 0.04, green: 0.13, blue: 0.24),
                Color(red: 0.06, green: 0.20, blue: 0.34),
                Color(red: 0.08, green: 0.26, blue: 0.42),
                Color(red: 0.05, green: 0.18, blue: 0.30),
                Color(red: 0.03, green: 0.11, blue: 0.20),
                Color(red: 0.05, green: 0.15, blue: 0.26),
                Color(red: 0.03, green: 0.12, blue: 0.22)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: - Camera section

    @ViewBuilder
    private func cameraSection(height: CGFloat, width: CGFloat) -> some View {
        let reticleW = min(width * 0.78, 280.0)
        let reticleH = reticleW * 0.60

        ZStack {
            // Camera feed or black placeholder
            if model.authStatus == .authorized {
                CameraPreview(session: model.session)
            } else {
                Color.black
            }

            if model.authStatus == .authorized {
                // Dimmed overlay with a transparent cut-out for the scan area
                ZStack {
                    Color.black.opacity(0.45)
                    RoundedRectangle(cornerRadius: 16)
                        .frame(width: reticleW, height: reticleH)
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                .allowsHitTesting(false)

                // Reticle white border
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white, lineWidth: 2)
                    .frame(width: reticleW, height: reticleH)
                    .allowsHitTesting(false)

                // Accent corner tick marks
                ReticleCorners(width: reticleW, height: reticleH)
                    .allowsHitTesting(false)

                // Format badge — top-right of the viewfinder
                if let type = model.scannedType {
                    VStack {
                        HStack {
                            Spacer()
                            Text(type)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.black.opacity(0.55))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding([.top, .trailing], 12)
                                .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .topTrailing)))
                        }
                        Spacer()
                    }
                    .animation(.easeInOut(duration: 0.2), value: type)
                }
            }

            // Denied / restricted placeholder
            if model.authStatus == .denied || model.authStatus == .restricted {
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 44, weight: .thin))
                        .foregroundStyle(.white.opacity(0.45))
                    Text("Camera access required")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.65))
                }
                .accessibilityLabel("Camera access required. See the settings card below.")
            }

            // Permission request in progress
            if model.authStatus == .notDetermined {
                ProgressView().tint(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
    }

    // MARK: - Permission card

    private var permissionCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(toolAccent.opacity(0.20))
                    .frame(width: 56, height: 56)
                Image(systemName: "camera.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [toolAccentLight, toolAccent],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }
            VStack(spacing: 6) {
                Text("Camera Access Required")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primary)
                Text("Allow camera access to scan barcodes and QR codes.")
                    .font(.callout)
                    .foregroundStyle(Color.primary.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Task { @MainActor in await UIApplication.shared.open(url) }
                }
            }
            .buttonStyle(.glass)
        }
        .padding(24)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: - Result card

    private func resultCard(value: String, type: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(toolAccent.opacity(0.20))
                        .frame(width: 44, height: 44)
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [toolAccentLight, toolAccent],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Scanned Result")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.primary)
                    Text(type)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(toolAccent)
                }
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        model.scannedValue = nil
                        model.scannedType  = nil
                        model.product      = nil
                        model.productState = .idle
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.primary.opacity(0.40))
                }
                .accessibilityLabel("Clear result")
            }

            Text(value)
                .font(.system(.body, design: .monospaced).weight(.medium))
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .accessibilityLabel("Scanned value: \(value)")

            Divider()
                .background(Color.primary.opacity(0.15))

            HStack(spacing: 10) {
                Button {
                    UIPasteboard.general.string = value
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.glass)

                ShareLink(item: value) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.glass)
            }
        }
        .padding(18)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: - History section

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(toolAccentLight)
                Text("Scan History")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primary)
                Spacer()
                Button("Clear All") { showClearConfirmation = true }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.55))
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 10)

            Divider().padding(.horizontal, 18)

            ForEach(history) { entry in
                historyRow(entry)
                if entry.id != history.last?.id {
                    Divider().padding(.horizontal, 18)
                }
            }

            Color.clear.frame(height: 4)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }

    private func historyRow(_ entry: BarcodeEntry) -> some View {
        Button {
            UIPasteboard.general.string = entry.value
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.value)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(Color.primary.opacity(0.50))
                }
                Spacer()
                Text(entry.type)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(toolAccent)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(toolAccent.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                Image(systemName: "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.30))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(entry.value), \(entry.type), \(entry.date.formatted(date: .abbreviated, time: .shortened)). Tap to copy."
        )
    }

    // MARK: - Product card

    @ViewBuilder
    private var productCard: some View {
        switch model.productState {
        case .loading:
            HStack(spacing: 12) {
                ProgressView().tint(.teal)
                Text("Looking up product…")
                    .font(.subheadline)
                    .foregroundStyle(Color.primary.opacity(0.65))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))

        case .found:
            if let p = model.product {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.teal)
                        Text("Product Info")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.primary.opacity(0.55))
                        Spacer()
                        if !p.nutriScoreGrade.isEmpty {
                            Text("Nutri-Score \(p.nutriScoreGrade)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(p.nutriScoreColor, in: Capsule())
                        }
                    }
                    Text(p.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                    if !p.brand.isEmpty {
                        Text(p.brand)
                            .font(.subheadline)
                            .foregroundStyle(Color.primary.opacity(0.65))
                    }
                    if !p.quantity.isEmpty {
                        Text(p.quantity)
                            .font(.caption)
                            .foregroundStyle(Color.primary.opacity(0.50))
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
            }

        case .notFound:
            HStack(spacing: 10) {
                Image(systemName: "questionmark.circle")
                    .foregroundStyle(Color.primary.opacity(0.45))
                Text("Product not found in Open Food Facts")
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.55))
            }
            .padding(16)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))

        case .error(let msg):
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text(msg).font(.caption).foregroundStyle(Color.primary.opacity(0.55))
            }
            .padding(16)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))

        case .idle:
            EmptyView()
        }
    }

    // MARK: - Accent colors

    private var toolAccent:      Color { Color(red: 0.15, green: 0.65, blue: 0.90) }
    private var toolAccentLight: Color { Color(red: 0.40, green: 0.85, blue: 1.00) }
}

// MARK: - Reticle Corners

private struct ReticleCorners: View {
    let width:  CGFloat
    let height: CGFloat

    private let cornerLength: CGFloat = 22
    private let lineWidth:    CGFloat = 3.5
    private let accentColor = Color(red: 0.15, green: 0.65, blue: 0.90)

    var body: some View {
        Canvas { ctx, size in
            let w  = size.width
            let h  = size.height
            let cl = cornerLength

            var path = Path()

            // Top-left
            path.move(to: CGPoint(x: cl, y: 0))
            path.addLine(to: CGPoint(x:  0, y:  0))
            path.addLine(to: CGPoint(x:  0, y: cl))
            // Top-right
            path.move(to: CGPoint(x: w - cl, y:  0))
            path.addLine(to: CGPoint(x: w,   y:  0))
            path.addLine(to: CGPoint(x: w,   y: cl))
            // Bottom-left
            path.move(to: CGPoint(x: cl, y: h))
            path.addLine(to: CGPoint(x:  0, y: h))
            path.addLine(to: CGPoint(x:  0, y: h - cl))
            // Bottom-right
            path.move(to: CGPoint(x: w - cl, y: h))
            path.addLine(to: CGPoint(x: w,   y: h))
            path.addLine(to: CGPoint(x: w,   y: h - cl))

            ctx.stroke(
                path,
                with: .color(accentColor),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BarcodeScannerView()
    }
}
