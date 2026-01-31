import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import LandingPage from './pages/LandingPage';
import Login from './pages/Login';
import VolunteerRegistration from './pages/VolunteerRegistration';
import NGORegistration from './pages/NGORegistration';
import DonorRegistration from './pages/DonorRegistration';

function App() {
    return (
        <Router>
            <Routes>
                <Route path="/" element={<LandingPage />} />
                <Route path="/login" element={<Login />} />
                <Route path="/register/volunteer" element={<VolunteerRegistration />} />
                <Route path="/register/ngo" element={<NGORegistration />} />
                <Route path="/register/donor" element={<DonorRegistration />} />
                <Route path="/dashboard" element={
                    <div style={{
                        minHeight: '100vh',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        flexDirection: 'column',
                        gap: '20px'
                    }}>
                        <h1>Welcome to FreshSave Dashboard!</h1>
                        <p>You have successfully logged in.</p>
                    </div>
                } />
            </Routes>
        </Router>
    );
}

export default App;
