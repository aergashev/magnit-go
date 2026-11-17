import Foundation

// Changes to lines already in the basket. Entity-level: each touches one line and
// nothing else, so the basket's own UI (EditableLine, PaperStepper, UndoBar) uses them.

extension AppState {
    /// Not available for marked drinks: another bottle means another code to scan.
    func increment(_ line: BasketLine) {
        guard let index = basket.firstIndex(where: { $0.id == line.id }), !basket[index].isMarked else { return }
        basket[index].qty += 1
    }

    /// Going below one removes the line. No confirmation: removal is undoable.
    func decrement(_ line: BasketLine) {
        guard let index = basket.firstIndex(where: { $0.id == line.id }) else { return }
        if basket[index].qty > 1 {
            basket[index].qty -= 1
            if basket[index].isMarked { basket[index].marks.removeLast() }
        } else {
            remove(line)
        }
    }

    func remove(_ line: BasketLine) {
        guard let index = basket.firstIndex(where: { $0.id == line.id }) else { return }
        basket.remove(at: index)
        let entry = RemovedLine(line: line, index: index)
        removed = entry
        if lastAddedID == line.id { lastAddedID = basket.first?.id }

        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(7))
            if self?.removed?.token == entry.token { self?.removed = nil }
        }
    }

    func undoRemove() {
        guard let entry = removed else { return }
        basket.insert(entry.line, at: min(entry.index, basket.count))
        lastAddedID = entry.line.id
        removed = nil
    }
}
