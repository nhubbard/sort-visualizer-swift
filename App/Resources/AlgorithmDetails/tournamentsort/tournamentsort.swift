func sort(_ array: inout [Int]) {
    let n = array.count
    guard n > 1 else {
        return
    }

    // matches[root], matches[root + 1], matches[root + 2] = (winner, winners, losers) for a
    // match node at slot `root`. `winners`/`losers` are references: either a player leaf,
    // encoded as `-playerIndex` (so `<= 0`), or another match node's root offset (`> 0`).
    var matches = [Int](repeating: 0, count: 6 * n)

    func isPlayer(_ ref: Int) -> Bool {
        ref <= 0
    }
    func makePlayer(_ index: Int) -> Int {
        -index
    }
    func getWinner(_ root: Int) -> Int {
        matches[root]
    }
    func getWinners(_ root: Int) -> Int {
        matches[root + 1]
    }
    func getLosers(_ root: Int) -> Int {
        matches[root + 2]
    }
    func setMatch(_ root: Int, _ winner: Int, _ winners: Int, _ losers: Int) {
        matches[root] = winner
        matches[root + 1] = winners
        matches[root + 2] = losers
    }
    func getPlayer(_ ref: Int) -> Int {
        isPlayer(ref) ? abs(ref) : getWinner(ref)
    }

    func makeMatch(_ top: Int, _ bot: Int, _ root: Int) -> Int {
        let topWinner = getPlayer(top)
        let botWinner = getPlayer(bot)
        if array[topWinner] <= array[botWinner] {
            setMatch(root, topWinner, top, bot)
        } else {
            setMatch(root, botWinner, bot, top)
        }
        return root
    }

    func knockout(_ i: Int, _ k: Int, _ root: Int) -> Int {
        if i == k {
            return makePlayer(i)
        }
        let mid = (i + k) / 2
        let leftRef = knockout(i, mid, 2 * root)
        let rightRef = knockout(mid + 1, k, 2 * root + 3)
        return makeMatch(leftRef, rightRef, root)
    }

    func rebuild(_ root: Int) -> Int {
        if isPlayer(getWinners(root)) {
            return getLosers(root)
        }
        matches[root + 1] = rebuild(getWinners(root))
        if array[getPlayer(getLosers(root))] < array[getPlayer(getWinners(root))] {
            matches[root] = getPlayer(getLosers(root))
            let previousLosers = getLosers(root)
            matches[root + 2] = getWinners(root)
            matches[root + 1] = previousLosers
        } else {
            matches[root] = getPlayer(getWinners(root))
        }
        return root
    }

    var tourney = knockout(0, n - 1, 3)

    func pop() -> Int {
        let result = array[getPlayer(tourney)]
        tourney = isPlayer(tourney) ? 0 : rebuild(tourney)
        return result
    }

    var output = [Int](repeating: 0, count: n)
    for i in 0 ..< n {
        output[i] = pop()
    }
    array = output
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
