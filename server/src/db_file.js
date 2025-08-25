const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const DATA_DIR = path.join(__dirname, "..", "data");
const FILE = path.join(DATA_DIR, "players.json");

function ensure() {
  if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
  if (!fs.existsSync(FILE))
    fs.writeFileSync(FILE, JSON.stringify({ players: [] }, null, 2));
}
function load() {
  ensure();
  return JSON.parse(fs.readFileSync(FILE, "utf8"));
}
function save(db) {
  fs.writeFileSync(FILE, JSON.stringify(db, null, 2));
}

function now() {
  return Math.floor(Date.now() / 1000);
}
function newId() {
  return crypto.randomUUID
    ? crypto.randomUUID()
    : Date.now().toString(36) + Math.random().toString(36).slice(2);
}

module.exports = {
  getByName(name) {
    const db = load();
    const n = String(name || "");
    return (
      db.players.find((p) => p.name.toLowerCase() === n.toLowerCase()) || null
    );
  },
  getById(id) {
    const db = load();
    return db.players.find((p) => p.id === id) || null;
  },
  create(name, avatar_id = 0) {
    const db = load();
    const row = {
      id: newId(),
      name: String(name),
      avatar_id,
      created_at: now(),
      updated_at: now(),
    };
    db.players.push(row);
    save(db);
    return row;
  },
  touch(id) {
    const db = load();
    const p = db.players.find((x) => x.id === id);
    if (p) {
      p.updated_at = now();
      save(db);
    }
  },
};
