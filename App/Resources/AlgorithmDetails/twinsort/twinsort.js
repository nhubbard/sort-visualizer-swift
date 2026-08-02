function reverseRange(arr, lo, hi) {
  while (lo < hi) {
    [arr[lo], arr[hi]] = [arr[hi], arr[lo]];
    lo++;
    hi--;
  }
}

function twinSwap(arr, nmemb) {
  let index = 0;
  let end = nmemb - 2;
  while (index <= end) {
    if (arr[index] <= arr[index + 1]) {
      index += 2;
      continue;
    }
    const start = index;
    index += 2;
    while (true) {
      if (index > end) {
        if (start === 0 && (nmemb % 2 === 0 || arr[index - 1] > arr[index])) {
          end = nmemb - 1;
          reverseRange(arr, start, end);
          return 1;
        }
        break;
      }
      if (arr[index] > arr[index + 1]) {
        if (arr[index - 1] > arr[index]) {
          index += 2;
          continue;
        }
        [arr[index], arr[index + 1]] = [arr[index + 1], arr[index]];
      }
      break;
    }
    end = index - 1;
    reverseRange(arr, start, end);
    end = nmemb - 2;
    index += 2;
  }
  return 0;
}

function tailMerge(arr, buf, nmemb, block) {
  const s = 0;
  while (block < nmemb) {
    let offset = 0;
    while (offset + block < nmemb) {
      const a = offset;
      let e = a + block - 1;
      if (arr[e] <= arr[e + 1]) {
        offset += block * 2;
        continue;
      }
      let cMax, dMax;
      if (offset + block * 2 <= nmemb) {
        cMax = s + block;
        dMax = a + block * 2;
      } else {
        cMax = s + nmemb - (offset + block);
        dMax = nmemb;
      }
      let d = dMax - 1;
      while (arr[e] <= arr[d]) {
        dMax--;
        d--;
        cMax--;
      }
      let c = s;
      d = a + block;
      while (c < cMax) {
        buf[c] = arr[d];
        c++;
        d++;
      }
      c--;
      d = a + block - 1;
      e = dMax - 1;
      if (arr[a] <= arr[a + block]) {
        arr[e] = arr[d];
        e--;
        d--;
        while (c >= s) {
          while (arr[d] > buf[c]) {
            arr[e] = arr[d];
            e--;
            d--;
          }
          arr[e] = buf[c];
          e--;
          c--;
        }
      } else {
        arr[e] = arr[d];
        e--;
        d--;
        while (d >= a) {
          while (arr[d] <= buf[c]) {
            arr[e] = buf[c];
            e--;
            c--;
          }
          arr[e] = arr[d];
          e--;
          d--;
        }
        while (c >= s) {
          arr[e] = buf[c];
          e--;
          c--;
        }
      }
      offset += block * 2;
    }
    block *= 2;
  }
}

function twinsort(arr, nmemb) {
  if (twinSwap(arr, nmemb) === 0) {
    const buf = new Array(Math.floor(nmemb / 2)).fill(0);
    tailMerge(arr, buf, nmemb, 2);
  }
}

function sort(arr) {
  const n = arr.length;
  twinsort(arr, n);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
