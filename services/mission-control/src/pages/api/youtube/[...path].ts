import type { NextApiRequest, NextApiResponse } from 'next';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const { path } = req.query;
  const apiPath = Array.isArray(path) ? path.join('/') : path;

  const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:9000';
  const targetUrl = `${API_URL}/api/youtube/${apiPath}`;

  try {
    const response = await fetch(targetUrl, {
      method: req.method,
      headers: {
        'Content-Type': 'application/json',
      },
      ...(req.body && { body: JSON.stringify(req.body) }),
    });

    const data = await response.json();

    if (!response.ok) {
      return res.status(response.status).json(data);
    }

    return res.status(200).json(data);
  } catch (error) {
    console.error('API proxy error:', error);
    return res.status(500).json({
      error: 'Failed to connect to Social Intelligence Agent',
      detail: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}
