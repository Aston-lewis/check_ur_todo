// Task store helpers. The panel owns the live array; this file only
// parses, sorts, and returns new arrays so QML bindings re-evaluate.

var RANK = { critical: 0, high: 1, medium: 2, low: 3 }
var COLOR = {
  critical: "#E24B4A",
  high: "#E8892D",
  medium: "#D4B43C",
  low: "#3D8FD9"
}
var LABEL = {
  critical: "Critical",
  high: "High",
  medium: "Medium",
  low: "Low"
}
var PRIORITY_OPTIONS = [
  { value: "critical", label: "Critical" },
  { value: "high", label: "High" },
  { value: "medium", label: "Medium" },
  { value: "low", label: "Low" }
]

function trim(value) {
  return String(value || "").replace(/^\s+|\s+$/g, "")
}

function priorityOptions() {
  return PRIORITY_OPTIONS
}

function normalizePriority(value) {
  var priority = String(value || "").toLowerCase()
  if (RANK[priority] !== undefined) return priority
  return "medium"
}

function rank(priority) {
  return RANK[normalizePriority(priority)]
}

function color(priority) {
  return COLOR[normalizePriority(priority)]
}

function label(priority) {
  return LABEL[normalizePriority(priority)]
}

function newId() {
  return Date.now().toString(36) + "-" + Math.floor(Math.random() * 1e9).toString(36)
}

function copyTask(task, overrides) {
  var next = {
    id: task.id,
    title: task.title,
    description: task.description,
    priority: task.priority,
    completed: task.completed === true,
    createdAt: task.createdAt,
    completedAt: task.completedAt
  }
  if (overrides) {
    for (var key in overrides) next[key] = overrides[key]
  }
  return next
}

function createTask(title, description, priority) {
  var now = Date.now()
  return {
    id: newId(),
    title: trim(title),
    description: trim(description),
    priority: normalizePriority(priority),
    completed: false,
    createdAt: now,
    completedAt: 0
  }
}

function normalizeTask(raw) {
  if (!raw || typeof raw !== "object") return null
  var title = trim(raw.title)
  if (title === "") return null
  return {
    id: String(raw.id || newId()),
    title: title,
    description: trim(raw.description),
    priority: normalizePriority(raw.priority),
    completed: raw.completed === true,
    createdAt: Number(raw.createdAt) || 0,
    completedAt: Number(raw.completedAt) || 0
  }
}

function parse(raw) {
  var text = trim(raw)
  if (text === "") return []
  try {
    var data = JSON.parse(text)
    var list = Array.isArray(data) ? data : (data && Array.isArray(data.tasks) ? data.tasks : [])
    var out = []
    for (var i = 0; i < list.length; i++) {
      var task = normalizeTask(list[i])
      if (task) out.push(task)
    }
    return out
  } catch (e) {
    return []
  }
}

function serialize(tasks) {
  return JSON.stringify({ version: 1, tasks: tasks || [] }, null, 2) + "\n"
}

function matches(task, query) {
  var needle = trim(query).toLowerCase()
  if (needle === "") return true
  return String(task.title || "").toLowerCase().indexOf(needle) >= 0
      || String(task.description || "").toLowerCase().indexOf(needle) >= 0
      || label(task.priority).toLowerCase().indexOf(needle) >= 0
}

function compareTasks(a, b) {
  var rankDelta = rank(a.priority) - rank(b.priority)
  if (rankDelta !== 0) return rankDelta
  if (a.completed && b.completed)
    return (Number(b.completedAt) || 0) - (Number(a.completedAt) || 0)
  return (Number(b.createdAt) || 0) - (Number(a.createdAt) || 0)
}

function listed(tasks, query, completed) {
  var list = tasks || []
  var out = []
  var wantComplete = completed === true
  for (var i = 0; i < list.length; i++) {
    var task = list[i]
    if (!task) continue
    if (!!task.completed !== wantComplete) continue
    if (!matches(task, query)) continue
    out.push(task)
  }
  out.sort(compareTasks)
  return out
}

function add(tasks, task) {
  if (!task || !task.title) return tasks || []
  return [task].concat(tasks || [])
}

function mapTasks(tasks, id, fn) {
  var list = tasks || []
  var out = []
  var changed = false
  for (var i = 0; i < list.length; i++) {
    var task = list[i]
    if (!task || task.id !== id) {
      out.push(task)
      continue
    }
    var next = fn(task)
    if (next === task) {
      out.push(task)
    } else {
      changed = true
      out.push(next)
    }
  }
  return changed ? out : list
}

function setCompleted(tasks, id, completed) {
  var now = Date.now()
  var done = completed === true
  return mapTasks(tasks, id, function(task) {
    if (!!task.completed === done) return task
    return copyTask(task, {
      completed: done,
      completedAt: done ? now : 0
    })
  })
}

function remove(tasks, id) {
  var list = tasks || []
  var out = []
  for (var i = 0; i < list.length; i++) {
    if (list[i] && list[i].id !== id) out.push(list[i])
  }
  return out
}

function updateTask(tasks, id, title, description, priority) {
  var nextTitle = trim(title)
  var nextDescription = trim(description)
  var nextPriority = normalizePriority(priority)
  if (nextTitle === "") return tasks || []
  return mapTasks(tasks, id, function(task) {
    if (task.title === nextTitle && task.description === nextDescription && task.priority === nextPriority)
      return task
    return copyTask(task, {
      title: nextTitle,
      description: nextDescription,
      priority: nextPriority
    })
  })
}

function ongoingCount(tasks) {
  var list = tasks || []
  var count = 0
  for (var i = 0; i < list.length; i++) {
    if (list[i] && !list[i].completed) count++
  }
  return count
}

function highestOngoing(tasks) {
  var list = tasks || []
  var best = ""
  var bestRank = 99
  for (var i = 0; i < list.length; i++) {
    var task = list[i]
    if (!task || task.completed) continue
    var taskRank = rank(task.priority)
    if (taskRank < bestRank) {
      bestRank = taskRank
      best = task.priority
    }
  }
  return best
}

function emptyMessage(query, activeTab, taskCount) {
  if (trim(query) !== "")
    return "No tasks match \u201c" + query + "\u201d"
  if (activeTab === "complete")
    return "Nothing completed yet"
  return taskCount === 0 ? "Nothing on the list yet" : "All caught up"
}

function badgeTooltip(count, highest) {
  if (count <= 0) return "Todo List"
  var head = count === 1 ? "1 ongoing" : count + " ongoing"
  if (highest === "critical" || highest === "high")
    return head + " · " + label(highest)
  return head
}

function cloneIdMap(map) {
  var next = {}
  var keys = Object.keys(map || {})
  for (var i = 0; i < keys.length; i++) next[keys[i]] = true
  return next
}
