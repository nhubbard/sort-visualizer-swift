// MARK: - Non-`nil` Result Struct
fileprivate struct NonNilResult<T>: Equatable, Comparable where T: Equatable {
  var offset: Int
  var value: T
  
  init(_ offset: Int, _ value: T) {
    self.offset = offset
    self.value = value
  }
  
  static func ==(lhs: NonNilResult<T>, rhs: NonNilResult<T>) -> Bool {
    lhs.offset == rhs.offset && lhs.value == rhs.value
  }
  
  static func <(lhs: NonNilResult<T>, rhs: NonNilResult<T>) -> Bool {
    lhs.offset < rhs.offset
  }
}

// MARK: - `nil`-able Result Struct
fileprivate struct NilResult<T>: Equatable, Comparable where T: Equatable {
  var offset: Int
  var value: T?
  
  init(_ offset: Int, _ value: T?) {
    self.offset = offset
    self.value = value
  }
  
  static func ==(lhs: NilResult<T>, rhs: NilResult<T>) -> Bool {
    lhs.offset == rhs.offset && lhs.value == rhs.value
  }
  
  static func <(lhs: NilResult<T>, rhs: NilResult<T>) -> Bool {
    lhs.offset < rhs.offset
  }
}

// MARK: - ForEach
public extension Sequence {
  /**
   * Run an async closure for each element within the sequence.
   *
   * The closure calls will be performed in order, by waiting for each call to complete before proceeding with the next one. If any of the closure calls throw an error, then the iteration will be terminated and the error rethrown.
   *
   * - Parameter operation: The closure to run for each element.
   * - Throws: Rethrows any error thrown by the passed closure.
   */
  func asyncForEach(
    _ operation: (Element) async throws -> Void
  ) async rethrows {
    for element in self {
      try await operation(element)
    }
  }
  
  /**
   * Run an async closure for each element within the sequence.
   *
   * The closure calls will be performed concurrently, but the call to this function won't return until all of the closure calls have completed.
   *
   * - Parameter withPriority: Any specific `TaskPriority` to assign to the async tasks that will perform the closure calls. The default is `nil` (meaning that the system picks a priority).
   * - Parameter operation: The closure to run for each element.
   */
  func concurrentForEach(
    withPriority priority: TaskPriority? = nil,
    _ operation: @escaping (Element) async -> Void
  ) async {
    await withTaskGroup(of: Void.self) { group in
      for element in self {
        group.addTask(priority: priority) {
          await operation(element)
        }
      }
    }
  }
  
  /**
   * Run an async closure for each element within the sequence.
   *
   * The closure calls will be performed concurrently, but the call to this function won't return until all of the closure calls have completed. If any of the closure calls throw an error, then the first error will be rethrown once all closure calls have completed.
   *
   * - Parameter withPriority: Any specific `TaskPriority` to assign to the async tasks that will perform the closure calls. The default is `nil` (meaning that the system picks a priority).
   * - Parameter operation: The closure to run for each element.
   * - Throws: Rethrows any error thrown by the passed closure.
   */
  func concurrentForEach(
    withPriority priority: TaskPriority? = nil,
    _ operation: @escaping (Element) async throws -> Void
  ) async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
      for element in self {
        group.addTask(priority: priority) {
          try await operation(element)
        }
      }
      // Propagate any errors thrown by the group's tasks:
      for try await _ in group {}
    }
  }
}

// MARK: - Map
public extension Sequence {
  /**
   * Transform the sequence into an array of new values using an async closure.
   *
   * The closure calls will be performed in order, by waiting for each call to complete before proceeding with the next one. If any of the closure calls throw an error, then the iteration will be terminated and the error rethrown.
   *
   * - Parameter transform: The transformation to run on each element.
   * - Returns: The transformed values as an array. The order of the transformed values will match the original sequence.
   * - Throws: Rethrows any error thrown by the passed closure.
   */
  func asyncMap<T>(
    _ transform: (Element) async throws -> T
  ) async rethrows -> [T] {
    var values = [T]()
    for element in self {
      try await values.append(transform(element))
    }
    return values
  }

  /**
   * Transform the sequence into an array of new values using an async closure.
   *
   * The closure calls will be performed concurrently, but the call to this function won't return until all of the closure calls have completed.
   *
   * - Parameter withPriority: Any specific `TaskPriority` to assign to the async tasks that will perform the closure calls. The default is `nil` (meaning that the system picks a priority).
   * - Parameter useGroups: Whether to use task groups instead of a simple map operation.
   * - Parameter transform: The transform to run on each element.
   * - Returns: The transformed values as an array. The order of the transformed values will match the original sequence.
   */
  func concurrentMap<T>(
    withPriority priority: TaskPriority? = nil,
    useGroups: Bool = false,
    _ transform: @escaping (Element) async -> T
  ) async -> [T] where T: Equatable {
    if useGroups {
      return await withTaskGroup(of: NonNilResult<T>.self) { group in
        for (idx, element) in enumerated() {
          group.addTask(priority: priority) {
            return await NonNilResult(idx, transform(element))
          }
        }
        var res = [NonNilResult<T>]()
        while let next = await group.next() {
          res.append(next)
        }
        return res.sorted().map { $0.value }
      }
    } else {
      let tasks = map { element in
        Task(priority: priority) {
          await transform(element)
        }
      }
      return await tasks.asyncMap { task in
        await task.value
      }
    }
  }
  
  /**
   * Transform the sequence into an array of new values using an async closure.
   *
   * The closure calls will be performed concurrently, but the call to this function won't return until all of the closure calls have completed. If any of the closure calls throw an error, then the first error will be rethrown once all closure calls have completed.
   *
   * - Parameter withPriority: Any specific `TaskPriority` to assign to the async tasks that will perform the closure calls. The default as `nil` (meaning that the system picks a priority).
   * - Parameter useGroups: Whether to use the newer task groups-based implementation. Defaults to `false`.
   * - Parameter transform: The transform to run on each element.
   * - Returns: The transformed values as an array. The order of the transformed values will match the original sequence.
   * - Throws: Rethrows any error thrown by the passed closure.
   */
  func concurrentMap<T>(
    withPriority priority: TaskPriority? = nil,
    useGroups: Bool = false,
    _ transform: @escaping (Element) async throws -> T
  ) async throws -> [T] where T: Equatable {
    if useGroups {
      return try await withThrowingTaskGroup(of: NonNilResult<T>.self) { group in
        for (idx, element) in enumerated() {
          group.addTask(priority: priority) {
            return try await NonNilResult(idx, transform(element))
          }
        }
        var res = [NonNilResult<T>]()
        while let next = try await group.next() {
          res.append(next)
        }
        return res.sorted().map { $0.value }
      }
    } else {
      let tasks = map { element in
        Task(priority: priority) {
          try await transform(element)
        }
      }
      return try await tasks.asyncMap { task in
        try await task.value
      }
    }
  }
}

// MARK: - CompactMap
public extension Sequence {
  /**
   * Transform the sequence into an array of new values using an async closure that returns optional values. Only the non-`nil` return values will be included in the new array.
   *
   * The closure calls will be performed in order, by waiting for each call to complete before proceeding with the next one. If any of the closure calls throw an error, then the iteration will be terminated and the error rethrown.
   *
   * - Parameter transform: The transform to run on each element.
   * - Returns: The transformed values as an array. The order of the transformed values will match the original sequence, except for teh values that were transformed into `nil`.
   * - Throws: Rethrows any error thrown by the passed closure.
   */
  func asyncCompactMap<T>(
    _ transform: (Element) async throws -> T?
  ) async rethrows -> [T] {
    var values = [T]()
    for element in self {
      guard let value = try await transform(element) else {
        continue
      }
      values.append(value)
    }
    return values
  }
  
  /**
   * Transform the sequence into an array of new values using an async closure that returns optional values. Only the non-`nil` return values will be included in the new array.
   *
   * The closure calls will be performed concurrently, but the call to this function won't return until all of the closure calls have completed.
   *
   * - Parameter withPriority: Any specific `TaskPriority` to assign to the async tasks that will perform the closure calls. The default is `nil` (meaning that the system picks a priority).
   * - Parameter useGroups: Whether to use the newer task groups-based implementation. Defaults to `false`.
   * - Parameter transform: The transform to run on each element.
   * - Returns: The transformed values as an array. The order of the transformed values will match the original sequence, except for the values that were transformed into `nil`.
   */
  func concurrentCompactMap<T>(
    withPriority priority: TaskPriority? = nil,
    useGroups: Bool = false,
    _ transform: @escaping (Element) async -> T?
  ) async -> [T] where T: Equatable {
    if useGroups {
      return await withTaskGroup(of: NilResult<T>.self) { group in
        for (idx, element) in enumerated() {
          group.addTask(priority: priority) {
            return await NilResult(idx, transform(element))
          }
        }
        var res = [NonNilResult<T>]()
        while let next = await group.next() {
          if let v = next.value {
            res.append(NonNilResult(next.offset, v))
          }
        }
        return res.sorted().map { $0.value }
      }
    } else {
      let tasks = map { element in
        Task(priority: priority) {
          await transform(element)
        }
      }
      return await tasks.asyncCompactMap { task in
        await task.value
      }
    }
  }
  
  /**
   * Transform the sequence into an array of new values using an async closure that returns optional values. Only the non-`nil` return values will be included in the new array.
   *
   * The closure calls will be performed concurrently, but the call to this function won't return until all of the closure calls have completed. If any of the closure calls throw an error, then the first error will be rethrown once all closure calls have completed.
   *
   * - Parameter withPriority: Any specific `TaskPriority` to assign to the async tasks that will perform the closure calls. The default is `nil` (meaning that the system picks a priority).
   * - Parameter useGroups: Whether to use the newer task groups-based implementation. Defaults to `false`.
   * - Parameter transform: The transform to run on each element.
   * - Returns: The transformed values as an array. The order of the transformed values will match the original sequence, except for the values that were transformed into `nil`.
   * - Throws: Rethrows any error thrown by the passed closure.
   */
  func concurrentCompactMap<T>(
    withPriority priority: TaskPriority? = nil,
    useGroups: Bool = false,
    _ transform: @escaping (Element) async throws -> T?
  ) async throws -> [T] where T: Equatable {
    if useGroups {
      return try await withThrowingTaskGroup(of: NilResult<T>.self) { group in
        for (idx, element) in enumerated() {
          group.addTask(priority: priority) {
            return try await NilResult(idx, transform(element))
          }
        }
        var res = [NonNilResult<T>]()
        while let next = try await group.next() {
          if let v = next.value {
            res.append(NonNilResult(next.offset, v))
          }
        }
        return res.sorted().map { $0.value }
      }
    } else {
      let tasks = map { element in
        Task(priority: priority) {
          try await transform(element)
        }
      }
      return try await tasks.asyncCompactMap { task in
        try await task.value
      }
    }
  }
}

// MARK: - FlatMap
public extension Sequence {
  /**
   * Transform the sequence into an array of new values using an async closure that returns sequences. The returned sequences will be flattened into the array returned from this function.
   *
   * The closure calls will be performed in order, by waiting for each call to complete before proceeding with the next one. If any of the closure calls throw an error, then the iteration will be terminated and the error rethrown.
   *
   * - Parameter transform: The transform to run on each element.
   * - Returns: The transformed values as an array. The order of the transformed values will match the original sequence, with the results of each closure call appearing in-order within the returned array.
   * - Throws: Rethrows any error thrown by the passed closure.
   */
  func asyncFlatMap<T: Sequence>(
    _ transform: (Element) async throws -> T
  ) async rethrows -> [T.Element] {
    var values = [T.Element]()
    for element in self {
      try await values.append(contentsOf: transform(element))
    }
    return values
  }
  
  /**
   * Transform the sequence into an array of new values using an async closure that returns sequences. The returned sequences will be flattened into the array returned from this function.
   *
   * The closure calls will be performed concurrently, but the call to this function won't return until all of the closure calls have completed.
   *
   * - Parameter priority: Any specific `TaskPriority` to assign to the async tasks that will perform the closure calls. The default is `nil` (meaning that the system picks a priority).
   * - Parameter useGroups: Whether to use the newer task groups-based implementation. Defaults to `false`.
   * - Parameter transform: The transform to run on each element.
   * - Returns: The transformed values as an array. The order of the transformed values will match the original sequence, with the results of each closure call appearing in-order within the returned array.
   */
  func concurrentFlatMap<T: Sequence>(
    withPriority priority: TaskPriority? = nil,
    useGroups: Bool = false,
    _ transform: @escaping (Element) async -> T
  ) async -> [T.Element] where T: Equatable {
    if useGroups {
      return await withTaskGroup(of: NonNilResult<T>.self) { group in
        for (idx, element) in enumerated() {
          group.addTask(priority: priority) {
            return await NonNilResult(idx, transform(element))
          }
        }
        var res = [NonNilResult<T>]()
        while let next = await group.next() {
          res.append(next)
        }
        return res.sorted().flatMap { $0.value }
      }
    } else {
      let tasks = map { element in
        Task(priority: priority) {
          await transform(element)
        }
      }
      return await tasks.asyncFlatMap { task in
        await task.value
      }
    }
  }
  
  /**
   * Transform the sequence into an array of new values using an async closure that returns sequences. The returned sequences will be flattened into the array returned from this function.
   *
   * The closure calls will be performed concurrently, but the call to this function won't return until all of the closure calls have completed. If any of the closure calls throw an error, then the first error will be rethrown once all closure calls have completed.
   *
   * - Parameter priority: Any specific `TaskPriority` to assign to the async tasks that will perform the closure calls. The default is `nil` (meaning that the system picks a priority).
   * - Parameter useGroups: Whether to use the newer task groups-based implementation. Defaults to `false`.
   * - Parameter transform: The transform to run on each element.
   * - Returns: The transformed values as an array. The order of the transformed values will match the original sequence, with the results of each closure call appearing in-order with the returned array.
   * - Throws: Rethrows any error thrown by the passed closure.
   */
  func concurrentFlatMap<T: Sequence>(
    withPriority priority: TaskPriority? = nil,
    useGroups: Bool = false,
    _ transform: @escaping (Element) async throws -> T
  ) async throws -> [T.Element] where T: Equatable {
    if useGroups {
      return try await withThrowingTaskGroup(of: NonNilResult<T>.self) { group in
        for (idx, element) in enumerated() {
          group.addTask(priority: priority) {
            return try await NonNilResult(idx, transform(element))
          }
        }
        var res = [NonNilResult<T>]()
        while let next = try await group.next() {
          res.append(next)
        }
        return res.sorted().flatMap { $0.value }
      }
    } else {
      let tasks = map { element in
        Task(priority: priority) {
          try await transform(element)
        }
      }
      return try await tasks.asyncFlatMap { task in
        try await task.value
      }
    }
  }
}
