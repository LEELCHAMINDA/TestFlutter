-- usp_GetAllProducts: Returns only Ids of active products
-- usp_GetProductById: Returns full product details by Id

-- Modified SP: Returns only Id column
ALTER PROCEDURE [dbo].[usp_GetAllProducts]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT Id FROM Products
    WHERE IsActive = 1
    ORDER BY CreatedAt DESC;
END
GO
