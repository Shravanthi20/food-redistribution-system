import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Leaf, ArrowLeft } from 'lucide-react';
import { signInWithEmailAndPassword, signInWithPopup } from 'firebase/auth';
import { auth, googleProvider, appleProvider } from '../firebase/config';
import FormInput from '../components/FormInput';

function Login() {
    const navigate = useNavigate();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const [formData, setFormData] = useState({
        email: '',
        password: ''
    });

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({ ...prev, [name]: value }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        try {
            await signInWithEmailAndPassword(auth, formData.email, formData.password);
            navigate('/dashboard');
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    const handleSocialAuth = async (provider) => {
        setError('');
        try {
            await signInWithPopup(auth, provider);
            navigate('/dashboard');
        } catch (err) {
            setError(err.message);
        }
    };

    return (
        <div className="page-container">
            <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="card"
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

                <h2 className="section-title">Welcome Back</h2>
                <p style={{ color: 'var(--text-light)', marginBottom: '24px' }}>
                    Log in to continue making a difference
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

                <div className="social-auth">
                    <button className="social-button" onClick={() => handleSocialAuth(googleProvider)}>
                        <img src="https://www.google.com/favicon.ico" alt="Google" width="20" />
                        Continue with Google
                    </button>
                    <button className="social-button" onClick={() => handleSocialAuth(appleProvider)}>
                        <img src="https://www.apple.com/favicon.ico" alt="Apple" width="20" />
                        Continue with Apple
                    </button>
                </div>

                <div className="divider"><span>or</span></div>

                <form onSubmit={handleSubmit} className="form">
                    <FormInput
                        label="Email"
                        type="email"
                        name="email"
                        value={formData.email}
                        onChange={handleChange}
                        required
                        placeholder="name@example.com"
                    />

                    <FormInput
                        label="Password"
                        type="password"
                        name="password"
                        value={formData.password}
                        onChange={handleChange}
                        required
                        placeholder="••••••••"
                    />

                    <button type="submit" className="btn btn-primary btn-full" disabled={loading}>
                        {loading ? 'Logging in...' : 'Log In'}
                    </button>
                </form>

                <p className="mt-3 text-center" style={{ color: 'var(--text-light)' }}>
                    Don't have an account?{' '}
                    <span className="text-link" onClick={() => navigate('/')}>
                        Register Now
                    </span>
                </p>
            </motion.div>
        </div>
    );
}

export default Login;
