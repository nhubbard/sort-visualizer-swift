fun merge(left: List<Int>, right: List<Int>): List<Int> {
  var indexLeft = 0
  var indexRight = 0
  var newList: MutableList<Int> = mutableListOf()
  while (indexLeft < left.count() && indexRight < right.count()) {
    if (left[indexLeft] <= right[indexRight]) {
      newList.add(left[indexLeft])
      indexLeft++
    } else {
      newList.add(right[indexRight])
      indexRight++
    }
  }
  while (indexLeft < left.size) {
    newList.add(left[indexLeft])
    indexLeft++
  }
  while (indexRight < right.size) {
    newList.add(right[indexRight])
    indexRight++
  }
  return newList;
}

fun sort(list: List<Int>): List<Int> {
  if (list.size <= 1) {
    return list
  }
  val middle = list.size / 2
  var left = list.subList(0, middle)
  var right = list.subList(middle, list.size)
  return merge(sort(left), sort(right))
}

fun main() {
  var array = mutableListOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(sort(array).joinToString(", ")))
}