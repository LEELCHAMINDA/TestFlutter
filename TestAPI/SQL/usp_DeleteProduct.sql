CREATE OR ALTER PROCEDURE [dbo].[usp_DeleteProduct]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Products WHERE Id = @Id)
        SELECT 0 AS RowsAffected;
    ELSE
    BEGIN
        UPDATE Products
        SET IsActive = 0, UpdatedAt = GETUTCDATE()
        WHERE Id = @Id;

        SELECT 1 AS RowsAffected;
    END
END
GO
