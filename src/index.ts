import express, { Request, Response } from 'express';
import cors from 'cors';
import multer from 'multer';
import { randomUUID } from 'crypto';
import { Pool } from 'pg';
import { Storage } from '@google-cloud/storage';

const app = express();
const port = process.env.PORT || 3000;

const {
  DB_USER = 'postgres',
  DB_PASSWORD = '',
  DB_NAME = 'notes',
  DB_HOST,
  INSTANCE_CONNECTION_NAME,
  BUCKET_NAME,
} = process.env;

const pool = new Pool({
  user: DB_USER,
  password: DB_PASSWORD,
  database: DB_NAME,
  // In Cloud Run, connect over the Cloud SQL Auth Proxy unix socket.
  // Locally, fall back to DB_HOST (e.g. 127.0.0.1) for `npm run dev`.
  ...(INSTANCE_CONNECTION_NAME
    ? { host: `/cloudsql/${INSTANCE_CONNECTION_NAME}` }
    : { host: DB_HOST || '127.0.0.1', port: 5432 }),
});

const storage = new Storage();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
});

async function initDb() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS notes (
      id SERIAL PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      photo_url TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `);
}

app.use(cors());
app.use(express.json());

app.get('/test', (req: Request, res: Response) => {
  res.send('Hello World');
});

app.get('/notes', async (req: Request, res: Response) => {
  try {
    const result = await pool.query(
      'SELECT id, title, description, photo_url AS "photoUrl", created_at AS "createdAt" FROM notes ORDER BY id DESC'
    );
    res.json(result.rows);
  } catch (err) {
    console.error('Failed to fetch notes', err);
    res.status(500).json({ error: 'Failed to fetch notes' });
  }
});

app.post('/notes', upload.single('photo'), async (req: Request, res: Response) => {
  const { title, description } = req.body;

  if (!title || !title.trim()) {
    res.status(400).json({ error: 'Title is required' });
    return;
  }

  try {
    let photoUrl: string | null = null;

    if (req.file && BUCKET_NAME) {
      const bucket = storage.bucket(BUCKET_NAME);
      const objectName = `${randomUUID()}-${req.file.originalname}`;
      const blob = bucket.file(objectName);

      await blob.save(req.file.buffer, {
        contentType: req.file.mimetype,
      });

      photoUrl = `https://storage.googleapis.com/${BUCKET_NAME}/${objectName}`;
    }

    const result = await pool.query(
      'INSERT INTO notes (title, description, photo_url) VALUES ($1, $2, $3) RETURNING id, title, description, photo_url AS "photoUrl", created_at AS "createdAt"',
      [title, description || null, photoUrl]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Failed to create note', err);
    res.status(500).json({ error: 'Failed to create note' });
  }
});

initDb()
  .then(() => {
    app.listen(port, () => {
      console.log(`Server listening on port ${port}`);
    });
  })
  .catch((err) => {
    console.error('Failed to initialize database', err);
    process.exit(1);
  });
