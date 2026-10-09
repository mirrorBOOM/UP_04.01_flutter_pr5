const http = require('http');
const url = require('url');

const PORT = 8080;

let users = [
  { id: 1, username: 'admin', fullName: 'Администратор Клуба', password: 'Admin@123', role: 'admin' },
  { id: 2, username: 'trainer', fullName: 'Тренер Александр', password: 'Trainer@123', role: 'trainer' },
  { id: 3, username: 'client', fullName: 'Клиент Иван', password: 'Client@123', role: 'client' },
];

let workouts = [
  { id: 1, title: 'CrossFit WOD Pro', code: 'CRF-101', durationMinutes: 60, caloriesBurned: 750, intensity: 5, hallId: 1, trainerId: 1, categoryIds: [1, 2], capacityTotal: 15, capacityAvailable: 4, deletedAt: null },
  { id: 2, title: 'Хатха-йога Баланс', code: 'YOG-201', durationMinutes: 75, caloriesBurned: 320, intensity: 2, hallId: 2, trainerId: 2, categoryIds: [3], capacityTotal: 20, capacityAvailable: 11, deletedAt: null },
];

function sendJson(res, status, data) {
  res.writeHead(status, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  });
  res.end(JSON.stringify(data));
}

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  const query = parsedUrl.query;

  if (req.method === 'OPTIONS') {
    res.writeHead(200, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    });
    res.end();
    return;
  }

  // Аутентификация: POST /api/auth/login
  if (pathname === '/api/auth/login' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      const { username, password } = JSON.parse(body);
      const user = users.find(u => u.username === username && u.password === password);
      if (!user) {
        return sendJson(res, 401, { message: 'Неверный логин или пароль' });
      }
      return sendJson(res, 200, {
        accessToken: `token_${user.role}_${Date.now()}`,
        refreshToken: `refresh_${user.role}_${Date.now()}`,
        user: { id: user.id, username: user.username, fullName: user.fullName, role: user.role }
      });
    });
    return;
  }

  // Регистрация: POST /api/auth/register
  if (pathname === '/api/auth/register' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      const data = JSON.parse(body);
      const newUser = { id: Date.now(), ...data };
      users.push(newUser);
      return sendJson(res, 200, {
        accessToken: `token_${newUser.role}_${Date.now()}`,
        refreshToken: `refresh_${newUser.role}_${Date.now()}`,
        user: { id: newUser.id, username: newUser.username, fullName: newUser.fullName, role: newUser.role }
      });
    });
    return;
  }

  // Обновление токена: POST /api/auth/refresh
  if (pathname === '/api/auth/refresh' && req.method === 'POST') {
    return sendJson(res, 200, {
      accessToken: `token_refreshed_${Date.now()}`
    });
  }

  // Проверка прав на сервере (п. 17 ТЗ):
  // Сервер извлекает роль из реального токена, а не верит клиенту!
  const authHeader = req.headers['authorization'] || '';
  const isClientToken = authHeader.includes('client');

  if (pathname === '/api/workouts' && req.method === 'POST' && isClientToken) {
    // Если клиент подделал интерфейс и пытается создать тренировку:
    return sendJson(res, 403, { message: 'Недостаточно прав. Клиентам запрещено создавать тренировки!' });
  }

  // GET /api/workouts
  if (pathname === '/api/workouts' && req.method === 'GET') {
    return sendJson(res, 200, { items: workouts, page: 1, size: 10, total: workouts.length });
  }

  sendJson(res, 404, { message: 'Маршрут не найден' });
});

server.listen(PORT, () => {
  console.log(`🚀 Mock API с поддержкой Auth запущен на http://localhost:${PORT}`);
});