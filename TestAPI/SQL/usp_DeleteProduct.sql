CREATE OR ALTER PROCEDURE [dbo].[usp_DeleteProduct]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Products
    SET IsActive = 0, UpdatedAt = GETUTCDATE()
    WHERE Id = @Id;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO
