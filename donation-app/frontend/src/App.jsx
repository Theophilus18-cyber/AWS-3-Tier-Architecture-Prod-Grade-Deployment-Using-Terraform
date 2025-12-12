import React, { useState, useEffect } from 'react';
import { Heart, DollarSign, Users, ArrowRight, Gift, Calendar } from 'lucide-react';
import axios from 'axios';

// API configuration...

//testing deployement.
const API_URL = import.meta.env.VITE_API_URL || '/api';

function App() {
    const [donations, setDonations] = useState([]);
    const [stats, setStats] = useState({ total_raised: 0, total_donations: 0, unique_donors: 0 });
    const [loading, setLoading] = useState(true);
    const [formData, setFormData] = useState({
        donor_name: '',
        email: '',
        amount: '',
        cause: 'Food',
        message: '',
        is_anonymous: false
    });
    const [submitting, setSubmitting] = useState(false);
    const [showSuccess, setShowSuccess] = useState(false);

    // Fetch data
    useEffect(() => {
        fetchData();
    }, []);

    const fetchData = async () => {
        try {
            const [donationsRes, statsRes] = await Promise.all([
                axios.get(`${API_URL}/donations?limit=5`),
                axios.get(`${API_URL}/stats`)
            ]);
            setDonations(donationsRes.data);
            setStats(statsRes.data);
            setLoading(false);
        } catch (error) {
            console.error('Error fetching data:', error);
            setLoading(false);
        }
    };

    const handleInputChange = (e) => {
        const { name, value, type, checked } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: type === 'checkbox' ? checked : value
        }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setSubmitting(true);

        try {
            await axios.post(`${API_URL}/donations`, formData);
            setShowSuccess(true);
            setFormData({
                donor_name: '',
                email: '',
                amount: '',
                cause: 'Food',
                message: '',
                is_anonymous: false
            });
            fetchData(); // Refresh data

            setTimeout(() => setShowSuccess(false), 5000);
        } catch (error) {
            console.error('Error submitting donation:', error);
            alert('Failed to submit donation. Please try again.');
        } finally {
            setSubmitting(false);
        }
    };

    const causes = ['Food', 'Utilities', 'Education', 'Healthcare', 'Environment', 'Disaster Relief'];

    return (
        <div className="min-h-screen bg-gray-50 font-sans">
            {/* Header */}
            <header className="bg-white shadow-sm sticky top-0 z-10">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
                    <div className="flex items-center space-x-2">
                        <div className="bg-primary-100 p-2 rounded-full">
                            <Heart className="w-6 h-6 text-primary-600" fill="currentColor" />
                        </div>
                        <span className="text-xl font-bold text-gray-900">HopeFund</span>
                    </div>
                    <nav className="hidden md:flex space-x-8">
                        <a href="#home" className="text-gray-600 hover:text-primary-600 font-medium">Home</a>
                        <a href="#donate" className="text-gray-600 hover:text-primary-600 font-medium">Donate</a>
                        <a href="#impact" className="text-gray-600 hover:text-primary-600 font-medium">Impact</a>
                    </nav>
                    <a href="#donate" className="btn-primary text-sm py-2 px-4">Donate Now</a>
                </div>
            </header>

            {/* Hero Section */}
            <section id="home" className="relative bg-primary-900 text-white py-20 overflow-hidden">
                <div className="absolute inset-0 opacity-10 bg-[url('https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?ixlib=rb-4.0.3&auto=format&fit=crop&w=1920&q=80')] bg-cover bg-center"></div>
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
                    <div className="md:w-2/3">
                        <h1 className="text-4xl md:text-6xl font-bold mb-6 leading-tight">
                            Make a Difference in Someone's Life Today
                        </h1>
                        <p className="text-xl text-primary-100 mb-8 max-w-2xl">
                            Your donation provides food, utilities, and hope to families in need.
                            Join our community of givers and create lasting change.
                        </p>
                        <div className="flex flex-col sm:flex-row gap-4">
                            <a href="#donate" className="bg-white text-primary-900 px-8 py-4 rounded-full font-bold text-lg hover:bg-primary-50 transition-colors inline-flex items-center justify-center">
                                Start Donating <ArrowRight className="ml-2 w-5 h-5" />
                            </a>
                            <a href="#impact" className="border-2 border-white text-white px-8 py-4 rounded-full font-bold text-lg hover:bg-white/10 transition-colors inline-flex items-center justify-center">
                                See Our Impact
                            </a>
                        </div>
                    </div>
                </div>
            </section>

            {/* Stats Section */}
            <section className="py-12 bg-white -mt-8 relative z-20 max-w-6xl mx-auto rounded-xl shadow-xl mx-4 lg:mx-auto">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-8 px-8 text-center divide-y md:divide-y-0 md:divide-x divide-gray-100">
                    <div className="py-4">
                        <div className="flex justify-center mb-4">
                            <div className="bg-primary-100 p-3 rounded-full">
                                <DollarSign className="w-8 h-8 text-primary-600" />
                            </div>
                        </div>
                        <h3 className="text-4xl font-bold text-gray-900 mb-2">${Number(stats.total_raised).toLocaleString()}</h3>
                        <p className="text-gray-500 font-medium uppercase tracking-wide text-sm">Total Raised</p>
                    </div>
                    <div className="py-4">
                        <div className="flex justify-center mb-4">
                            <div className="bg-secondary-100 p-3 rounded-full">
                                <Gift className="w-8 h-8 text-secondary-600" />
                            </div>
                        </div>
                        <h3 className="text-4xl font-bold text-gray-900 mb-2">{stats.total_donations}</h3>
                        <p className="text-gray-500 font-medium uppercase tracking-wide text-sm">Donations Received</p>
                    </div>
                    <div className="py-4">
                        <div className="flex justify-center mb-4">
                            <div className="bg-orange-100 p-3 rounded-full">
                                <Users className="w-8 h-8 text-orange-600" />
                            </div>
                        </div>
                        <h3 className="text-4xl font-bold text-gray-900 mb-2">{stats.unique_donors}</h3>
                        <p className="text-gray-500 font-medium uppercase tracking-wide text-sm">Unique Donors</p>
                    </div>
                </div>
            </section>

            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16 grid grid-cols-1 lg:grid-cols-2 gap-16">
                {/* Donation Form */}
                <div id="donate">
                    <div className="bg-white rounded-2xl shadow-xl p-8 border border-gray-100">
                        <div className="mb-8">
                            <h2 className="text-3xl font-bold text-gray-900 mb-2">Make a Donation</h2>
                            <p className="text-gray-500">Your contribution goes directly to those in need.</p>
                        </div>

                        {showSuccess && (
                            <div className="mb-6 bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg flex items-center">
                                <Heart className="w-5 h-5 mr-2 fill-current" />
                                <span>Thank you! Your donation has been received.</span>
                            </div>
                        )}

                        <form onSubmit={handleSubmit} className="space-y-6">
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-2">Your Name</label>
                                    <input
                                        type="text"
                                        name="donor_name"
                                        value={formData.donor_name}
                                        onChange={handleInputChange}
                                        className="input-field"
                                        placeholder="John Doe"
                                        required
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-2">Email (Optional)</label>
                                    <input
                                        type="email"
                                        name="email"
                                        value={formData.email}
                                        onChange={handleInputChange}
                                        className="input-field"
                                        placeholder="john@example.com"
                                    />
                                </div>
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-2">Donation Amount ($)</label>
                                <div className="relative">
                                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                        <span className="text-gray-500 text-lg">$</span>
                                    </div>
                                    <input
                                        type="number"
                                        name="amount"
                                        value={formData.amount}
                                        onChange={handleInputChange}
                                        className="input-field pl-8 text-lg font-semibold"
                                        placeholder="50.00"
                                        min="1"
                                        step="0.01"
                                        required
                                    />
                                </div>
                                <div className="flex gap-3 mt-3">
                                    {[10, 25, 50, 100].map(amt => (
                                        <button
                                            type="button"
                                            key={amt}
                                            onClick={() => setFormData(prev => ({ ...prev, amount: amt }))}
                                            className={`px-4 py-2 rounded-full text-sm font-medium border transition-colors ${Number(formData.amount) === amt
                                                ? 'bg-primary-600 text-white border-primary-600'
                                                : 'bg-white text-gray-600 border-gray-300 hover:border-primary-500 hover:text-primary-600'
                                                }`}
                                        >
                                            ${amt}
                                        </button>
                                    ))}
                                </div>
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-2">Cause</label>
                                <select
                                    name="cause"
                                    value={formData.cause}
                                    onChange={handleInputChange}
                                    className="input-field bg-white"
                                >
                                    {causes.map(c => (
                                        <option key={c} value={c}>{c}</option>
                                    ))}
                                </select>
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-2">Message (Optional)</label>
                                <textarea
                                    name="message"
                                    value={formData.message}
                                    onChange={handleInputChange}
                                    className="input-field h-24 resize-none"
                                    placeholder="Leave a message of support..."
                                ></textarea>
                            </div>

                            <div className="flex items-center">
                                <input
                                    type="checkbox"
                                    id="is_anonymous"
                                    name="is_anonymous"
                                    checked={formData.is_anonymous}
                                    onChange={handleInputChange}
                                    className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                                />
                                <label htmlFor="is_anonymous" className="ml-2 block text-sm text-gray-700">
                                    Make this donation anonymous
                                </label>
                            </div>

                            <button
                                type="submit"
                                disabled={submitting}
                                className={`w-full btn-primary text-lg shadow-lg shadow-primary-200 ${submitting ? 'opacity-75 cursor-not-allowed' : ''}`}
                            >
                                {submitting ? 'Processing...' : 'Donate Now'}
                            </button>
                        </form>
                    </div>
                </div>

                {/* Recent Donations */}
                <div id="impact">
                    <div className="mb-8 flex justify-between items-end">
                        <div>
                            <h2 className="text-3xl font-bold text-gray-900 mb-2">Recent Donations</h2>
                            <p className="text-gray-500">See who's helping our community.</p>
                        </div>
                        <div className="hidden md:block">
                            <button className="text-primary-600 font-medium hover:text-primary-700 flex items-center">
                                View All <ArrowRight className="ml-1 w-4 h-4" />
                            </button>
                        </div>
                    </div>

                    <div className="space-y-4">
                        {loading ? (
                            <div className="text-center py-12 text-gray-500">Loading donations...</div>
                        ) : donations.length === 0 ? (
                            <div className="text-center py-12 bg-white rounded-xl border border-dashed border-gray-300">
                                <Heart className="w-12 h-12 text-gray-300 mx-auto mb-3" />
                                <p className="text-gray-500">Be the first to donate!</p>
                            </div>
                        ) : (
                            donations.map((donation) => (
                                <div key={donation.id} className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 card-hover flex items-start gap-4">
                                    <div className="bg-primary-50 p-3 rounded-full shrink-0">
                                        <Heart className="w-6 h-6 text-primary-500" fill="currentColor" />
                                    </div>
                                    <div className="flex-1">
                                        <div className="flex justify-between items-start">
                                            <div>
                                                <h4 className="font-bold text-gray-900 text-lg">
                                                    {donation.is_anonymous ? 'Anonymous Donor' : donation.donor_name}
                                                </h4>
                                                <div className="flex items-center text-sm text-gray-500 mt-1">
                                                    <span className="bg-gray-100 px-2 py-0.5 rounded text-xs font-medium text-gray-600 mr-2">
                                                        {donation.cause}
                                                    </span>
                                                    <span className="flex items-center">
                                                        <Calendar className="w-3 h-3 mr-1" />
                                                        {new Date(donation.created_at).toLocaleDateString()}
                                                    </span>
                                                </div>
                                            </div>
                                            <span className="font-bold text-primary-600 text-xl">
                                                ${Number(donation.amount).toLocaleString()}
                                            </span>
                                        </div>
                                        {donation.message && (
                                            <p className="mt-3 text-gray-600 bg-gray-50 p-3 rounded-lg text-sm italic">
                                                "{donation.message}"
                                            </p>
                                        )}
                                    </div>
                                </div>
                            ))
                        )}
                    </div>
                </div>
            </div>

            {/* Footer */}
            <footer className="bg-gray-900 text-white py-12">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
                        <div className="col-span-1 md:col-span-2">
                            <div className="flex items-center space-x-2 mb-4">
                                <div className="bg-primary-500 p-1.5 rounded-full">
                                    <Heart className="w-5 h-5 text-white" fill="currentColor" />
                                </div>
                                <span className="text-xl font-bold">HopeFund</span>
                            </div>
                            <p className="text-gray-400 max-w-sm">
                                Dedicated to connecting generous hearts with those in need.
                                100% of your donation goes directly to the cause you choose.
                            </p>
                        </div>
                        <div>
                            <h4 className="font-bold text-lg mb-4">Quick Links</h4>
                            <ul className="space-y-2 text-gray-400">
                                <li><a href="#" className="hover:text-primary-400">About Us</a></li>
                                <li><a href="#" className="hover:text-primary-400">Our Causes</a></li>
                                <li><a href="#" className="hover:text-primary-400">Transparency</a></li>
                                <li><a href="#" className="hover:text-primary-400">Contact</a></li>
                            </ul>
                        </div>
                        <div>
                            <h4 className="font-bold text-lg mb-4">Connect</h4>
                            <ul className="space-y-2 text-gray-400">
                                <li><a href="#" className="hover:text-primary-400">Twitter</a></li>
                                <li><a href="#" className="hover:text-primary-400">Facebook</a></li>
                                <li><a href="#" className="hover:text-primary-400">Instagram</a></li>
                                <li><a href="#" className="hover:text-primary-400">LinkedIn</a></li>
                            </ul>
                        </div>
                    </div>
                    <div className="border-t border-gray-800 mt-12 pt-8 text-center text-gray-500 text-sm">
                        &copy; {new Date().getFullYear()} HopeFund Charity. All rights reserved.
                    </div>
                </div>
            </footer>
        </div>
    );
}

export default App;
