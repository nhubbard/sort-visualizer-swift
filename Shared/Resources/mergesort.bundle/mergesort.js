function mergeSort(array) {
  const half = array.length / 2;
  if (array.length < 2) {
    return array;
  }
  const left = array.splice(0, half);
  return merge(mergeSort(left), mergeSort(array));
}

function merge(left, right) {
  let arr = [];
  while (left.length && right.length) {
    if (left[0] < right[0]) {
      arr.push(left.shift());
    } else {
      arr.push(right.shift());
    }
  }
  return [...arr, ...left, ...right];
}

var array = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0];
console.log(mergeSort(array));
