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
var TAB_OPTIONS = [
  { value: "daily", label: "Daily" },
  { value: "backlog", label: "Backlog" },
  { value: "ongoing", label: "Ongoing" },
  { value: "complete", label: "Completed" }
]

function trim(value) {
  return String(value || "").replace(/^\s+|\s+$/g, "")
}

function priorityOptions() {
  return PRIORITY_OPTIONS
}

function tabOptions() {
  return TAB_OPTIONS
}

function localDateKey(date) {
  var value = date || new Date()
  var month = String(value.getMonth() + 1)
  var day = String(value.getDate())
  if (month.length < 2) month = "0" + month
  if (day.length < 2) day = "0" + day
  return value.getFullYear() + "-" + month + "-" + day
}

function normalizePriority(value) {
  var priority = String(value || "").toLowerCase()
  if (RANK[priority] !== undefined) return priority
  return "medium"
}

function normalizeStatus(status, completed) {
  var value = String(status || "").toLowerCase()
  if (value === "backlog" || value === "ongoing" || value === "complete") return value
  return completed === true ? "complete" : "ongoing"
}

function normalizeTab(tab) {
  var value = String(tab || "").toLowerCase()
  if (value === "daily" || value === "backlog" || value === "ongoing" || value === "complete") return value
  return "ongoing"
}

function addStatusForTab(tab) {
  return String(tab || "") === "backlog" ? "backlog" : "ongoing"
}

function cycleTab(current, direction) {
  var tabs = TAB_OPTIONS
  var i = 0
  for (; i < tabs.length; i++) if (tabs[i].value === current) break
  if (i >= tabs.length) i = 1
  var next = i + (direction > 0 ? 1 : -1)
  if (next < 0) next = tabs.length - 1
  if (next >= tabs.length) next = 0
  return tabs[next].value
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

function statusLabel(status) {
  var value = normalizeStatus(status, false)
  if (value === "backlog") return "Backlog"
  if (value === "complete") return "Completed"
  return "Ongoing"
}

function newId() {
  return Date.now().toString(36) + "-" + Math.floor(Math.random() * 1e9).toString(36)
}

function copyTask(task, overrides) {
  var status = normalizeStatus(task.status, task.completed)
  var next = {
    id: task.id,
    title: task.title,
    description: task.description,
    priority: task.priority,
    status: status,
    completed: status === "complete",
    createdAt: task.createdAt,
    completedAt: task.completedAt
  }
  if (overrides) {
    for (var key in overrides) next[key] = overrides[key]
  }
  next.status = normalizeStatus(next.status, next.completed)
  next.completed = next.status === "complete"
  return next
}

function createTask(title, description, priority, status) {
  var now = Date.now()
  var nextStatus = normalizeStatus(status, false)
  if (nextStatus === "complete") nextStatus = "ongoing"
  return {
    id: newId(),
    title: trim(title),
    description: trim(description),
    priority: normalizePriority(priority),
    status: nextStatus,
    completed: false,
    createdAt: now,
    completedAt: 0
  }
}

function createDailyTask(title, description) {
  var now = Date.now()
  return {
    id: "daily-" + newId(),
    title: trim(title),
    description: trim(description),
    completed: false,
    createdAt: now,
    completedAt: 0
  }
}

function normalizeTask(raw) {
  if (!raw || typeof raw !== "object") return null
  var title = trim(raw.title)
  if (title === "") return null
  var status = normalizeStatus(raw.status, raw.completed)
  return {
    id: String(raw.id || newId()),
    title: title,
    description: trim(raw.description),
    priority: normalizePriority(raw.priority),
    status: status,
    completed: status === "complete",
    createdAt: Number(raw.createdAt) || 0,
    completedAt: Number(raw.completedAt) || 0
  }
}

function normalizeDailyTask(raw) {
  if (!raw || typeof raw !== "object") return null
  var title = trim(raw.title)
  if (title === "") return null
  return {
    id: String(raw.id || ("daily-" + newId())),
    title: title,
    description: trim(raw.description),
    completed: raw.completed === true,
    createdAt: Number(raw.createdAt) || 0,
    completedAt: Number(raw.completedAt) || 0
  }
}

function parseStore(raw) {
  var empty = { tasks: [], dailyTasks: [], dailyResetDate: "", activeTab: "ongoing", valid: true }
  var text = trim(raw)
  if (text === "") return empty
  try {
    var data = JSON.parse(text)
    var list = Array.isArray(data) ? data : (data && Array.isArray(data.tasks) ? data.tasks : [])
    var dailyList = data && Array.isArray(data.dailyTasks) ? data.dailyTasks : []
    var out = []
    var dailyOut = []
    for (var i = 0; i < list.length; i++) {
      var task = normalizeTask(list[i])
      if (task) out.push(task)
    }
    for (var j = 0; j < dailyList.length; j++) {
      var dailyTask = normalizeDailyTask(dailyList[j])
      if (dailyTask) dailyOut.push(dailyTask)
    }
    return {
      tasks: out,
      dailyTasks: dailyOut,
      dailyResetDate: data && /^\d{4}-\d{2}-\d{2}$/.test(String(data.dailyResetDate || ""))
        ? String(data.dailyResetDate)
        : "",
      activeTab: normalizeTab(data && data.activeTab),
      valid: true
    }
  } catch (e) {
    return { tasks: [], dailyTasks: [], dailyResetDate: "", activeTab: "ongoing", valid: false }
  }
}

function parse(raw) {
  return parseStore(raw).tasks
}

function serialize(tasks, activeTab, dailyTasks, dailyResetDate) {
  return JSON.stringify({
    version: 2,
    activeTab: normalizeTab(activeTab),
    tasks: tasks || [],
    dailyTasks: dailyTasks || [],
    dailyResetDate: String(dailyResetDate || "")
  }, null, 2) + "\n"
}

function matches(task, query) {
  var needle = trim(query).toLowerCase()
  if (needle === "") return true
  return String(task.title || "").toLowerCase().indexOf(needle) >= 0
      || String(task.description || "").toLowerCase().indexOf(needle) >= 0
      || label(task.priority).toLowerCase().indexOf(needle) >= 0
      || statusLabel(task.status).toLowerCase().indexOf(needle) >= 0
}

function compareTasks(a, b) {
  var rankDelta = rank(a.priority) - rank(b.priority)
  if (rankDelta !== 0) return rankDelta
  if (a.status === "complete" && b.status === "complete")
    return (Number(b.completedAt) || 0) - (Number(a.completedAt) || 0)
  return (Number(b.createdAt) || 0) - (Number(a.createdAt) || 0)
}

function listed(tasks, query, status) {
  var list = tasks || []
  var want = normalizeStatus(status, false)
  var out = []
  for (var i = 0; i < list.length; i++) {
    var task = list[i]
    if (!task) continue
    if (normalizeStatus(task.status, task.completed) !== want) continue
    if (!matches(task, query)) continue
    out.push(task)
  }
  out.sort(compareTasks)
  return out
}

function listedDaily(tasks, query) {
  var list = tasks || []
  var out = []
  var needle = trim(query).toLowerCase()
  for (var i = 0; i < list.length; i++) {
    var task = list[i]
    if (!task) continue
    if (needle !== ""
        && String(task.title || "").toLowerCase().indexOf(needle) < 0
        && String(task.description || "").toLowerCase().indexOf(needle) < 0) continue
    out.push(task)
  }
  out.sort(function(a, b) {
    return (Number(b.createdAt) || 0) - (Number(a.createdAt) || 0)
  })
  return out
}

function add(tasks, task) {
  if (!task || !task.title) return tasks || []
  return [task].concat(tasks || [])
}

function addDaily(tasks, task) {
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

function setStatus(tasks, id, status) {
  var nextStatus = normalizeStatus(status, false)
  var now = Date.now()
  return mapTasks(tasks, id, function(task) {
    if (task.status === nextStatus) return task
    return copyTask(task, {
      status: nextStatus,
      completedAt: nextStatus === "complete" ? now : 0
    })
  })
}

function setCompleted(tasks, id, completed) {
  return setStatus(tasks, id, completed === true ? "complete" : "ongoing")
}

function setDailyCompleted(tasks, id, completed) {
  var value = completed === true
  return mapTasks(tasks, id, function(task) {
    if ((task.completed === true) === value) return task
    var next = {}
    for (var key in task) next[key] = task[key]
    next.completed = value
    next.completedAt = value ? Date.now() : 0
    return next
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

function removeDaily(tasks, id) {
  return remove(tasks, id)
}

function removeCompleted(tasks) {
  var list = tasks || []
  var out = []
  for (var i = 0; i < list.length; i++) {
    if (list[i] && normalizeStatus(list[i].status, list[i].completed) !== "complete")
      out.push(list[i])
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

function updateDailyTask(tasks, id, title, description) {
  var nextTitle = trim(title)
  var nextDescription = trim(description)
  if (nextTitle === "") return tasks || []
  return mapTasks(tasks, id, function(task) {
    if (task.title === nextTitle && task.description === nextDescription) return task
    var next = {}
    for (var key in task) next[key] = task[key]
    next.title = nextTitle
    next.description = nextDescription
    return next
  })
}

function resetDailyTasks(tasks) {
  var list = tasks || []
  var out = []
  var changed = false
  for (var i = 0; i < list.length; i++) {
    var task = list[i]
    if (!task || task.completed !== true) {
      out.push(task)
      continue
    }
    var next = {}
    for (var key in task) next[key] = task[key]
    next.completed = false
    next.completedAt = 0
    out.push(next)
    changed = true
  }
  return changed ? out : list
}

function rollDailyTasks(tasks, previousDate, currentDate) {
  var date = String(currentDate || "")
  if (String(previousDate || "") === date)
    return { tasks: tasks || [], dailyResetDate: date, changed: false }
  return {
    tasks: resetDailyTasks(tasks),
    dailyResetDate: date,
    changed: true
  }
}

function countStatus(tasks, status) {
  var list = tasks || []
  var want = normalizeStatus(status, false)
  var count = 0
  for (var i = 0; i < list.length; i++) {
    if (list[i] && normalizeStatus(list[i].status, list[i].completed) === want) count++
  }
  return count
}

function ongoingCount(tasks) {
  return countStatus(tasks, "ongoing")
}

function highestOngoing(tasks) {
  var list = tasks || []
  var best = ""
  var bestRank = 99
  for (var i = 0; i < list.length; i++) {
    var task = list[i]
    if (!task || normalizeStatus(task.status, task.completed) !== "ongoing") continue
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
  if (activeTab === "daily")
    return taskCount === 0 ? "No daily tasks yet" : "No daily tasks match"
  if (activeTab === "complete")
    return "Nothing completed yet"
  if (activeTab === "backlog")
    return "Nothing in the backlog"
  return taskCount === 0 ? "Nothing on the list yet" : "Nothing ongoing"
}

function badgeTooltip(count, highest) {
  if (count <= 0) return "Todo List (Daily)"
  var head = count === 1 ? "1 ongoing" : count + " ongoing"
  if (highest === "critical" || highest === "high")
    return head + " · " + label(highest) + " · Daily"
  return head + " · Daily"
}

function cloneIdMap(map) {
  var next = {}
  var keys = Object.keys(map || {})
  for (var i = 0; i < keys.length; i++) next[keys[i]] = true
  return next
}
