const net = require("net");
const jwt = require("jsonwebtoken");
const CFG = require("./config");
const DB = require("./db_file"); // file DB (works on Node 22)

const TICK_MS = Math.max(10, Math.floor(1000 / (CFG.TICK_HZ || 15)));

// --- helpers ---
function writePacket(sock, obj) {
  const js = Buffer.from(JSON.stringify(obj), "utf8");
  const len = Buffer.alloc(4);
  len.writeUInt32LE(js.length, 0);
  try {
    sock.write(Buffer.concat([len, js]));
  } catch (_) {}
}
function tokenFor(pid, kind = "user", ttlSec = 7 * 24 * 60 * 60) {
  return jwt.sign({ sub: pid, kind }, CFG.JWT_SECRET, { expiresIn: ttlSec });
}
function verifyToken(tok) {
  try {
    return jwt.verify(tok, CFG.JWT_SECRET);
  } catch {
    return null;
  }
}

// --- one simple room (shard later) ---
const room = {
  id: "HOME_OUTSIDE#A",
  playersBySock: new Map(), // sock -> runtime state
  index: new Map(), // pid  -> sock
};
function broadcast(exceptSock, obj) {
  for (const s of room.playersBySock.keys())
    if (s !== exceptSock) writePacket(s, obj);
}

// --- TCP server ---
const server = net.createServer((sock) => {
  let buf = Buffer.alloc(0);
  let auth = null; // { pid, name, avatar_id }
  let player = null; // { pid,name,look,x,y,tx,ty,dir,a }

  sock.on("data", (chunk) => {
    buf = Buffer.concat([buf, chunk]);
    while (buf.length >= 4) {
      const len = buf.readUInt32LE(0);
      if (buf.length < 4 + len) break;
      const js = buf.slice(4, 4 + len).toString("utf8");
      buf = buf.slice(4 + len);

      let msg = {};
      try {
        msg = JSON.parse(js);
      } catch {
        continue;
      }
      const t = msg.t || msg.op;

      if (t === "AUTH_CREATE") {
        const name = String(msg.name || "").trim();
        if (name.length < 3 || name.length > 16) {
          writePacket(sock, { v: 1, t: "ERROR", code: "BAD_NAME" });
          continue;
        }
        if (DB.getByName(name)) {
          writePacket(sock, { v: 1, t: "ERROR", code: "NAME_TAKEN" });
          continue;
        }
        const row = DB.create(name, 0);
        const tok = tokenFor(row.id);
        auth = { pid: row.id, name: row.name, avatar_id: row.avatar_id };
        writePacket(sock, {
          v: 1,
          t: "AUTH_OK",
          pid: row.id,
          name: row.name,
          look: { avatar_id: row.avatar_id, equip: [0, 0, 0, 0, 0, 0] },
          token: tok,
        });
      } else if (t === "AUTH_TOKEN") {
        const pay = verifyToken(String(msg.token || ""));
        if (!pay) {
          writePacket(sock, { v: 1, t: "ERROR", code: "AUTH_FAIL" });
          continue;
        }
        const row = DB.getById(pay.sub);
        if (!row) {
          writePacket(sock, { v: 1, t: "ERROR", code: "UNKNOWN_PLAYER" });
          continue;
        }
        auth = { pid: row.id, name: row.name, avatar_id: row.avatar_id };
        writePacket(sock, {
          v: 1,
          t: "AUTH_OK",
          pid: row.id,
          name: row.name,
          look: { avatar_id: row.avatar_id, equip: [0, 0, 0, 0, 0, 0] },
        });
      } else if (t === "JOIN") {
        if (!auth) {
          writePacket(sock, { v: 1, t: "ERROR", code: "NEED_AUTH" });
          continue;
        }
        if (room.playersBySock.size >= (CFG.ROOM_CAP || 3)) {
          writePacket(sock, { v: 1, t: "ERROR", code: "ROOM_FULL" });
          continue;
        }
        player = {
          pid: auth.pid,
          name: auth.name,
          look: { avatar_id: auth.avatar_id, equip: [0, 0, 0, 0, 0, 0] },
          x: 64,
          y: 64,
          tx: 64,
          ty: 64,
          dir: 2,
          a: "idle",
        };
        room.playersBySock.set(sock, player);
        room.index.set(player.pid, sock);
        DB.touch(player.pid);

        // existing occupants to newcomer
        for (const [, p] of room.playersBySock) {
          if (p === player) continue;
          writePacket(sock, {
            v: 1,
            t: "JOINED",
            pid: p.pid,
            name: p.name,
            look: p.look,
          });
        }
        // announce newcomer
        broadcast(sock, {
          v: 1,
          t: "JOINED",
          pid: player.pid,
          name: player.name,
          look: player.look,
        });
      } else if (t === "MOVE") {
        if (!player) continue;
        if (Array.isArray(msg.p) && msg.p.length === 2) {
          player.tx = msg.p[0] | 0;
          player.ty = msg.p[1] | 0;
        }
      }
    }
  });

  sock.on("close", () => {
    if (player) {
      room.playersBySock.delete(sock);
      room.index.delete(player.pid);
      broadcast(null, { v: 1, t: "LEFT", pid: player.pid });
    }
  });
  sock.on("error", () => {
    try {
      sock.destroy();
    } catch (_) {}
  });
});

server.listen(CFG.PORT, () => {
  console.log(
    `IdleRPG server on ${CFG.PORT} (tick=${Math.round(1000 / TICK_MS)}Hz, cap=${
      CFG.ROOM_CAP
    })`
  );
});

// --- tick: authoritative movement + snapshots ---
setInterval(() => {
  for (const p of room.playersBySock.values()) {
    const dx = p.tx - p.x,
      dy = p.ty - p.y;
    const d2 = dx * dx + dy * dy;
    if (d2 > 1) {
      const d = Math.sqrt(d2);
      const spd = Number(CFG.SPEED) || 2.6;
      p.x += (dx / d) * spd;
      p.y += (dy / d) * spd;
      p.a = "walk";
      p.dir = Math.abs(dx) > Math.abs(dy) ? (dx > 0 ? 1 : 3) : dy > 0 ? 2 : 0;
    } else {
      p.a = "idle";
    }
  }
  const snap = { v: 1, t: "SNAP", players: [] };
  for (const p of room.playersBySock.values())
    snap.players.push({
      pid: p.pid,
      p: [p.x | 0, p.y | 0],
      d: p.dir | 0,
      a: p.a,
    });
  for (const s of room.playersBySock.keys()) writePacket(s, snap);
}, TICK_MS);
