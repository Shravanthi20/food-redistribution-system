import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Leaf, ArrowLeft } from 'lucide-react';
import { createUserWithEmailAndPassword } from 'firebase/auth';
import { auth } from '../firebase/config';
import FormInput from '../components/FormInput';

function DonorRegistration() {
    const navigate = useNavigate();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const [formData, setFormData] = useState({
        donorType: '',
        businessName: '',
        email: '',
        password: '',
        confirmPassword: '',
        phone: '',
        address: '',
        city: '',
        foodTypes: [],
        pickupDelivery: '',
        operatingHours: ''
    });

    const donorTypes = [
        { value: 'restaurant', label: 'Restaurant' },
        { value: 'grocery_store', label: 'Grocery Store' },
        { value: 'bakery', label: 'Bakery' },
        { value: 'cafe', label: 'Cafe' },
        { value: 'hotel', label: 'Hotel' },
        { value: 'individual', label: 'Individual' },
        { value: 'other', label: 'Other' }
    ];

    const foodTypeOptions = [
        'Fresh Produce', 'Baked Goods', 'Prepared Meals', 'Packaged Foods',
        'Dairy Products', 'Beverages', 'Other'
    ];

    const handleChange = (e) => {
        const { name, value, type, checked } = e.target;

        if (type === 'checkbox') {
            setFormData(prev => ({
                ...prev,
                foodTypes: checked
                    ? [...prev.foodTypes, value]
                    : prev.foodTypes.filter(type => type !== value)
            }));
        } else {
            setFormData(prev => ({ ...prev, [name]: value }));
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');

        if (formData.password !== formData.confirmPassword) {
            setError('Passwords do not match');
            return;
        }

        if (formData.password.length < 6) {
            setError('Password must be at least 6 characters');
            return;
        }

        setLoading(true);

        try {
            const userCredential = await createUserWithEmailAndPassword(
                auth,
                formData.email,
                formData.password
            );

            const idToken = await userCredential.user.getIdToken();

            await fetch('http://localhost:5000/api/users/sync', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${idToken}`
                },
                body: JSON.stringify({
                    userType: 'donor',
                    ...formData
                })
            });

            alert('Registration successful! Welcome to FreshSave.');
            navigate('/dashboard');
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="page-container">
            <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="card"
                style={{ maxWidth: '700px' }}
            >
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '24px' }}>
                    <button
                        onClick={() => navigate('/')}
                        style={{ background: 'none', border: 'none', cursor: 'pointer', padding: '8px' }}
                    >
                        <ArrowLeft size={24} color="var(--text-dark)" />
                    </button>
                    <div className="logo" style={{ margin: 0 }}>
                        <Leaf size={32} fill="#006644" />
                        <span style={{ fontSize: '1.5rem' }}>FreshSave</span>
                    </div>
                </div>

                <h2 className="section-title">Donor Registration</h2>
                <p style={{ color: 'var(--text-light)', marginBottom: '24px' }}>
                    Register to donate surplus food and make a difference
                </p>

                {error && (
                    <div style={{
                        padding: '12px',
                        background: '#fee',
                        borderRadius: '8px',
                        color: 'var(--error)',
                        marginBottom: '20px'
                    }}>
                        {error}
                    </div>
                )}

                <form onSubmit={handleSubmit} className="form">
                    <FormInput
                        label="Donor Type"
                        type="select"
                        name="donorType"
                        value={formData.donorType}
                        onChange={handleChange}
                        required
                        options={donorTypes}
                    />

                    <FormInput
                        label="Business/Individual Name"
                        name="businessName"
                        value={formData.businessName}
                        onChange={handleChange}
                        required
                        placeholder="Joe's Restaurant"
                    />

                    <div className="form-row">
                        <FormInput
                            label="Email"
                            type="email"
                            name="email"
                            value={formData.email}
                            onChange={handleChange}
                            required
                            placeholder="contact@business.com"
                        />
                        <FormInput
                            label="Phone"
                            type="tel"
                            name="phone"
                            value={formData.phone}
                            onChange={handleChange}
                            required
                            placeholder="+1 234 567 8900"
                        />
                    </div>

                    <div className="form-row">
                        <FormInput
                            label="Password"
                            type="password"
                            name="password"
                            value={formData.password}
                            onChange={handleChange}
                            required
                            placeholder="••••••••"
                        />
                        <FormInput
                            label="Confirm Password"
                            type="password"
                            name="confirmPassword"
                            value={formData.confirmPassword}
                            onChange={handleChange}
                            required
                            placeholder="••••••••"
                        />
                    </div>

                    <FormInput
                        label="Address"
                        name="address"
                        value={formData.address}
                        onChange={handleChange}
                        required
                        placeholder="123 Main Street"
                    />

                    <FormInput
                        label="City/Region"
                        name="city"
                        value={formData.city}
                        onChange={handleChange}
                        required
                        placeholder="New York"
                    />

                    <div className="form-group">
                        <label>Food Types Available (Select all that apply)</label>
                        <div className="checkbox-group">
                            {foodTypeOptions.map(type => (
                                <div key={type} className="checkbox-item">
                                    <input
                                        type="checkbox"
                                        id={type}
                                        value={type}
                                        checked={formData.foodTypes.includes(type)}
                                        onChange={handleChange}
                                    />
                                    <label htmlFor={type}>{type}</label>
                                </div>
                            ))}
                        </div>
                    </div>

                    <FormInput
                        label="Pickup/Delivery Options"
                        type="select"
                        name="pickupDelivery"
                        value={formData.pickupDelivery}
                        onChange={handleChange}
                        required
                        options={[
                            { value: 'pickup', label: 'Pickup Only' },
                            { value: 'delivery', label: 'Delivery Available' },
                            { value: 'both', label: 'Both' }
                        ]}
                    />

                    <FormInput
                        label="Operating Hours"
                        name="operatingHours"
                        value={formData.operatingHours}
                        onChange={handleChange}
                        required
                        placeholder="9 AM - 9 PM"
                    />

                    <button type="submit" className="btn btn-primary btn-full" disabled={loading}>
                        {loading ? 'Creating Account...' : 'Register as Donor'}
                    </button>
                </form>
            </motion.div>
        </div>
    );
}

export default DonorRegistration;
