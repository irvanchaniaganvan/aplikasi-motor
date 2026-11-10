import assert from 'node:assert/strict';
import test from 'node:test';

import { handleRequest } from '../src/index.js';

const BASE_ENV = {
  GEMINI_API_KEY: 'test-gemini-key',
  GEMINI_MODEL: 'gemini-test',
  RATE_LIMIT_MAX: '10',
  RATE_LIMIT_WINDOW_SECONDS: '60',
};

function payload(overrides = {}) {
  return {
    install_id: 'c56a4180-65aa-42ec-a945-5fd21dec0538',
    question: 'Kapan sebaiknya ganti oli?',
    motor: {
      id: 'honda-vario-125',
      name: 'Honda Vario 125',
      oil_spec: {
        sae: '10W-30',
        jaso: 'JASO MB',
        volume: '0.8 L',
      },
    },
    history: [],
    reference: 'Panduan oli motor Rawatin.',
    ...overrides,
  };
}

function post(body) {
  return new Request('https://worker.test/ask-oil', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

function geminiResponse(answer, refused = false, reason) {
  const content = JSON.stringify({
    answer,
    refused,
    ...(reason ? { reason } : {}),
  });
  return new Response(
    JSON.stringify({
      candidates: [{ content: { parts: [{ text: content }] } }],
    }),
    {
      status: 200,
      headers: { 'content-type': 'application/json' },
    },
  );
}

function rawGeminiResponse(text, status = 200) {
  return new Response(
    JSON.stringify({
      candidates: [{ content: { parts: [{ text }] } }],
    }),
    {
      status,
      headers: { 'content-type': 'application/json' },
    },
  );
}

test('GET /health mengembalikan status ok', async () => {
  const response = await handleRequest(
    new Request('https://worker.test/health'),
    BASE_ENV,
  );

  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { status: 'ok' });
});

test('OPTIONS mengembalikan CORS untuk aplikasi web', async () => {
  const response = await handleRequest(
    new Request('https://worker.test/ask-oil', { method: 'OPTIONS' }),
    BASE_ENV,
  );

  assert.equal(response.status, 204);
  assert.equal(response.headers.get('access-control-allow-origin'), '*');
});

test('sapaan dijawab ramah tanpa memanggil Gemini', async () => {
  let called = false;
  const response = await handleRequest(post(payload({ question: 'halo' })), BASE_ENV, {
    fetchImpl: async () => {
      called = true;
      return geminiResponse('Jawaban provider.');
    },
  });

  const data = await response.json();
  assert.equal(response.status, 200);
  assert.equal(data.refused, false);
  assert.match(data.answer, /Halo!/);
  assert.equal(called, false);
});

test('ucapan terima kasih dijawab ramah tanpa memanggil Gemini', async () => {
  let called = false;
  const response = await handleRequest(
    post(payload({ question: 'terima kasih' })),
    BASE_ENV,
    {
      fetchImpl: async () => {
        called = true;
        return geminiResponse('Jawaban provider.');
      },
    },
  );

  const data = await response.json();
  assert.equal(data.refused, false);
  assert.match(data.answer, /Sama-sama/);
  assert.equal(called, false);
});

test('pertanyaan hari atau tanggal saat ini ditolak tanpa memanggil Gemini', async () => {
  let called = false;
  const response = await handleRequest(
    post(payload({ question: 'hari ini hari apa ya? tanggalnya?' })),
    BASE_ENV,
    {
      fetchImpl: async () => {
        called = true;
        return geminiResponse('Jawaban provider.');
      },
    },
  );

  const data = await response.json();
  assert.equal(response.status, 200);
  assert.equal(data.refused, true);
  assert.equal(data.reason, 'off_topic');
  assert.match(data.answer, /fokus membantu perawatan motor/);
  assert.equal(called, false);
});

test('install_id yang bukan UUID v4 ditolak', async () => {
  const response = await handleRequest(
    post(payload({ install_id: 'test-install-id' })),
    BASE_ENV,
  );

  assert.equal(response.status, 400);
  const data = await response.json();
  assert.equal(data.code, 'bad_request');
});

test('pertanyaan lebih dari 500 karakter ditolak dengan too_long', async () => {
  const response = await handleRequest(
    post(payload({ question: 'a'.repeat(501) })),
    BASE_ENV,
  );

  assert.equal(response.status, 400);
  const data = await response.json();
  assert.equal(data.code, 'too_long');
});

test('referensi lebih dari 10 KB ditolak', async () => {
  const response = await handleRequest(
    post(payload({ reference: 'a'.repeat(10 * 1024 + 1) })),
    BASE_ENV,
  );

  assert.equal(response.status, 400);
  const data = await response.json();
  assert.equal(data.code, 'bad_request');
});

test('riwayat lebih dari 6 pesan ditolak', async () => {
  const history = Array.from({ length: 7 }, (_, index) => ({
    role: index % 2 === 0 ? 'user' : 'assistant',
    content: `Pesan ${index}`,
  }));
  const response = await handleRequest(
    post(payload({ history })),
    BASE_ENV,
  );

  assert.equal(response.status, 400);
  const data = await response.json();
  assert.equal(data.code, 'bad_request');
});

test('permintaan valid memanggil Gemini dan mengembalikan answer', async () => {
  let capturedUrl;
  let capturedInit;
  const response = await handleRequest(post(payload()), BASE_ENV, {
    fetchImpl: async (url, init) => {
      capturedUrl = url;
      capturedInit = init;
      return geminiResponse('Ganti oli sesuai buku manual motor kamu.');
    },
  });

  const data = await response.json();
  assert.equal(response.status, 200);
  assert.equal(data.answer, 'Ganti oli sesuai buku manual motor kamu.');
  assert.equal(data.refused, false);
  assert.match(capturedUrl, /gemini-test:generateContent$/);
  assert.equal(capturedInit.headers['x-goog-api-key'], 'test-gemini-key');

  const providerBody = JSON.parse(capturedInit.body);
  assert.match(
    providerBody.system_instruction.parts[0].text,
    /Asisten Perawatan Motor Rawatin/,
  );
  assert.equal(providerBody.generationConfig.responseMimeType, 'application/json');
  assert.equal(providerBody.generationConfig.maxOutputTokens, 800);
  assert.equal(
    providerBody.generationConfig.thinkingConfig.thinkingLevel,
    'low',
  );
  assert.match(
    providerBody.contents.at(-1).parts[0].text,
    /Kapan sebaiknya ganti oli\?/,
  );
});

test('model default adalah gemini-3.5-flash-lite', async () => {
  const env = { ...BASE_ENV };
  delete env.GEMINI_MODEL;

  let capturedUrl;
  const response = await handleRequest(post(payload()), env, {
    fetchImpl: async (url) => {
      capturedUrl = url;
      return geminiResponse('Jawaban valid.');
    },
  });

  assert.equal(response.status, 200);
  assert.match(capturedUrl, /gemini-3\.5-flash-lite:generateContent$/);
});

test('respons Gemini yang bukan JSON valid menjadi server_error', async () => {
  const response = await handleRequest(post(payload()), BASE_ENV, {
    fetchImpl: async () => rawGeminiResponse('bukan json'),
  });

  assert.equal(response.status, 500);
  const data = await response.json();
  assert.equal(data.code, 'server_error');
});

test('status 429 dari Gemini diteruskan sebagai rate_limited', async () => {
  const response = await handleRequest(post(payload()), BASE_ENV, {
    fetchImpl: async () => new Response('quota', { status: 429 }),
  });

  assert.equal(response.status, 429);
  const data = await response.json();
  assert.equal(data.code, 'rate_limited');
});

test('tanpa GEMINI_API_KEY backend mengembalikan server_error', async () => {
  const env = { ...BASE_ENV };
  delete env.GEMINI_API_KEY;

  const response = await handleRequest(post(payload()), env);
  assert.equal(response.status, 500);
  const data = await response.json();
  assert.equal(data.code, 'server_error');
});

test('rate limit per install_id mengembalikan 429 setelah batas', async () => {
  const store = new Map();
  const kv = {
    async get(key) {
      return store.get(key) ?? null;
    },
    async put(key, value) {
      store.set(key, value);
    },
  };
  const env = {
    ...BASE_ENV,
    AI_RATE_LIMIT: kv,
    RATE_LIMIT_MAX: '1',
  };
  const now = () => 1700000000000;
  const fetchImpl = async () => geminiResponse('Jawaban valid.');

  const first = await handleRequest(post(payload()), env, { fetchImpl, now });
  const second = await handleRequest(post(payload()), env, { fetchImpl, now });

  assert.equal(first.status, 200);
  assert.equal(second.status, 429);
  assert.equal(second.headers.get('retry-after'), '60');
});
