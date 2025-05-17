// Mock storage service that responds to basic HTTP requests
const express = require('express');
const cors = require('cors');
const app = express();
const port = process.env.PORT || 5000;

// Enable CORS
app.use(cors());

// Parse JSON body
app.use(express.json());

// Simple in-memory "database"
const buckets = [];
const objects = [];

// Logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// API routes

// Get all buckets
app.get('/buckets', (req, res) => {
  res.json(buckets);
});

// Create a bucket
app.post('/buckets', (req, res) => {
  const bucket = req.body;
  bucket.id = bucket.id || `bucket-${Date.now()}`;
  bucket.created_at = new Date().toISOString();
  bucket.updated_at = new Date().toISOString();
  buckets.push(bucket);
  res.status(201).json(bucket);
});

// Get a bucket
app.get('/buckets/:id', (req, res) => {
  const bucket = buckets.find(b => b.id === req.params.id);
  if (!bucket) {
    return res.status(404).json({ error: 'Bucket not found' });
  }
  res.json(bucket);
});

// Get all objects
app.get('/objects', (req, res) => {
  const bucketObjects = objects.filter(obj => obj.bucket_id === req.query.bucket_id);
  res.json(bucketObjects);
});

// Create an object
app.post('/objects', (req, res) => {
  const object = req.body;
  object.id = object.id || `object-${Date.now()}`;
  object.created_at = new Date().toISOString();
  object.updated_at = new Date().toISOString();
  object.last_accessed_at = new Date().toISOString();
  objects.push(object);
  res.status(201).json(object);
});

// Get an object
app.get('/objects/:id', (req, res) => {
  const object = objects.find(o => o.id === req.params.id);
  if (!object) {
    return res.status(404).json({ error: 'Object not found' });
  }
  object.last_accessed_at = new Date().toISOString();
  res.json(object);
});

// Default error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal Server Error' });
});

// Start server
app.listen(port, () => {
  console.log(`Mock Storage API running at http://localhost:${port}`);
});