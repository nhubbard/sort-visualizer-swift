func sort(_ arr: inout [Int]) {
    let n = arr.count
    guard n > 1 else { return }

    enum StackID { case two, three }
    var stack2: [Int] = []
    var stack3: [Int] = []

    func push(_ id: StackID, _ value: Int) {
        switch id {
        case .two: stack2.append(value)
        case .three: stack3.append(value)
        }
    }
    func pop(_ id: StackID) -> Int {
        switch id {
        case .two: return stack2.removeLast()
        case .three: return stack3.removeLast()
        }
    }
    func peek(_ id: StackID) -> Int? {
        switch id {
        case .two: return stack2.last
        case .three: return stack3.last
        }
    }
    func isEmpty(_ id: StackID) -> Bool {
        switch id {
        case .two: return stack2.isEmpty
        case .three: return stack3.isEmpty
        }
    }

    var sp = 0
    var unsorted = 0
    var target = 0
    var targetMoves = 0

    @discardableResult
    func moveFromMain(_ id: StackID, checkUnsorted: Bool) -> Int {
        var duplicates = 1
        push(id, arr[sp])
        sp += 1
        var endOnLength = sp >= n || (checkUnsorted && sp >= unsorted)
        while !endOnLength, arr[sp] == peek(id) {
            duplicates += 1
            push(id, arr[sp])
            sp += 1
            endOnLength = sp >= n || (checkUnsorted && sp >= unsorted)
        }
        return duplicates
    }

    func moveToMain(_ id: StackID) {
        sp -= 1
        arr[sp] = pop(id)
        while !isEmpty(id), peek(id) == arr[sp] {
            sp -= 1
            arr[sp] = pop(id)
        }
    }

    func moveBetweenStacks(_ from: StackID, _ to: StackID) {
        push(to, pop(from))
        while !isEmpty(from), peek(from) == peek(to) {
            push(to, pop(from))
        }
    }

    func validNumberMoves(_ moves: Int) -> Bool {
        if moves == 0 {
            return true
        }
        if moves % 2 == 0 {
            return false
        }
        return validNumberMoves(moves / 2)
    }

    func getHeight(_ movesPlus1: Int) -> Int {
        if movesPlus1 == 1 {
            return 0
        }
        return getHeight(movesPlus1 / 2) + 1
    }

    func endConMet(_ endCon: Int, _ moves: Int) -> Bool {
        guard validNumberMoves(moves) else { return false }
        switch endCon {
        case 1: return stack2.isEmpty || target <= stack2.last!
        case 2: return moves == targetMoves
        case 3: return stack2.isEmpty
        default: fatalError("unknown end condition")
        }
    }

    @discardableResult
    func hanoi(_ startStack: Int, _ goRight: Bool, _ endCon: Int) -> Int {
        var moves = 0
        var minPoleLoc = startStack

        if !endConMet(endCon, moves) {
            moves += 1
            switch minPoleLoc {
            case 1:
                if goRight {
                    moveFromMain(.two, checkUnsorted: true)
                    minPoleLoc = 2
                } else {
                    moveFromMain(.three, checkUnsorted: true)
                    minPoleLoc = 3
                }
            case 2:
                if goRight {
                    moveBetweenStacks(.two, .three)
                    minPoleLoc = 3
                } else {
                    moveToMain(.two)
                    minPoleLoc = 1
                }
            default: // 3
                if goRight {
                    moveToMain(.three)
                    minPoleLoc = 1
                } else {
                    moveBetweenStacks(.three, .two)
                    minPoleLoc = 2
                }
            }
        }

        while !endConMet(endCon, moves) {
            moves += 2
            switch minPoleLoc {
            case 1:
                if !stack2.isEmpty, stack3.isEmpty || stack2.last! < stack3.last! {
                    moveBetweenStacks(.two, .three)
                } else {
                    moveBetweenStacks(.three, .two)
                }
                if goRight {
                    moveFromMain(.two, checkUnsorted: true)
                    minPoleLoc = 2
                } else {
                    moveFromMain(.three, checkUnsorted: true)
                    minPoleLoc = 3
                }
            case 2:
                if stack3.isEmpty || (sp < unsorted && arr[sp] < stack3.last!) {
                    moveFromMain(.three, checkUnsorted: true)
                } else {
                    moveToMain(.three)
                }
                if goRight {
                    moveBetweenStacks(.two, .three)
                    minPoleLoc = 3
                } else {
                    moveToMain(.two)
                    minPoleLoc = 1
                }
            default: // 3
                if stack2.isEmpty || (sp < unsorted && arr[sp] < stack2.last!) {
                    moveFromMain(.two, checkUnsorted: true)
                } else {
                    moveToMain(.two)
                }
                if goRight {
                    moveToMain(.three)
                    minPoleLoc = 1
                } else {
                    moveBetweenStacks(.three, .two)
                    minPoleLoc = 2
                }
            }
        }

        return moves
    }

    func removeFromMainStack() {
        target = arr[sp]
        let moves = hanoi(2, true, 1)
        let height = getHeight(moves + 1)
        targetMoves = moves
        let evenHeight = height % 2 == 0

        if evenHeight {
            hanoi(1, true, 2)
        }
        unsorted += moveFromMain(.two, checkUnsorted: false)
        hanoi(3, evenHeight, 2)
    }

    func returnToMainStack() {
        let moves = hanoi(2, true, 3)
        let height = getHeight(moves + 1)
        if height % 2 == 1 {
            targetMoves = moves
            hanoi(3, true, 2)
        }
    }

    while unsorted < n {
        removeFromMainStack()
    }
    returnToMainStack()
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
