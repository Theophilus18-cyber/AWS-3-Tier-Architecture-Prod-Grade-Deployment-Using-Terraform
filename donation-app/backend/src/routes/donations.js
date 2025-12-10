const express = require('express');
const { body, validationResult } = require('express-validator');
const donationController = require('../controllers/donationController');

const router = express.Router();

// Validation rules
const donationValidation = [
    body('donor_name').trim().notEmpty().withMessage('Donor name is required'),
    body('amount').isFloat({ min: 1 }).withMessage('Amount must be at least 1'),
    body('cause').trim().notEmpty().withMessage('Cause is required'),
    body('email').optional().isEmail().withMessage('Invalid email format'),
];

// Validation middleware
const validate = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }
    next();
};

// Routes
router.get('/', donationController.getAllDonations);
router.get('/:id', donationController.getDonationById);
router.post('/', donationValidation, validate, donationController.createDonation);
router.put('/:id', donationController.updateDonation);
router.delete('/:id', donationController.deleteDonation);

module.exports = router;
