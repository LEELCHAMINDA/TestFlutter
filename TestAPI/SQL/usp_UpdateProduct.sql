CREATE OR ALTER PROCEDURE [dbo].[usp_UpdateProduct]
    @Id INT,
    @Name NVARCHAR(200),
    @Description NVARCHAR(MAX),
    @Price DECIMAL(18,2),
    @Stock INT,
    @IsActive BIT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Products
    SET
        Name = @Name,
        Description = @Description,
        Price = @Price,
        Stock = @Stock,
        IsActive = @IsActive,
        UpdatedAt = GETUTCDATE()
    WHERE Id = @Id;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO
