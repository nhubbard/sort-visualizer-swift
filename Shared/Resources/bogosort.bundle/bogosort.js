function isSorted(arr) {
  for (let i = 1; i < arr.length; i++)
    if (arr[i - 1] > arr[i])
      return false;
  return true;
}

function shuffle(arr) {
  let n = arr.length;
  let i;
  while (n > 0) {
    i = Math.floor(Math.random() * n);
    n--;
    [arr[n], arr[i]] = [arr[i], arr[n]];
  }
}

function sort(arr) {
  while (!isSorted(arr))
    shuffle(arr);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23];
sort(array);
console.log("[" + array.join(", ") + "]");
