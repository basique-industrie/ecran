import CoreGraphics
import Domain
import Foundation

public enum CooperativeCorner {
    public static func complementaryBand(action: WindowAction, placed: CGRect, usable: CGRect) -> CGRect? {
        guard action.category == .corners else { return nil }
        switch action {
        case .topLeft, .bottomLeft:
            let width = usable.maxX - placed.maxX
            guard width > 20 else { return nil }
            return CGRect(x: placed.maxX, y: placed.minY, width: width, height: placed.height)
        case .topRight, .bottomRight:
            let width = placed.minX - usable.minX
            guard width > 20 else { return nil }
            return CGRect(x: usable.minX, y: placed.minY, width: width, height: placed.height)
        default:
            return nil
        }
    }

    public static func shouldResize(_ candidate: CGRect, into band: CGRect, excluding placed: CGRect) -> Bool {
        let overlap = candidate.intersection(band)
        guard overlap.width > 20, overlap.height > 20 else { return false }
        let collision = candidate.intersection(placed)
        guard collision.width < 8 || collision.height < 8 else { return false }
        let candidateArea = max(candidate.width * candidate.height, 1)
        let bandArea = max(band.width * band.height, 1)
        let overlapArea = overlap.width * overlap.height
        guard overlapArea / candidateArea >= 0.5 else { return false }
        return candidateArea <= bandArea * 1.25
    }
}
