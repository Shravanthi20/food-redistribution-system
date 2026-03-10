import React from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Leaf, Heart, Users, Building2, ChevronRight, ArrowRight, Truck, ShieldCheck, Recycle } from 'lucide-react';

const LandingPage = () => {
    const navigate = useNavigate();

    const fadeIn = {
        initial: { opacity: 0, y: 20 },
        animate: { opacity: 1, y: 0 },
        transition: { duration: 0.6 }
    };

    return (
        <div className="landing-page">
            {/* Navbar */}
            <nav style={styles.navbar}>
                <div style={styles.logo} onClick={() => navigate('/')}>
                    <Leaf size={32} fill="#006644" color="#006644" />
                    <span style={styles.logoText}>FreshSave</span>
                </div>
                <div style={styles.navLinks}>
                    <button style={styles.textBtn} onClick={() => navigate('/login')}>Log In</button>
                    <button style={styles.primaryBtn} onClick={() => navigate('/register/donor')}>Donate Food</button>
                </div>
            </nav>

            {/* Hero Section */}
            <header style={styles.hero}>
                <div className="container" style={styles.heroContainer}>
                    <motion.div
                        initial={{ opacity: 0, x: -50 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ duration: 0.8 }}
                        style={styles.heroContent}
                    >
                        <div style={styles.badge}>#1 Food Redistribution Platform</div>
                        <h1 style={styles.heroTitle}>Share Food,<br /><span style={{ color: 'var(--primary-color)' }}>Share Love.</span></h1>
                        <p style={styles.heroText}>
                            Connect surplus food from restaurants and events with local communities in need.
                            Join our verified network of donors, volunteers, and NGOs.
                        </p>
                        <div style={styles.heroButtons}>
                            <button style={styles.largePrimaryBtn} onClick={() => navigate('/register/donor')}>
                                I Want to Donate <ArrowRight size={20} />
                            </button>
                            <button style={styles.largeSecondaryBtn} onClick={() => navigate('/register/ngo')}>
                                I Need Food
                            </button>
                        </div>
                    </motion.div>
                    <motion.div
                        initial={{ opacity: 0, scale: 0.9 }}
                        animate={{ opacity: 1, scale: 1 }}
                        transition={{ duration: 0.8 }}
                        style={styles.heroImageWrapper}
                    >
                        <img src="/assets/hero.png" alt="Community Sharing Food" style={styles.heroImage} />
                    </motion.div>
                </div>
            </header>

            {/* Stats Section */}
            <section style={styles.statsSection}>
                <div className="container" style={styles.statsGrid}>
                    <StatCard number="10k+" label="Meals Served" icon={<Heart size={24} />} />
                    <StatCard number="500+" label="Active Volunteers" icon={<Users size={24} />} />
                    <StatCard number="2.5T" label="Food Waste Reduced" icon={<Recycle size={24} />} />
                    <StatCard number="150+" label="Partner NGOs" icon={<Building2 size={24} />} />
                </div>
            </section>

            {/* How It Works / Features */}
            <section style={styles.section}>
                <div className="container">
                    <div style={styles.sectionHeader}>
                        <h2 style={styles.sectionTitle}>How FreshSave Works</h2>
                        <p style={styles.sectionSubtitle}>A seamless ecosystem connecting donors, volunteers, and communities.</p>
                    </div>

                    <div style={styles.featureRow}>
                        <div style={styles.featureImageWrapper}>
                            <img src="/assets/features.png" alt="App Features" style={styles.featureImage} />
                        </div>
                        <div style={styles.featureList}>
                            <FeatureItem
                                icon={<ShieldCheck size={28} color="var(--primary-color)" />}
                                title="Verified Donors & NGOs"
                                desc="We ensure safety and quality through our rigorous verification process for all partners."
                            />
                            <FeatureItem
                                icon={<Truck size={28} color="var(--primary-color)" />}
                                title="Real-Time Logistics"
                                desc="Volunteers receive instant alerts for nearby pickups, ensuring food reaches its destination fresh."
                            />
                            <FeatureItem
                                icon={<Leaf size={28} color="var(--primary-color)" />}
                                title="Sustainability Tracking"
                                desc="Track your impact with detailed analytics on CO2 reduction and meals provided."
                            />
                        </div>
                    </div>
                </div>
            </section>

            {/* Impact Section */}
            <section style={{ ...styles.section, background: 'var(--primary-light)' }}>
                <div className="container" style={{ ...styles.featureRow, flexDirection: 'row-reverse' }}>
                    <div style={styles.featureImageWrapper}>
                        <img src="/assets/impact.png" alt="Eco Impact" style={styles.featureImage} />
                    </div>
                    <div style={styles.contentSide}>
                        <h2 style={styles.sectionTitle}>Make a Real Impact</h2>
                        <p style={styles.textLarge}>
                            Every meal saved is a step towards a greener planet. By redirecting surplus food, we not only fight hunger but also reduce methane emissions from landfills.
                        </p>
                        <div style={styles.impactGrid}>
                            <div style={styles.impactItem}>
                                <h3>Zero</h3>
                                <p>Hunger Goal</p>
                            </div>
                            <div style={styles.impactItem}>
                                <h3>100%</h3>
                                <p>Volunteer Driven</p>
                            </div>
                        </div>
                        <button style={styles.primaryBtn} onClick={() => navigate('/register/volunteer')}>
                            Become a Volunteer
                        </button>
                    </div>
                </div>
            </section>

            {/* CTA Grid */}
            <section style={{ ...styles.section, paddingBottom: 80 }}>
                <div className="container">
                    <div style={styles.sectionHeader}>
                        <h2 style={styles.sectionTitle}>Get Involved Today</h2>
                    </div>
                    <div className="card-grid">
                        <RoleCard
                            title="Become a Donor"
                            desc="Restaurants, caterers, and individuals."
                            icon={Heart}
                            action={() => navigate('/register/donor')}
                        />
                        <RoleCard
                            title="Join as NGO"
                            desc="Receive food for your community."
                            icon={Building2}
                            action={() => navigate('/register/ngo')}
                        />
                        <RoleCard
                            title="Volunteer"
                            desc="Help transport food."
                            icon={Truck}
                            action={() => navigate('/register/volunteer')}
                        />
                    </div>
                </div>
            </section>

            {/* Footer */}
            <footer style={styles.footer}>
                <div className="container" style={styles.footerContent}>
                    <div>
                        <div style={{ ...styles.logo, color: 'white', marginBottom: 16 }}>
                            <Leaf size={24} fill="white" color="white" />
                            <span>FreshSave</span>
                        </div>
                        <p style={{ color: '#ffffff80', maxWidth: 300 }}>
                            Bridging the gap between abundance and need through technology and community.
                        </p>
                    </div>
                    <div style={styles.footerLinks}>
                        <h4>Platform</h4>
                        <a href="#">About Us</a>
                        <a href="#">Safety Guidelines</a>
                        <a href="#">Contact</a>
                    </div>
                    <div style={styles.footerLinks}>
                        <h4>Legal</h4>
                        <a href="#">Privacy Policy</a>
                        <a href="#">Terms of Service</a>
                    </div>
                </div>
                <div style={styles.copyright}>
                    © 2024 FreshSave. All rights reserved.
                </div>
            </footer>
        </div>
    );
};

// Sub-components
const StatCard = ({ number, label, icon }) => (
    <div style={styles.statCard}>
        <div style={styles.statIcon}>{icon}</div>
        <h3 style={styles.statNumber}>{number}</h3>
        <p style={styles.statLabel}>{label}</p>
    </div>
);

const FeatureItem = ({ icon, title, desc }) => (
    <div style={styles.featureItem}>
        <div style={styles.featureIconBox}>{icon}</div>
        <div>
            <h4 style={styles.featureTitle}>{title}</h4>
            <p style={styles.featureDesc}>{desc}</p>
        </div>
    </div>
);

const RoleCard = ({ title, desc, icon: Icon, action }) => (
    <motion.div
        whileHover={{ y: -5 }}
        style={styles.roleCard}
        onClick={action}
    >
        <div style={styles.roleIcon}><Icon size={32} /></div>
        <h3>{title}</h3>
        <p>{desc}</p>
        <div style={styles.linkArrow}>Get Started <ChevronRight size={16} /></div>
    </motion.div>
);

// Styles Object
const styles = {
    navbar: {
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: '20px 40px',
        background: '#fff',
        position: 'sticky',
        top: 0,
        zIndex: 100,
        boxShadow: '0 2px 10px rgba(0,0,0,0.05)'
    },
    logo: {
        display: 'flex',
        alignItems: 'center',
        gap: '8px',
        cursor: 'pointer',
        fontWeight: '800',
        fontSize: '1.5rem',
        color: 'var(--primary-color)'
    },
    navLinks: {
        display: 'flex',
        gap: '16px'
    },
    primaryBtn: {
        background: 'var(--primary-color)',
        color: 'white',
        border: 'none',
        padding: '10px 24px',
        borderRadius: '50px',
        fontWeight: '600',
        cursor: 'pointer',
        fontSize: '0.95rem'
    },
    textBtn: {
        background: 'transparent',
        color: 'var(--text-dark)',
        border: 'none',
        padding: '10px 20px',
        fontWeight: '600',
        cursor: 'pointer',
        fontSize: '0.95rem'
    },
    hero: {
        background: 'linear-gradient(135deg, #f8faf9 0%, #e8f5e9 100%)',
        padding: '80px 20px',
        overflow: 'hidden'
    },
    heroContainer: {
        display: 'grid',
        gridTemplateColumns: '1fr 1fr',
        gap: '60px',
        alignItems: 'center',
        maxWidth: '1200px',
        margin: '0 auto'
    },
    heroContent: {
        display: 'flex',
        flexDirection: 'column',
        gap: '24px'
    },
    badge: {
        background: '#e8f5e9',
        color: 'var(--primary-color)',
        padding: '6px 12px',
        borderRadius: '4px',
        fontWeight: '600',
        fontSize: '0.85rem',
        width: 'fit-content'
    },
    heroTitle: {
        fontSize: '4rem',
        lineHeight: '1.1',
        fontWeight: '800',
        color: '#1a1a1a'
    },
    heroText: {
        fontSize: '1.2rem',
        color: 'var(--text-light)',
        lineHeight: '1.6',
        maxWidth: '500px'
    },
    heroButtons: {
        display: 'flex',
        gap: '16px',
        marginTop: '10px'
    },
    largePrimaryBtn: {
        background: 'var(--primary-color)',
        color: 'white',
        border: 'none',
        padding: '16px 32px',
        borderRadius: '50px',
        fontWeight: '700',
        fontSize: '1.1rem',
        cursor: 'pointer',
        display: 'flex',
        alignItems: 'center',
        gap: '8px',
        boxShadow: '0 4px 15px rgba(0, 102, 68, 0.2)'
    },
    largeSecondaryBtn: {
        background: 'white',
        color: 'var(--text-dark)',
        border: '2px solid #e0e0e0',
        padding: '16px 32px',
        borderRadius: '50px',
        fontWeight: '700',
        fontSize: '1.1rem',
        cursor: 'pointer'
    },
    heroImage: {
        width: '100%',
        height: 'auto',
        borderRadius: '24px',
        boxShadow: '0 20px 40px rgba(0,0,0,0.1)'
    },
    statsSection: {
        background: 'var(--primary-color)',
        padding: '40px 0',
        color: 'white'
    },
    statsGrid: {
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
        gap: '30px',
        maxWidth: '1200px',
        margin: '0 auto'
    },
    statCard: {
        textAlign: 'center',
        padding: '20px'
    },
    statIcon: {
        background: 'rgba(255,255,255,0.2)',
        width: '48px',
        height: '48px',
        borderRadius: '50%',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        margin: '0 auto 16px',
        color: 'white'
    },
    statNumber: {
        fontSize: '2.5rem',
        fontWeight: '800',
        marginBottom: '4px'
    },
    statLabel: {
        fontSize: '1rem',
        opacity: 0.9
    },
    section: {
        padding: '80px 0'
    },
    sectionHeader: {
        textAlign: 'center',
        marginBottom: '60px',
        maxWidth: '600px',
        marginLeft: 'auto',
        marginRight: 'auto'
    },
    sectionTitle: {
        fontSize: '2.5rem',
        fontWeight: '800',
        color: '#1a1a1a',
        marginBottom: '16px'
    },
    sectionSubtitle: {
        fontSize: '1.2rem',
        color: 'var(--text-light)'
    },
    featureRow: {
        display: 'grid',
        gridTemplateColumns: '1fr 1fr',
        gap: '60px',
        alignItems: 'center',
        maxWidth: '1200px',
        margin: '0 auto'
    },
    featureImageWrapper: {
        borderRadius: '24px',
        overflow: 'hidden',
        boxShadow: '0 20px 40px rgba(0,0,0,0.1)'
    },
    featureImage: {
        width: '100%',
        height: 'auto',
        display: 'block'
    },
    featureList: {
        display: 'flex',
        flexDirection: 'column',
        gap: '30px'
    },
    featureItem: {
        display: 'flex',
        gap: '20px'
    },
    featureIconBox: {
        background: '#e8f5e9',
        width: '60px',
        height: '60px',
        borderRadius: '16px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexShrink: 0
    },
    featureTitle: {
        fontSize: '1.2rem',
        fontWeight: '700',
        marginBottom: '8px',
        color: '#1a1a1a'
    },
    featureDesc: {
        color: 'var(--text-light)',
        lineHeight: '1.5'
    },
    roleCard: {
        background: 'white',
        padding: '32px',
        borderRadius: '24px',
        boxShadow: '0 10px 30px rgba(0,0,0,0.05)',
        cursor: 'pointer',
        border: '1px solid #f0f0f0',
        textAlign: 'center'
    },
    roleIcon: {
        color: 'var(--primary-color)',
        marginBottom: '20px'
    },
    linkArrow: {
        color: 'var(--primary-color)',
        fontWeight: '700',
        marginTop: '20px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: '4px'
    },
    footer: {
        background: '#1a1a1a',
        color: 'white',
        padding: '60px 0 20px'
    },
    footerContent: {
        display: 'grid',
        gridTemplateColumns: '2fr 1fr 1fr',
        gap: '40px',
        maxWidth: '1200px',
        margin: '0 auto',
        paddingBottom: '40px',
        borderBottom: '1px solid #333'
    },
    footerLinks: {
        display: 'flex',
        flexDirection: 'column',
        gap: '16px'
    },
    copyright: {
        textAlign: 'center',
        paddingTop: '20px',
        color: '#666',
        fontSize: '0.9rem'
    }
};

export default LandingPage;
