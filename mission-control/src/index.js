const express = require("express");
const app = express();
const port = process.env.PORT || 8012;

app.use(express.json());

// Enable CORS
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
  next();
});

app.get("/", (req, res) => {
  res.send("Mission Control is running");
});

app.get("/healthz", (req, res) => {
  res.status(200).json({ status: "healthy" });
});

app.get("/api/services", (req, res) => {
  // Return list of services and their status
  res.json({
    services: [
      { name: "slack-bot", status: "running", url: "http://localhost:8011" },
      { name: "rag-gateway", status: "running", url: "http://localhost:8013" },
      { name: "whatsapp-adapter", status: "running", url: "http://localhost:8014" }
    ]
  });
});

app.listen(port, () => {
  console.log(`Mission Control listening on port ${port}`);
  console.log(`Environment: ${process.env.ENVIRONMENT || "not set"}`);
});