function isSorted(arr) {
  for (let i = 1; i < arr.length; i++)
    if (arr[i - 1] > arr[i])
      return false;
  return true;
}

function sort(arr) {
  let n = arr.length;
  while (!isSorted(arr)) {
    let i = Math.floor(Math.random() * n);
    let j = Math.floor(Math.random() * n);
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
}

var array = [0, 39, 21, 62, 91, 77];
sort(array);
console.log("[" + array.join(", ") + "]");
