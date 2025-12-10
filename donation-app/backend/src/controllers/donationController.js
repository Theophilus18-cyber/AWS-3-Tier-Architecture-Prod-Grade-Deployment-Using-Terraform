const { pool } = require('../config/database');

const SORTABLE_COLUMNS = ['created_at', 'amount', 'donor_name', 'id'];

// GET all donations
const getAllDonations = async (req, res) => {
    try {
        const { cause, sort = 'created_at', order = 'DESC' } = req.query;

        const sortColumn = SORTABLE_COLUMNS.includes(sort) ? sort : 'created_at';
        const sortDirection = order?.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

        let query = 'SELECT * FROM donations';
        const params = [];

        if (cause) {
            query += ' WHERE cause = ?';
            params.push(cause);
        }

        query += ` ORDER BY ${sortColumn} ${sortDirection}`;

        const [rows] = await pool.query(query, params);
        res.json(rows);
    } catch (error) {
        console.error('Error fetching donations:', error);
        res.status(500).json({ error: 'Failed to fetch donations' });
    }
};

// GET donation by ID
const getDonationById = async (req, res) => {
    try {
        const { id } = req.params;
        const [rows] = await pool.query('SELECT * FROM donations WHERE id = ?', [id]);

        if (rows.length === 0) {
            return res.status(404).json({ error: 'Donation not found' });
        }

        res.json(rows[0]);
    } catch (error) {
        console.error('Error fetching donation:', error);
        res.status(500).json({ error: 'Failed to fetch donation' });
    }
};

// POST create donation
const createDonation = async (req, res) => {
    try {
        const { donor_name, email, amount, cause, message, is_anonymous } = req.body;

        const [result] = await pool.query(
            `INSERT INTO donations (donor_name, email, amount, cause, message, is_anonymous)
       VALUES (?, ?, ?, ?, ?, ?)`,
            [donor_name, email, amount, cause, message, is_anonymous || false]
        );

        const [createdRows] = await pool.query('SELECT * FROM donations WHERE id = ?', [
            result.insertId,
        ]);

        res.status(201).json(createdRows[0]);
    } catch (error) {
        console.error('Error creating donation:', error);
        res.status(500).json({ error: 'Failed to create donation' });
    }
};

// PUT update donation
const updateDonation = async (req, res) => {
    try {
        const { id } = req.params;
        const { donor_name, email, amount, cause, message, is_anonymous } = req.body;

        const [result] = await pool.query(
            `UPDATE donations 
       SET donor_name = COALESCE(?, donor_name),
           email = COALESCE(?, email),
           amount = COALESCE(?, amount),
           cause = COALESCE(?, cause),
           message = COALESCE(?, message),
           is_anonymous = COALESCE(?, is_anonymous),
           updated_at = CURRENT_TIMESTAMP
       WHERE id = ?`,
            [donor_name, email, amount, cause, message, is_anonymous, id]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Donation not found' });
        }

        const [updatedRows] = await pool.query('SELECT * FROM donations WHERE id = ?', [id]);
        res.json(updatedRows[0]);
    } catch (error) {
        console.error('Error updating donation:', error);
        res.status(500).json({ error: 'Failed to update donation' });
    }
};

// DELETE donation
const deleteDonation = async (req, res) => {
    try {
        const { id } = req.params;

        const [rows] = await pool.query('SELECT * FROM donations WHERE id = ?', [id]);
        if (rows.length === 0) {
            return res.status(404).json({ error: 'Donation not found' });
        }

        await pool.query('DELETE FROM donations WHERE id = ?', [id]);

        res.json({ message: 'Donation deleted successfully', donation: rows[0] });
    } catch (error) {
        console.error('Error deleting donation:', error);
        res.status(500).json({ error: 'Failed to delete donation' });
    }
};

module.exports = {
    getAllDonations,
    getDonationById,
    createDonation,
    updateDonation,
    deleteDonation,
};
