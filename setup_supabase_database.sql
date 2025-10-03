-- Database setup for Expense Tracker using Supabase
-- Run this in your Supabase SQL Editor

-- Create users table first (proper user management)
CREATE TABLE IF NOT EXISTS public.users (
    id SERIAL PRIMARY KEY,
    user_name TEXT NOT NULL UNIQUE,
    email TEXT UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create expenses table with proper user relationship
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL,
    date DATE NOT NULL,
    payee TEXT,
    payment_app TEXT,
    transaction_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add user_settings table for budget and preferences
CREATE TABLE IF NOT EXISTS public.user_settings (
    user_id INTEGER PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    monthly_budget DOUBLE PRECISION DEFAULT 25000,
    currency TEXT DEFAULT '₹',
    category_budgets JSONB DEFAULT '{}',
    custom_categories JSONB DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- Create policies for users table
CREATE POLICY "Allow all operations on users" ON public.users
    FOR ALL USING (true) WITH CHECK (true);

-- Create policies for expenses table
CREATE POLICY "Allow all operations on expenses" ON public.expenses
    FOR ALL USING (true) WITH CHECK (true);

-- Create policies for user_settings table
CREATE POLICY "Allow all operations on user_settings" ON public.user_settings
    FOR ALL USING (true) WITH CHECK (true);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_user_name ON public.users(user_name);
CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON public.expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON public.expenses(date);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON public.expenses(category);
CREATE INDEX IF NOT EXISTS idx_expenses_created_at ON public.expenses(created_at);
CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON public.user_settings(user_id);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for automatic timestamp updates
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_expenses_updated_at ON public.expenses;
CREATE TRIGGER update_expenses_updated_at
    BEFORE UPDATE ON public.expenses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_settings_updated_at ON public.user_settings;
CREATE TRIGGER update_user_settings_updated_at
    BEFORE UPDATE ON public.user_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert default user for testing (optional)
INSERT INTO public.users (user_name) 
VALUES ('Default User')
ON CONFLICT (user_name) DO NOTHING;

-- Insert default user settings for the default user
INSERT INTO public.user_settings (user_id, monthly_budget, currency, category_budgets, custom_categories)
SELECT u.id, 25000.00, '₹', '{}', '[]'
FROM public.users u 
WHERE u.user_name = 'Default User'
ON CONFLICT (user_id) DO NOTHING;

-- Grant necessary permissions
GRANT ALL ON public.users TO authenticated;
GRANT ALL ON public.expenses TO authenticated;
GRANT ALL ON public.user_settings TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.users_id_seq TO authenticated;
