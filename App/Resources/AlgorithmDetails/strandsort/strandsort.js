function mergeTo(arr, subList, a, m, b) {
  let i = 0;
  const s = m - a;
  while (i < s && m < b) {
    if (subList[i] < arr[m]) {
      arr[a] = subList[i];
      a++; i++;
    } else {
      arr[a] = arr[m];
      a++; m++;
    }
  }
  while (i < s) {
    arr[a] = subList[i];
    a++; i++;
  }
}

function sort(arr) {
  const n = arr.length;
  if (n < 2) return;

  let subList = [];

  let j = n;
  let k = j;
  while (j > 0) {
    subList[0] = arr[0];
    k--;

    let i = 0;
    let p = 0;
    for (let m = 1; m < j; m++) {
      if (arr[m] >= subList[i]) {
        i++;
        subList[i] = arr[m];
        k--;
      } else {
        arr[p] = arr[m];
        p++;
      }
    }

    mergeTo(arr, subList, k, j, n);
    j = k;
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
