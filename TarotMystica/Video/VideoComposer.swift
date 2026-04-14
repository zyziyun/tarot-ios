import AVFoundation
import CoreGraphics
import SwiftUI
import UIKit

/// Streaming video composer — renders frames on-demand and writes them immediately
/// to avoid holding all frames in memory at once (which caused OOM on iPhone).
@MainActor
final class VideoComposer {

    struct Config {
        let width: Int
        let height: Int
        let fps: Int
        let bitrate: Int

        static let `default` = Config(width: 1080, height: 1920, fps: 30, bitrate: 4_000_000)
    }

    private let storyboard: VideoStoryboard
    private let config: Config
    private let scale: CGFloat = 2.0  // 540x960 @2x = 1080x1920

    init(storyboard: VideoStoryboard, config: Config = .default) {
        self.storyboard = storyboard
        self.config = config
    }

    /// Stream-render and compose video — one frame at a time, constant memory
    func generate(progress: @escaping (Float) -> Void) async throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("tarot_share_\(UUID().uuidString).mp4")
        try? FileManager.default.removeItem(at: outputURL)

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: config.width,
            AVVideoHeightKey: config.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: config.bitrate,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
            ],
        ]

        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        writerInput.expectsMediaDataInRealTime = false

        let pixelAttrs: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: config.width,
            kCVPixelBufferHeightKey as String: config.height,
        ]

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: pixelAttrs
        )

        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        let fps = storyboard.fps
        let totalFrames = storyboard.totalFrames
        let timescale = CMTimeScale(fps)
        let crossfadeFrameCount = Int(storyboard.crossfadeDuration * Double(fps))
        var frameIndex = 0

        // Keep only the last frame of each scene for crossfade (1 image, ~8MB)
        var previousLastFrame: CGImage?

        for (sceneIdx, scene) in storyboard.scenes.enumerated() {
            let holdFrameCount = Int(scene.holdDuration * Double(fps))

            if sceneIdx > 0, let prevFrame = previousLastFrame {
                let firstFrame = renderSceneFrame(scene, at: 0, totalHoldFrames: holdFrameCount)
                if let toFrame = firstFrame {
                    for i in 0..<crossfadeFrameCount {
                        let alpha = CGFloat(i) / CGFloat(max(crossfadeFrameCount - 1, 1))
                        let blended = blendFrames(from: prevFrame, to: toFrame, alpha: alpha)
                        if let blended {
                            try await writeFrame(blended, at: frameIndex, timescale: timescale,
                                                 adaptor: adaptor, writerInput: writerInput)
                        }
                        frameIndex += 1
                        reportProgress(frameIndex, totalFrames, progress)
                    }
                }
            }

            var lastSceneFrame: CGImage?
            let isAnimated = scene.isAnimated

            if !isAnimated {
                let frame = renderSceneFrame(scene, at: 0, totalHoldFrames: holdFrameCount)
                lastSceneFrame = frame
                if let frame {
                    for _ in 0..<holdFrameCount {
                        try await writeFrame(frame, at: frameIndex, timescale: timescale,
                                             adaptor: adaptor, writerInput: writerInput)
                        frameIndex += 1
                    }
                    reportProgress(frameIndex, totalFrames, progress)
                    await Task.yield()
                }
            } else {
                for i in 0..<holdFrameCount {
                    let frame = renderSceneFrame(scene, at: i, totalHoldFrames: holdFrameCount)
                    if let frame {
                        try await writeFrame(frame, at: frameIndex, timescale: timescale,
                                             adaptor: adaptor, writerInput: writerInput)
                        lastSceneFrame = frame
                    }
                    frameIndex += 1
                    if frameIndex % 5 == 0 {
                        reportProgress(frameIndex, totalFrames, progress)
                        await Task.yield()
                    }
                }
            }

            previousLastFrame = lastSceneFrame
        }

        writerInput.markAsFinished()
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            writer.finishWriting { c.resume() }
        }

        if writer.status == .failed {
            throw writer.error ?? NSError(domain: "VideoComposer", code: -1)
        }

        progress(1.0)
        return outputURL
    }

    // MARK: - Render a single scene frame

    private func renderSceneFrame(_ scene: VideoScene, at frameIdx: Int, totalHoldFrames: Int) -> CGImage? {
        switch scene {
        case .titleCard(let question, let spreadName):
            return renderView(VideoTitleScene(question: question, spreadName: spreadName))

        case .spreadLayout(let spreadKey, let positionCount, let spreadName):
            return renderView(VideoSpreadLayoutScene(
                spreadKey: spreadKey,
                positionCount: positionCount,
                spreadName: spreadName
            ))

        case .cardDraw(let cards, _):
            // Animate: cards appear one by one over the duration
            let drawProgress = Double(frameIdx + 1) / Double(max(totalHoldFrames, 1))
            return renderView(VideoCardDrawScene(cards: cards, drawProgress: drawProgress))

        case .cardReveal(let card, let position, let cardName):
            let flipFrames = Int(Double(totalHoldFrames) * 0.4)
            let flipProgress: Double
            if frameIdx < flipFrames {
                flipProgress = Double(frameIdx) / Double(max(flipFrames - 1, 1))
            } else {
                flipProgress = 1.0
            }
            return renderView(VideoCardRevealScene(
                cardImage: card.card.image,
                cardName: cardName,
                positionLabel: position.label,
                isReversed: card.reversed,
                flipProgress: flipProgress
            ))

        case .allCards(let cards, let spreadKey):
            return renderView(VideoAllCardsScene(cards: cards, spreadKey: spreadKey))

        case .aiSummary(let text, let question, let spreadName, let cards):
            return renderView(VideoAISummaryScene(text: text, question: question, spreadName: spreadName, cards: cards))

        case .outro:
            return renderView(VideoOutroScene())
        }
    }

    // MARK: - SwiftUI → CGImage

    private func renderView<V: View>(_ view: V) -> CGImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        return renderer.cgImage
    }

    // MARK: - Blend two frames (crossfade)

    private func blendFrames(from: CGImage, to: CGImage, alpha: CGFloat) -> CGImage? {
        let w = from.width, h = from.height
        guard let ctx = CGContext(
            data: nil, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else { return nil }

        let rect = CGRect(x: 0, y: 0, width: w, height: h)
        // Draw 'from' fully opaque first, then overlay 'to' at alpha.
        // Source-over gives: result = to*alpha + from*(1-alpha) — correct linear crossfade.
        ctx.setAlpha(1.0)
        ctx.draw(from, in: rect)
        ctx.setAlpha(alpha)
        ctx.draw(to, in: rect)
        return ctx.makeImage()
    }

    // MARK: - Write one frame to video

    private func writeFrame(_ image: CGImage, at index: Int, timescale: CMTimeScale,
                            adaptor: AVAssetWriterInputPixelBufferAdaptor,
                            writerInput: AVAssetWriterInput) async throws {
        while !writerInput.isReadyForMoreMediaData {
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        if let pb = makePixelBuffer(from: image, adaptor: adaptor) {
            let time = CMTime(value: CMTimeValue(index), timescale: timescale)
            adaptor.append(pb, withPresentationTime: time)
        }
    }

    // MARK: - CGImage → CVPixelBuffer (via UIKit for correct orientation)

    private func makePixelBuffer(from image: CGImage, adaptor: AVAssetWriterInputPixelBufferAdaptor) -> CVPixelBuffer? {
        guard let pool = adaptor.pixelBufferPool else { return nil }

        var pb: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pb)
        guard let buffer = pb else { return nil }

        let w = config.width, h = config.height
        let size = CGSize(width: w, height: h)

        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 1.0
        fmt.opaque = true
        let uiImage = UIImage(cgImage: image)
        let rendered = UIGraphicsImageRenderer(size: size, format: fmt).image { _ in
            uiImage.draw(in: CGRect(origin: .zero, size: size))
        }

        guard let cg = rendered.cgImage,
              let provider = cg.dataProvider,
              let srcData = provider.data else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let dst = CVPixelBufferGetBaseAddress(buffer) else { return nil }
        let dstBPR = CVPixelBufferGetBytesPerRow(buffer)
        let srcBPR = cg.bytesPerRow
        let src = CFDataGetBytePtr(srcData)!
        let dstPtr = dst.assumingMemoryBound(to: UInt8.self)
        let copyLen = min(dstBPR, srcBPR)

        for row in 0..<h {
            memcpy(dstPtr + row * dstBPR, src + row * srcBPR, copyLen)
        }

        return buffer
    }

    // MARK: - Progress

    private func reportProgress(_ done: Int, _ total: Int, _ cb: (Float) -> Void) {
        cb(min(Float(done) / Float(max(total, 1)), 0.99))
    }
}
