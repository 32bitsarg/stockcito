-- Script completo para solucionar RLS en Supabase
-- Ejecutar en el SQL Editor de Supabase

-- 1. Verificar estructura actual de la tabla
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'ml_training_data'
ORDER BY ordinal_position;

-- 2. Crear tabla ml_training_data si no existe
CREATE TABLE IF NOT EXISTS ml_training_data (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  data_type TEXT NOT NULL,
  features JSONB NOT NULL,
  target REAL,
  metadata JSONB,
  is_anonymous BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Crear tabla ml_aggregated_data si no existe
CREATE TABLE IF NOT EXISTS ml_aggregated_data (
  id SERIAL PRIMARY KEY,
  data_type TEXT NOT NULL,
  aggregated_features JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Habilitar RLS
ALTER TABLE ml_training_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE ml_aggregated_data ENABLE ROW LEVEL SECURITY;

-- 5. Eliminar políticas existentes
DROP POLICY IF EXISTS "ml_training_data_insert_policy" ON ml_training_data;
DROP POLICY IF EXISTS "ml_training_data_select_policy" ON ml_training_data;
DROP POLICY IF EXISTS "ml_training_data_update_policy" ON ml_training_data;
DROP POLICY IF EXISTS "ml_training_data_delete_policy" ON ml_training_data;
DROP POLICY IF EXISTS "Permitir inserción para usuarios autenticados" ON ml_training_data;
DROP POLICY IF EXISTS "Permitir inserción para usuarios anónimos" ON ml_training_data;
DROP POLICY IF EXISTS "Permitir lectura de datos propios" ON ml_training_data;
DROP POLICY IF EXISTS "Permitir lectura de datos agregados" ON ml_training_data;
DROP POLICY IF EXISTS "Permitir todo temporalmente" ON ml_training_data;

-- 6. Crear políticas RLS correctas para ml_training_data
CREATE POLICY "ml_training_data_insert_authenticated" ON ml_training_data
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid() OR user_id IS NULL);

CREATE POLICY "ml_training_data_insert_anonymous" ON ml_training_data
FOR INSERT
TO anon
WITH CHECK (is_anonymous = true);

CREATE POLICY "ml_training_data_select_authenticated" ON ml_training_data
FOR SELECT
TO authenticated
USING (user_id = auth.uid() OR is_anonymous = true);

CREATE POLICY "ml_training_data_select_anonymous" ON ml_training_data
FOR SELECT
TO anon
USING (is_anonymous = true);

-- 7. Crear políticas RLS para ml_aggregated_data
CREATE POLICY "ml_aggregated_data_insert_all" ON ml_aggregated_data
FOR INSERT
TO authenticated, anon
WITH CHECK (true);

CREATE POLICY "ml_aggregated_data_select_all" ON ml_aggregated_data
FOR SELECT
TO authenticated, anon
USING (true);

-- 8. Verificar que las políticas se crearon correctamente
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE tablename IN ('ml_training_data', 'ml_aggregated_data')
ORDER BY tablename, policyname;
