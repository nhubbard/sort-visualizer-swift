func mergeSort(_ array: [Int]) -> [Int] {
  guard array.count > 1 else { return array }
  let middleIndex = array.count / 2
  let leftArray = mergeSort(Array(array[0..<middleIndex]))
  let rightArray = mergeSort(Array(array[middleIndex..<array.count]))
  return merge(leftArray, rightArray)
}

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

var items: [Int] = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0]
print(mergeSort(items))
