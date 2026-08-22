function sort(arr) {
  var length = arr.length;
  var a = 1;
  while (a < length) {
    var b = a;
    var c = 0;
    while (b < length) {
      if (arr[b - a] > arr[b]) {
        var temp = arr[b - a];
        arr[b - a] = arr[b];
        arr[b] = temp;
      }
      c = (c + 1) % a;
      b++;
      if (c === 0) b += a;
    }
    a *= 2;
  }

  a = Math.floor(a / 4);
  var e = 1;
  while (a > 0) {
    var d = e;
    while (d > 0) {
      var b2 = (d + 1) * a;
      var c2 = 0;
      while (b2 < length) {
        if (arr[b2 - d * a] > arr[b2]) {
          var temp2 = arr[b2 - d * a];
          arr[b2 - d * a] = arr[b2];
          arr[b2] = temp2;
        }
        c2 = (c2 + 1) % a;
        b2++;
        if (c2 === 0) b2 += a;
      }
      d = Math.floor(d / 2);
    }
    a = Math.floor(a / 2);
    e = e * 2 + 1;
  }
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
