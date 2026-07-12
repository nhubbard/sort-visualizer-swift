function isMinimum(arr, start, end) {
  for (let k = start + 1; k < end; k++)
    if (arr[start] > arr[k])
      return false;
  return true;
}

function isMaximum(arr, start, end) {
  for (let k = start; k < end - 1; k++)
    if (arr[k] > arr[end - 1])
      return false;
  return true;
}

function shuffleRange(arr, start, end) {
  for (let i = start; i < end - 1; i++) {
    let j = i + Math.floor(Math.random() * (end - i));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
}

function sort(arr) {
  let lo = 0;
  let hi = arr.length;
  while (lo < hi - 1) {
    if (isMinimum(arr, lo, hi))
      lo++;
    else if (isMaximum(arr, lo, hi))
      hi--;
    else
      shuffleRange(arr, lo, hi);
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23];
sort(array);
console.log("[" + array.join(", ") + "]");
