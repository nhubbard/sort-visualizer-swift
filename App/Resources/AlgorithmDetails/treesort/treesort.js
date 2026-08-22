class Node {
  constructor(pointer) {
    this.pointer = pointer;
    this.left = null;
    this.right = null;
  }
}

function sort(arr) {
  const n = arr.length;
  let root = null;

  function add(node, addPtr) {
    if (node === null) {
      return new Node(addPtr);
    }
    if (arr[addPtr] < arr[node.pointer]) {
      node.left = add(node.left, addPtr);
    } else {
      node.right = add(node.right, addPtr);
    }
    return node;
  }

  for (let i = 0; i < n; i++) {
    root = add(root, i);
  }

  const result = [];

  function traverse(node) {
    if (node === null) {
      return;
    }
    traverse(node.left);
    result.push(arr[node.pointer]);
    traverse(node.right);
  }

  traverse(root);

  for (let i = 0; i < n; i++) {
    arr[i] = result[i];
  }
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
