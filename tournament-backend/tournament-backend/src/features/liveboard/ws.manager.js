const { WebSocketServer, WebSocket } = require('ws');
const { EventEmitter } = require('events');
const jwtUtil = require('../../core/utils/jwt');
const logger = require('../../core/utils/logger');

class WebSocketManager {
  constructor(httpServer, liveboardService) {
    this.liveboardService = liveboardService;
    this.rooms = new Map();         // tournamentId → Set<WebSocket>
    this.clientMeta = new WeakMap(); // ws → { userId, tournamentId }
    this.localBus = new EventEmitter();

    this.wss = new WebSocketServer({ server: httpServer, path: '/ws' });

    this.localBus.on('liveboard:updates', (tournamentId, payload) => {
      try {
        this._broadcastToLocalRoom(tournamentId, payload);
      } catch (err) {
        logger.error('WS local event parse error', { err: err.message });
      }
    });

    this.wss.on('connection', (ws, req) => this._handleConnection(ws, req));

    // Heartbeat every 30s
    this._heartbeatInterval = setInterval(() => this._sendHeartbeats(), 30000);
    this.wss.on('close', () => clearInterval(this._heartbeatInterval));
  }

  _handleConnection(ws, req) {
    try {
      const url = new URL('http://host' + req.url);
      const parts = url.pathname.split('/').filter(Boolean);
      // Expected: /ws/tournament/:id
      const tournamentIdx = parts.indexOf('tournament');
      const tournamentId = tournamentIdx !== -1 ? parts[tournamentIdx + 1] : null;
      const token = url.searchParams.get('token');

      if (!token || !tournamentId) {
        ws.close(4001, 'Missing token or tournament ID');
        return;
      }

      let decoded;
      try {
        decoded = jwtUtil.verifyAccess(token);
      } catch {
        ws.close(4001, 'Unauthorized');
        return;
      }

      // Add to room
      if (!this.rooms.has(tournamentId)) this.rooms.set(tournamentId, new Set());
      this.rooms.get(tournamentId).add(ws);
      this.clientMeta.set(ws, { userId: decoded.sub, tournamentId });
      ws.isAlive = true;

      ws.on('pong', () => { ws.isAlive = true; });

      // Send initial state
      this.liveboardService.getParticipants(tournamentId)
        .then((participants) => {
          if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({ type: 'INITIAL_STATE', participants, timestamp: new Date() }));
          }
        })
        .catch((err) => logger.error('WS initial state error', { err: err.message }));

      ws.on('close', () => {
        const meta = this.clientMeta.get(ws);
        if (meta) {
          this.rooms.get(meta.tournamentId)?.delete(ws);
          if (this.rooms.get(meta.tournamentId)?.size === 0) {
            this.rooms.delete(meta.tournamentId);
          }
        }
      });

      ws.on('error', (err) => logger.error('WebSocket client error', { err: err.message }));

    } catch (err) {
      logger.error('WS connection handler error', { err: err.message });
      ws.close(4000, 'Internal error');
    }
  }

  async broadcastUpdate(tournamentId, payload) {
    this.localBus.emit('liveboard:updates', tournamentId, payload);
  }

  _broadcastToLocalRoom(tournamentId, payload) {
    const room = this.rooms.get(tournamentId);
    if (!room) return;
    const data = JSON.stringify(payload);
    for (const ws of room) {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(data);
      }
    }
  }

  _sendHeartbeats() {
    for (const [, room] of this.rooms) {
      for (const ws of room) {
        if (!ws.isAlive) {
          ws.terminate();
          continue;
        }
        ws.isAlive = false;
        ws.ping();
      }
    }
  }

  getRoomSize(tournamentId) {
    return this.rooms.get(tournamentId)?.size || 0;
  }
}

module.exports = WebSocketManager;
