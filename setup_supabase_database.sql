-- Database setup for Expense Tracker using Supabase
-- Run this in your Supabase SQL Editor

-- Create expenses table
CREATE TABLE public.expenses (
    id BIGSERIAL PRIMARY KEY,
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    description TEXT NOT NULL,
    category TEXT NOT NULL,
    date TIMESTAMPTZ NOT NULL,
    payee TEXT,
    payment_app TEXT DEFAULT 'PhonePe',
    transaction_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create categories table
CREATE TABLE public.categories (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    icon TEXT NOT NULL,
    color TEXT NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_expenses_date ON public.expenses(date DESC);
CREATE INDEX idx_expenses_category ON public.expenses(category);
CREATE INDEX idx_expenses_payee ON public.expenses(payee);
CREATE INDEX idx_expenses_created_at ON public.expenses(created_at DESC);

-- Enable Row Level Security (but allow all operations for your personal use)
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Create policies that allow all operations (since you're the only user)
CREATE POLICY "Allow all operations on expenses" ON public.expenses
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow all operations on categories" ON public.categories
    FOR ALL USING (true) WITH CHECK (true);

-- Insert default categories
INSERT INTO public.categories (name, icon, color, is_default) VALUES
('Food & Dining', '🍽️', '#FF6B6B', true),
('Transportation', '🚗', '#4ECDC4', true),
('Shopping', '🛒', '#45B7D1', true),
('Entertainment', '🎬', '#96CEB4', true),
('Bills & Utilities', '💡', '#FECA57', true),
('Healthcare', '🏥', '#FF9FF3', true),
('Education', '📚', '#54A0FF', true),
('Other', '📦', '#747D8C', true);

-- Create function for monthly totals (for analytics)
CREATE OR REPLACE FUNCTION get_monthly_totals()
RETURNS TABLE (
    month TEXT,
    total DECIMAL
) LANGUAGE sql AS $$
    SELECT
        TO_CHAR(date, 'YYYY-MM') as month,
        SUM(amount) as total
    FROM public.expenses
    WHERE date >= (CURRENT_DATE - INTERVAL '12 months')
    GROUP BY TO_CHAR(date, 'YYYY-MM')
    ORDER BY month DESC;
$$;

-- Create trigger to automatically update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER update_expenses_updated_at
    BEFORE UPDATE ON public.expenses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
