function sort(arr) {
  const n = arr.length;
  if (n === 0) return arr;

  const minValue = Math.min.apply(null, arr);
  const maxValue = Math.max.apply(null, arr);
  const auxLength = maxValue - minValue;
  const aux = new Array(auxLength).fill(0);

  function transferTo(index) {
    let pointer = 0;
    while (arr[index] > minValue) {
      arr[index]--;
      aux[pointer]++;
      pointer++;
    }
  }

  function transferFrom(index) {
    let pointer = 0;
    while (pointer < auxLength && aux[pointer] !== 0) {
      arr[index]++;
      aux[pointer]--;
      pointer++;
    }
  }

  for (let i = 0; i < n; i++) {
    transferTo(i);
  }
  for (let i = n - 1; i >= 0; i--) {
    transferFrom(i);
  }

  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
