import React from 'react';

function FormInput({
    label,
    type = 'text',
    name,
    value,
    onChange,
    required = false,
    placeholder = '',
    error = '',
    options = [] // For select inputs
}) {
    return (
        <div className="form-group">
            <label htmlFor={name}>
                {label} {required && <span style={{ color: 'var(--error)' }}>*</span>}
            </label>

            {type === 'select' ? (
                <select
                    id={name}
                    name={name}
                    value={value}
                    onChange={onChange}
                    required={required}
                >
                    <option value="">Select {label}</option>
                    {options.map((option) => (
                        <option key={option.value} value={option.value}>
                            {option.label}
                        </option>
                    ))}
                </select>
            ) : type === 'textarea' ? (
                <textarea
                    id={name}
                    name={name}
                    value={value}
                    onChange={onChange}
                    required={required}
                    placeholder={placeholder}
                />
            ) : (
                <input
                    id={name}
                    type={type}
                    name={name}
                    value={value}
                    onChange={onChange}
                    required={required}
                    placeholder={placeholder}
                />
            )}

            {error && <span className="error">{error}</span>}
        </div>
    );
}

export default FormInput;
