CREATE OR ALTER PROCEDURE [dbo].[usp_CreateProduct]
    @Name NVARCHAR(200),
    @Description NVARCHAR(MAX),
    @Price DECIMAL(18,2),
    @Stock INT,
    @IsActive BIT = 1,
    @NewId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Products (Name, Description, Price, Stock, IsActive, CreatedAt, UpdatedAt)
    VALUES (@Name, @Description, @Price, @Stock, @IsActive, GETUTCDATE(), GETUTCDATE());

    SET @NewId = SCOPE_IDENTITY();
END
GO
