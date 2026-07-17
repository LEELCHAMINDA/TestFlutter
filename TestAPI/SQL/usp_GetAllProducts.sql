-- Returns full product records for the active products (newest first).
-- The DB column is CreatedAt; we alias it to CreatedDate to match the
-- C# Product model / ProductResponse DTO property name.
ALTER PROCEDURE [dbo].[usp_GetAllProducts]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Name, Price, Description, Stock, IsActive, CreatedAt AS CreatedDate
    FROM Products
    WHERE IsActive = 1
    ORDER BY CreatedAt DESC;
END
GO
