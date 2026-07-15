function sort(arr) {
  const n = arr.length;

  function height(node) {
    let count = 0;
    while ((node >> count) % 2 === 1) {
      count += 1;
    }
    return count;
  }

  function thrift(node, parentFlag, rootFlag) {
    const isRoot = rootFlag && (node >= (1 << height(node)));
    if (!isRoot && !parentFlag) {
      return;
    }

    let choice = height(node) - (isRoot ? 0 : 1);
    if (parentFlag) {
      for (let child = choice - 1; child >= 0; child--) {
        if (arr[node - (1 << choice)] <= arr[node - (1 << child)]) {
          choice = child;
        }
      }
    }

    if (arr[node - (1 << choice)] <= arr[node]) {
      return;
    }

    const temp = arr[node];
    arr[node] = arr[node - (1 << choice)];
    arr[node - (1 << choice)] = temp;
    const nextNode = node - (1 << choice);
    thrift(nextNode, nextNode % 2 === 1, choice === height(node));
  }

  let node = 1;
  while (node < n) {
    thrift(node, node % 2 === 1, (node + (1 << height(node))) >= n);
    node += 1;
  }

  node -= (node - 1) % 2;
  while (node > 2) {
    for (let child = height(node) - 1; child >= 0; child--) {
      thrift(node - (1 << child), false, true);
    }
    node -= 2;
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
