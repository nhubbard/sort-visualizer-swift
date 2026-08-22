class Node {
  constructor(value) {
    this.value = value;
    this.left = null;
    this.right = null;
    this.isRed = true;
  }
}

function isRed(node) {
  return node !== null && node.isRed;
}

function singleRotateRight(node) {
  const b = node.left;
  node.left = b.right;
  b.right = node;
  b.isRed = false;
  node.isRed = true;
  return b;
}

function singleRotateLeft(node) {
  const b = node.right;
  node.right = b.left;
  b.left = node;
  b.isRed = false;
  node.isRed = true;
  return b;
}

function doubleRotateRight(node) {
  node.left = singleRotateLeft(node.left);
  return singleRotateRight(node);
}

function doubleRotateLeft(node) {
  node.right = singleRotateRight(node.right);
  return singleRotateLeft(node);
}

function add(node, value) {
  if (node === null) {
    return { node: new Node(value), needsFix: false };
  }

  if (!node.isRed && isRed(node.left) && isRed(node.right)) {
    node.isRed = true;
    node.left.isRed = false;
    node.right.isRed = false;
  }

  if (value < node.value) {
    const child = add(node.left, value);
    node.left = child.node;
    if (child.needsFix) {
      if (isRed(node.left.left)) {
        return { node: singleRotateRight(node), needsFix: false };
      }
      return { node: doubleRotateRight(node), needsFix: false };
    }
    return { node: node, needsFix: node.isRed && isRed(node.left) };
  }

  const child = add(node.right, value);
  node.right = child.node;
  if (child.needsFix) {
    if (isRed(node.right.right)) {
      return { node: singleRotateLeft(node), needsFix: false };
    }
    return { node: doubleRotateLeft(node), needsFix: false };
  }
  return { node: node, needsFix: node.isRed && isRed(node.right) };
}

function traverse(node, result) {
  if (node === null) {
    return;
  }
  traverse(node.left, result);
  result.push(node.value);
  traverse(node.right, result);
}

function sort(arr) {
  const n = arr.length;
  let root = null;
  for (let i = 0; i < n; i++) {
    const inserted = add(root, arr[i]);
    root = inserted.node;
    root.isRed = false;
  }

  const result = [];
  traverse(root, result);

  for (let i = 0; i < n; i++) {
    arr[i] = result[i];
  }
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
