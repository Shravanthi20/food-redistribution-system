import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Leaf, ArrowLeft } from 'lucide-react';
import { createUserWithEmailAndPassword } from 'firebase/auth';
import { auth } from '../firebase/config';
import FormInput from '../components/FormInput';

function NGORegistration() {
    const navigate = useNavigate();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const [formData, setFormData] = useState({
        organizationName: '',
        registrationNumber: '',
        email: '',
        password: '',
        confirmPassword: '',
        phone: '',
        address: '',
        city: '',
        organizationType: '',
        capacity: '',
        operatingHours: '',
        contactPersonName: '',
        website: ''
    });

    const organizationTypes = [
        { value: 'food_bank', label: 'Food Bank' },
        { value: 'shelter', label: 'Shelter' },
        { value: 'community_kitchen', label: 'Community Kitchen' },
        { value: 'charity', label: 'Charity Organization' },
        { value: 'other', label: 'Other' }
    ];

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({ ...prev, [name]: value }));
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
                    userType: 'ngo',
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

                <h2 className="section-title">NGO Registration</h2>
                <p style={{ color: 'var(--text-light)', marginBottom: '24px' }}>
                    Register your organization to receive food donations
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
                        label="Organization Name"
                        name="organizationName"
                        value={formData.organizationName}
                        onChange={handleChange}
                        required
                        placeholder="Food Bank of New York"
                    />

                    <div className="form-row">
                        <FormInput
                            label="Registration Number"
                            name="registrationNumber"
                            value={formData.registrationNumber}
                            onChange={handleChange}
                            required
                            placeholder="REG123456"
                        />
                        <FormInput
                            label="Organization Type"
                            type="select"
                            name="organizationType"
                            value={formData.organizationType}
                            onChange={handleChange}
                            required
                            options={organizationTypes}
                        />
                    </div>

                    <div className="form-row">
                        <FormInput
                            label="Email"
                            type="email"
                            name="email"
                            value={formData.email}
                            onChange={handleChange}
                            required
                            placeholder="contact@organization.org"
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

                    <div className="form-row">
                        <FormInput
                            label="Capacity (People/Day)"
                            type="number"
                            name="capacity"
                            value={formData.capacity}
                            onChange={handleChange}
                            required
                            placeholder="100"
                        />
                        <FormInput
                            label="Operating Hours"
                            name="operatingHours"
                            value={formData.operatingHours}
                            onChange={handleChange}
                            required
                            placeholder="9 AM - 5 PM"
                        />
                    </div>

                    <FormInput
                        label="Contact Person Name"
                        name="contactPersonName"
                        value={formData.contactPersonName}
                        onChange={handleChange}
                        required
                        placeholder="John Doe"
                    />

                    <FormInput
                        label="Website (Optional)"
                        type="url"
                        name="website"
                        value={formData.website}
                        onChange={handleChange}
                        placeholder="https://www.organization.org"
                    />

                    <button type="submit" className="btn btn-primary btn-full" disabled={loading}>
                        {loading ? 'Creating Account...' : 'Register Organization'}
                    </button>
                </form>
            </motion.div>
        </div>
    );
}

export default NGORegistration;
