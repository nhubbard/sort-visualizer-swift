func merge(_ left: [Int], _ right: [Int]) -> [Int] {
  var leftIndex = 0
  var rightIndex = 0
  var orderedArray: [Int] = []
  while leftIndex < left.count && rightIndex < right.count {
    let leftElement = left[leftIndex]
    let rightElement = right[rightIndex]
    if leftElement < rightElement {
      orderedArray.append(leftElement)
      leftIndex += 1
    } else if leftElement > rightElement {
      orderedArray.append(rightElement)
      rightIndex += 1
    } else { 
      orderedArray.append(leftElement)
      leftIndex += 1
      orderedArray.append(rightElement)
      rightIndex += 1
    }
  }
  while leftIndex < left.count {
    orderedArray.append(left[leftIndex])
    leftIndex += 1
  }
  while rightIndex < right.count {
    orderedArray.append(right[rightIndex])
    rightIndex += 1
  }
  return orderedArray
}

func sort(_ array: [Int]) -> [Int] {
  guard array.count > 1 else { return array }
  let middleIndex = array.count / 2
  let leftArray = sort(Array(array[0..<middleIndex]))
  let rightArray = sort(Array(array[middleIndex..<array.count]))
  return merge(leftArray, rightArray)
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
array = sort(array)
print(array)