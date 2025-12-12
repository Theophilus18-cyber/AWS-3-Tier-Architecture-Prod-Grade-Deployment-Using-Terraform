const mysql = require('mysql2/promise');
const { URL } = require('url');

//

const buildConfigFromUrl = (connectionString) => {
    const url = new URL(connectionString);
    return {
        host: url.hostname,
        port: url.port || 3306,
        user: url.username,
        password: url.password,
        database: url.pathname.replace('/', ''),
    };
};

const connectionConfig = process.env.DATABASE_URL
    ? buildConfigFromUrl(process.env.DATABASE_URL)
    : {
          host: process.env.DB_HOST,
          port: process.env.DB_PORT || 3306,
          user: process.env.DB_USER,
          password: process.env.DB_PASSWORD,
          database: process.env.DB_NAME,
      };

const pool = mysql.createPool({
    ...connectionConfig,
    waitForConnections: true,
    connectionLimit: 10,
    ssl:
        process.env.DB_SSL?.toLowerCase() === 'true'
            ? { rejectUnauthorized: false }
            : undefined,
});

const initDatabase = async () => {
    try {
        await pool.query(`
      CREATE TABLE IF NOT EXISTS donations (
        id INT AUTO_INCREMENT PRIMARY KEY,
        donor_name VARCHAR(100) NOT NULL,
        email VARCHAR(255),
        amount DECIMAL(10,2) NOT NULL,
        cause VARCHAR(100) NOT NULL,
        message TEXT,
        is_anonymous BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);
        console.log('✅ Database initialized');
    } catch (error) {
        console.error('❌ Database initialization failed:', error.message);
        if (process.env.NODE_ENV === 'production') throw error;
    }
};

module.exports = { pool, initDatabase };
