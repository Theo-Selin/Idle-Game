module.exports = {
  PORT: parseInt(process.env.PORT || "32123", 10),
  JWT_SECRET: process.env.JWT_SECRET || "dev-secret-change-me",
  ROOM_CAP: parseInt(process.env.ROOM_CAP || "3", 10),
  TICK_HZ: parseInt(process.env.TICK_HZ || "15", 10),
  SPEED: parseFloat(process.env.SPEED || "2.6"),
};
