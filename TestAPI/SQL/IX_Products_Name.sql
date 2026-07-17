-- Index on Products.Name to speed up prefix searches (LIKE 'term%').
-- Note: a leading wildcard (LIKE '%term%') cannot use this index; the search
-- stored procedure uses a trailing-only wildcard to stay sargable.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Products_Name' AND object_id = OBJECT_ID('Products'))
    CREATE NONCLUSTERED INDEX IX_Products_Name ON Products (Name) INCLUDE (IsActive);
GO
