function sort(arr) {
  function sortRange(start, end) {
    const length = end - start;
    if (length < 2) return;

    const bounds = Array.from(
      { length: 6 },
      (_, part) => start + Math.floor((length * part) / 5),
    );
    for (let part = 0; part < 5; part += 1) {
      sortRange(bounds[part], bounds[part + 1]);
    }

    const positions = bounds.slice(0, 5);
    const merged = [];
    while (merged.length < length) {
      let best = -1;
      for (let part = 0; part < 5; part += 1) {
        if (
          positions[part] < bounds[part + 1] &&
          (best < 0 || arr[positions[part]] < arr[positions[best]])
        ) {
          best = part;
        }
      }
      merged.push(arr[positions[best]]);
      positions[best] += 1;
    }
    for (let offset = 0; offset < length; offset += 1) {
      arr[start + offset] = merged[offset];
    }
  }

  sortRange(0, arr.length);
}

const array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
