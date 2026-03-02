const queue = [];

export function addTask(task) {
  queue.push(task);
}

export function getNextTask() {
  return queue.shift();
}

export function hasTasks() {
  return queue.length > 0;
}
