// A literal Bogo Bogo Sort re-derives the "is it sorted?" answer through a recursive sort of its
// own, so its real cost grows worse than n! squared -- even a handful of elements can take an
// unreasonable amount of time. To keep this example runnable, the true recursive algorithm below
// is only ever applied to a small leading slice of the array (CHAOS_LIMIT elements); the rest is
// finished with an ordinary insertion sort, and the two already-sorted pieces are merged back
// together at the end. The random reshuffle is also replaced with a deterministic, never-repeating
// permutation walk, so neither piece can wander into an unbounded random search.
const CHAOS_LIMIT = 5;

// Advances arr to its next lexicographic permutation in place. Returns false (after resetting
// arr to its first, fully ascending permutation) once every arrangement has been visited -- a
// deterministic stand-in for "shuffle the array at random".
function nextPermutation(arr) {
  const n = arr.length;
  let i = n - 2;
  while (i >= 0 && arr[i] >= arr[i + 1]) {
    i--;
  }
  if (i < 0) {
    arr.reverse();
    return false;
  }
  let j = n - 1;
  while (arr[j] <= arr[i]) {
    j--;
  }
  [arr[i], arr[j]] = [arr[j], arr[i]];
  const tail = arr.slice(i + 1).reverse();
  for (let k = 0; k < tail.length; k++) {
    arr[i + 1 + k] = tail[k];
  }
  return true;
}

// The heart of the joke: rather than scanning arr once, decide whether it is sorted by copying
// it, recursively Bogo-Bogo-sorting the copy's first n - 1 elements with this exact same process
// one level down, reshuffling the whole copy until its last two elements land in order, and
// comparing the result against the original. A match means the copy is now the true sorted
// arrangement of the same values, which is only possible if arr was already sorted.
function bogoBogoIsSorted(arr) {
  const n = arr.length;
  if (n <= 1) {
    return true;
  }
  const copy = arr.slice();
  let prefix = copy.slice(0, n - 1);
  bogoBogoSort(prefix);
  for (let k = 0; k < n - 1; k++) {
    copy[k] = prefix[k];
  }
  let candidate = 0;
  while (copy[n - 2] > copy[n - 1]) {
    [copy[candidate], copy[n - 1]] = [copy[n - 1], copy[candidate]];
    candidate++;
    prefix = copy.slice(0, n - 1);
    bogoBogoSort(prefix);
    for (let k = 0; k < n - 1; k++) {
      copy[k] = prefix[k];
    }
  }
  for (let k = 0; k < n; k++) {
    if (copy[k] !== arr[k]) {
      return false;
    }
  }
  return true;
}

function bogoBogoSort(arr) {
  while (!bogoBogoIsSorted(arr)) {
    nextPermutation(arr);
  }
}

function insertionSort(arr) {
  for (let i = 1; i < arr.length; i++) {
    const key = arr[i];
    let j = i - 1;
    while (j >= 0 && arr[j] > key) {
      arr[j + 1] = arr[j];
      j--;
    }
    arr[j + 1] = key;
  }
}

function mergeSorted(a, b) {
  const merged = [];
  let i = 0;
  let j = 0;
  while (i < a.length && j < b.length) {
    if (a[i] <= b[j]) {
      merged.push(a[i]);
      i++;
    } else {
      merged.push(b[j]);
      j++;
    }
  }
  while (i < a.length) {
    merged.push(a[i++]);
  }
  while (j < b.length) {
    merged.push(b[j++]);
  }
  return merged;
}

function sort(arr) {
  const n = arr.length;
  const limit = Math.min(CHAOS_LIMIT, n);
  const chaos = arr.slice(0, limit);
  const rest = arr.slice(limit);
  bogoBogoSort(chaos); // the real, recursive-check algorithm -- kept tiny on purpose
  insertionSort(rest); // an ordinary fast sort for everything past the demonstration slice
  const merged = mergeSorted(chaos, rest);
  for (let k = 0; k < n; k++) {
    arr[k] = merged[k];
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
