import React from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Leaf, Users, Building2, Heart } from 'lucide-react';

function Welcome() {
    const navigate = useNavigate();

    const userTypes = [
        {
            id: 'volunteer',
            title: 'Volunteer',
            description: 'Help rescue and distribute food to those in need',
            icon: Heart,
            path: '/register/volunteer'
        },
        {
            id: 'ngo',
            title: 'NGO',
            description: 'Register your organization to receive food donations',
            icon: Building2,
            path: '/register/ngo'
        },
        {
            id: 'donor',
            title: 'Donor',
            description: 'Donate surplus food from your business or home',
            icon: Users,
            path: '/register/donor'
        }
    ];

    return (
        <div className="page-container">
            <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6 }}
                style={{ width: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center' }}
            >
                <a href="/" className="logo">
                    <Leaf size={40} fill="#006644" />
                    <span>FreshSave</span>
                </a>

                <h1 className="page-title">Join the Movement</h1>
                <p className="page-subtitle">
                    Choose how you'd like to help fight food waste and hunger
                </p>

                <div className="card-grid">
                    {userTypes.map((type, index) => (
                        <motion.div
                            key={type.id}
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ duration: 0.6, delay: index * 0.1 }}
                            className="user-type-card"
                            onClick={() => navigate(type.path)}
                        >
                            <div className="icon">
                                <type.icon size={32} />
                            </div>
                            <h3>{type.title}</h3>
                            <p>{type.description}</p>
                        </motion.div>
                    ))}
                </div>

                <p className="mt-3 text-center" style={{ color: 'var(--text-light)' }}>
                    Already have an account?{' '}
                    <span className="text-link" onClick={() => navigate('/login')}>
                        Log In
                    </span>
                </p>
            </motion.div>
        </div>
    );
}

export default Welcome;
