-- Search products by name using a sargable prefix search so the
-- IX_Products_Name index can be used (leading wildcard would force a scan).
-- DB column is CreatedAt; aliased to CreatedDate for the C# model.
CREATE OR ALTER PROCEDURE [dbo].[usp_SearchProducts]
    @SearchTerm NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Pattern NVARCHAR(202) = ISNULL(@SearchTerm, '') + '%';

    SELECT Id, Name, Price, Description, Stock, IsActive, CreatedAt AS CreatedDate
    FROM Products
    WHERE IsActive = 1
      AND (@SearchTerm IS NULL OR @SearchTerm = '' OR Name LIKE @Pattern)
    ORDER BY CreatedAt DESC;
END
GO
