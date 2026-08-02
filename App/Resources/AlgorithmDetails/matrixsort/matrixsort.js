function sort(arr) {
  function dirCompareVal(left, right, dir) {
    let res;
    if (left > right) {
      res = 1;
    } else if (left < right) {
      res = -1;
    } else {
      res = 0;
    }
    return dir ? res : -res;
  }

  function gapReverse(start, end, gap) {
    let i = start;
    let j = end;
    while (i < j) {
      const tmp = arr[i];
      arr[i] = arr[j - gap];
      arr[j - gap] = tmp;
      i += gap;
      j -= gap;
    }
  }

  function insertLast(a, b, gap, dir) {
    let did = false;
    const key = arr[b];
    let j = b - gap;
    while (j >= a && dirCompareVal(key, arr[j], dir) < 0) {
      arr[j + gap] = arr[j];
      did = true;
      j -= gap;
    }
    arr[j + gap] = key;
    return did;
  }

  function getMatrixDims(length) {
    let dim = Math.floor(Math.sqrt(length));
    const insertLastFlag = dim * dim === length - 1;
    while (length % dim !== 0) {
      dim -= 1;
    }
    const width = dim;
    const height = Math.floor(length / dim);
    const unbalanced = (width === 1) !== (height === 1);
    return { width: width, insertLast: unbalanced || insertLastFlag };
  }

  function matrixSort(start, end, gap, dir) {
    const length = Math.floor((end - start) / gap);
    if (length < 2) {
      return false;
    } else if (length <= 16) {
      let did = false;
      let i = start;
      while (i < end) {
        did = insertLast(start, i, gap, dir) || did;
        i += gap;
      }
      return did;
    } else {
      const matShape = getMatrixDims(length);
      if (matShape.insertLast) {
        const did1 = matrixSort(start, end - gap, gap, dir);
        const did2 = insertLast(start, end - gap, gap, dir);
        return did1 || did2;
      }

      let i = start + matShape.width * gap;
      while (i < end) {
        gapReverse(i, i + matShape.width * gap, gap);
        i += 2 * matShape.width * gap;
      }

      let did = false;
      let newdid = true;
      while (newdid) {
        newdid = false;
        let curdir = dir;
        i = start;
        while (i < end) {
          newdid =
            matrixSort(i, i + matShape.width * gap, gap, curdir) || newdid;
          did = did || newdid;
          curdir = !curdir;
          i += matShape.width * gap;
        }

        newdid = false;
        for (let k = 0; k < matShape.width; k++) {
          newdid =
            matrixSort(
              start + k * gap,
              end + k * gap,
              gap * matShape.width,
              dir,
            ) || newdid;
          did = did || newdid;
        }
      }
      i = start + matShape.width * gap;
      while (i < end) {
        gapReverse(i, i + matShape.width * gap, gap);
        i += 2 * matShape.width * gap;
      }

      return did;
    }
  }

  matrixSort(0, arr.length, 1, true);
}

var array = [
  15, 3, 22, 8, 19, 1, 24, 11, 6, 20, 9, 17, 2, 14, 23, 5, 18, 0, 12, 21, 7, 16,
  4, 13, 10,
];
sort(array);
console.log("[" + array.join(", ") + "]");
