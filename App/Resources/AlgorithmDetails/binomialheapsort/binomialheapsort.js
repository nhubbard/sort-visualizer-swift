function sort(arr) {
  const n = arr.length;

  let index = 2;
  while (index <= n) {
    let maxNode = index;
    while (true) {
      let focus = maxNode;
      let depth = 1;
      while ((focus & depth) === 0) {
        if (arr[focus - depth - 1] > arr[maxNode - 1]) {
          maxNode = focus - depth;
        }
        depth *= 2;
      }
      if (focus !== maxNode) {
        [arr[focus - 1], arr[maxNode - 1]] = [arr[maxNode - 1], arr[focus - 1]];
      }
      if (focus === maxNode) {
        break;
      }
    }
    index += 2;
  }

  index = n;
  while (index > 2) {
    let maxNode = index;
    let focus = index;
    let depth = 1;
    while (focus !== 0) {
      if ((focus & depth) !== 0) {
        if (arr[focus - 1] > arr[maxNode - 1]) {
          maxNode = focus;
        }
        focus -= depth;
      }
      depth *= 2;
    }

    if (maxNode !== index) {
      focus = index;
      while (true) {
        [arr[focus - 1], arr[maxNode - 1]] = [arr[maxNode - 1], arr[focus - 1]];
        focus = maxNode;
        let innerDepth = 1;
        while ((focus & innerDepth) === 0) {
          if (arr[focus - innerDepth - 1] > arr[maxNode - 1]) {
            maxNode = focus - innerDepth;
          }
          innerDepth *= 2;
        }
        if (focus === maxNode) {
          break;
        }
      }
    }
    index -= 1;
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
