namespace TestAPI.Models.Dtos;

public record ProductResponse(
    int Id,
    string? Name,
    decimal Price,
    string? Description,
    int Stock,
    bool IsActive,
    DateTime CreatedDate
);

public record CreateProductRequest(
    string? Name,
    decimal Price,
    string? Description,
    int Stock,
    bool IsActive
);

public record UpdateProductRequest(
    string? Name,
    decimal Price,
    string? Description,
    int Stock,
    bool IsActive
);
