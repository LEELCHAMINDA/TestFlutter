CREATE OR ALTER PROCEDURE [dbo].[usp_GetProductById]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Name,
        Description,
        Price,
        Stock,
        IsActive,
        CreatedAt AS CreatedDate
    FROM Products
    WHERE Id = @Id;
END
GO
