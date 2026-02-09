import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Leaf, ArrowLeft } from 'lucide-react';
import { createUserWithEmailAndPassword } from 'firebase/auth';
import { auth } from '../firebase/config';
import FormInput from '../components/FormInput';

function VolunteerRegistration() {
    const navigate = useNavigate();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const [formData, setFormData] = useState({
        fullName: '',
        email: '',
        password: '',
        confirmPassword: '',
        phone: '',
        city: '',
        availability: [],
        hasTransportation: 'no',
        emergencyContact: '',
        emergencyPhone: ''
    });

    const availabilityOptions = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];

    const handleChange = (e) => {
        const { name, value, type, checked } = e.target;

        if (type === 'checkbox') {
            setFormData(prev => ({
                ...prev,
                availability: checked
                    ? [...prev.availability, value]
                    : prev.availability.filter(day => day !== value)
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

            // Send user data to backend
            const idToken = await userCredential.user.getIdToken();

            await fetch('http://localhost:5000/api/users/sync', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${idToken}`
                },
                body: JSON.stringify({
                    userType: 'volunteer',
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
                style={{ maxWidth: '600px' }}
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

                <h2 className="section-title">Volunteer Registration</h2>
                <p style={{ color: 'var(--text-light)', marginBottom: '24px' }}>
                    Join our community of volunteers making a difference
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
                        label="Full Name"
                        name="fullName"
                        value={formData.fullName}
                        onChange={handleChange}
                        required
                        placeholder="John Doe"
                    />

                    <div className="form-row">
                        <FormInput
                            label="Email"
                            type="email"
                            name="email"
                            value={formData.email}
                            onChange={handleChange}
                            required
                            placeholder="john@example.com"
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
                        label="City"
                        name="city"
                        value={formData.city}
                        onChange={handleChange}
                        required
                        placeholder="New York"
                    />

                    <div className="form-group">
                        <label>Availability (Select all that apply)</label>
                        <div className="checkbox-group">
                            {availabilityOptions.map(day => (
                                <div key={day} className="checkbox-item">
                                    <input
                                        type="checkbox"
                                        id={day}
                                        value={day}
                                        checked={formData.availability.includes(day)}
                                        onChange={handleChange}
                                    />
                                    <label htmlFor={day}>{day}</label>
                                </div>
                            ))}
                        </div>
                    </div>

                    <FormInput
                        label="Do you have transportation?"
                        type="select"
                        name="hasTransportation"
                        value={formData.hasTransportation}
                        onChange={handleChange}
                        required
                        options={[
                            { value: 'yes', label: 'Yes' },
                            { value: 'no', label: 'No' }
                        ]}
                    />

                    <div className="form-row">
                        <FormInput
                            label="Emergency Contact Name"
                            name="emergencyContact"
                            value={formData.emergencyContact}
                            onChange={handleChange}
                            required
                            placeholder="Jane Doe"
                        />
                        <FormInput
                            label="Emergency Contact Phone"
                            type="tel"
                            name="emergencyPhone"
                            value={formData.emergencyPhone}
                            onChange={handleChange}
                            required
                            placeholder="+1 234 567 8900"
                        />
                    </div>

                    <button type="submit" className="btn btn-primary btn-full" disabled={loading}>
                        {loading ? 'Creating Account...' : 'Register as Volunteer'}
                    </button>
                </form>
            </motion.div>
        </div>
    );
}

export default VolunteerRegistration;
