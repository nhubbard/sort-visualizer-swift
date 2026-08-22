function ceilPow2(value) {
  let r = 1;
  while (r < value) r *= 2;
  return r;
}

function sort(array) {
  const n = array.length;
  if (n <= 1) return;

  const size = ceilPow2(n) - 1;
  const mod = n % 2;
  const treeSize = n + size + mod;
  const tree = new Array(treeSize).fill(-1);

  const treeCompare = (a, b) => array[tree[a]] <= array[tree[b]];

  for (let i = size; i < treeSize - mod; i++) {
    tree[i] = i - size;
  }

  let j = size;
  let k = treeSize - mod;
  while (j > 0) {
    let i = j;
    while (i + 1 < k) {
      tree[Math.floor(i / 2)] = treeCompare(i, i + 1) ? tree[i] : tree[i + 1];
      i += 2;
    }
    if (i < k) {
      tree[Math.floor(i / 2)] = tree[i];
    }
    j = Math.floor(j / 2);
    k = Math.floor(k / 2);
  }

  function findNext() {
    let path = tree[0] + size;
    while (path > 0) {
      tree[path] = -1;
      path = Math.floor((path - 1) / 2);
    }

    let node = tree[0] + size;
    while (node > 0) {
      const sibling = node % 2 === 1 ? node + 1 : node - 1;
      const nodeValid = tree[node] !== -1;
      const siblingValid = tree[sibling] !== -1;
      let winner;
      if (nodeValid && siblingValid) {
        winner =
          node < sibling
            ? treeCompare(node, sibling)
              ? tree[node]
              : tree[sibling]
            : treeCompare(sibling, node)
              ? tree[sibling]
              : tree[node];
      } else if (nodeValid) {
        winner = tree[node];
      } else if (siblingValid) {
        winner = tree[sibling];
      } else {
        winner = -1;
      }
      node = Math.floor((node - 1) / 2);
      if (winner !== -1) {
        tree[node] = winner;
      }
    }
    return array[tree[0]];
  }

  const output = new Array(n);
  output[0] = array[tree[0]];
  for (let i = 1; i < n; i++) {
    output[i] = findNext();
  }
  for (let i = 0; i < n; i++) {
    array[i] = output[i];
  }
}

const array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log(`[${array.join(", ")}]`);
