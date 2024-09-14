IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'phober_staff')
BEGIN
CREATE DATABASE phober_staff;
END
