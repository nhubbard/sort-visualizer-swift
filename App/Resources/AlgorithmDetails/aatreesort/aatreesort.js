class Node {
  constructor(value) {
    this.value = value;
    this.level = 0;
    this.left = null;
    this.right = null;
  }
}

function level(node) {
  return node === null ? -1 : node.level;
}

function skew(node) {
  if (node.left === null) {
    return node;
  }
  const l = node.left;
  node.left = l.right;
  l.right = node;
  return l;
}

function split(node) {
  if (node.right === null) {
    return node;
  }
  const r = node.right;
  node.right = r.left;
  r.left = node;
  r.level++;
  return r;
}

function add(node, value) {
  if (node === null) {
    return new Node(value);
  }
  if (value < node.value) {
    node.left = add(node.left, value);
    if (level(node.left) === node.level) {
      if (node.level !== level(node.right)) {
        return skew(node);
      }
      node.level++;
      return node;
    }
    return node;
  } else {
    node.right = add(node.right, value);
    if (level(node.right.right) === node.level) {
      return split(node);
    }
    return node;
  }
}

function sort(arr) {
  const n = arr.length;
  let root = null;

  for (let i = 0; i < n; i++) {
    root = add(root, arr[i]);
  }

  const result = [];

  function traverse(node) {
    if (node === null) {
      return;
    }
    traverse(node.left);
    result.push(node.value);
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
