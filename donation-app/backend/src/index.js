const express = require('express');
const cors = require('cors');
require('dotenv').config();

const donationRoutes = require('./routes/donations');
const { initDatabase } = require('./config/database');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/donations', donationRoutes);

// Health check
app.get('/api/health', (req, res) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Stats endpoint
app.get('/api/stats', async (req, res) => {
    try {
        const { pool } = require('./config/database');
        const [rows] = await pool.query(`
      SELECT 
        IFNULL(SUM(amount), 0) as total_raised,
        COUNT(*) as total_donations,
        COUNT(DISTINCT IF(is_anonymous = 0, donor_name, NULL)) as unique_donors
      FROM donations
    `);
        res.json(rows[0]);
    } catch (error) {
        console.error('Stats error:', error);
        res.status(500).json({ error: 'Failed to fetch stats' });
    }
});

// Initialize database and start server
initDatabase()
    .then(() => {
        app.listen(PORT, () => {
            console.log(`🚀 Server running on http://localhost:${PORT}`);
        });
    })
    .catch((err) => {
        console.error('Failed to initialize database:', err);
        process.exit(1);
    });
