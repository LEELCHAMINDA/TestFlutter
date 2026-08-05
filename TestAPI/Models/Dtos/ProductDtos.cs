namespace TestAPI.Models.Dtos;

/// <summary>
/// Generic paged response wrapper for paginated API results.
/// </summary>
/// <typeparam name="T">The type of items in the response.</typeparam>
public class PagedResponse<T>
{
    /// <summary>
    /// Gets or sets the items for the current page.
    /// </summary>
    public IEnumerable<T> Items { get; set; } = [];

    /// <summary>
    /// Gets or sets the current page number.
    /// </summary>
    public int PageNumber { get; set; }

    /// <summary>
    /// Gets or sets the page size.
    /// </summary>
    public int PageSize { get; set; }

    /// <summary>
    /// Gets or sets the total number of items.
    /// </summary>
    public int TotalCount { get; set; }

    /// <summary>
    /// Gets or sets the total number of pages.
    /// </summary>
    public int TotalPages { get; set; }
}

/// <summary>
/// Data transfer object for product responses sent to clients.
/// </summary>
/// <param name="Id">The product identifier.</param>
/// <param name="Name">The product name.</param>
/// <param name="Price">The product price.</param>
/// <param name="Description">The product description.</param>
/// <param name="Stock">The stock quantity.</param>
/// <param name="IsActive">Whether the product is active.</param>
/// <param name="CreatedDate">The creation date.</param>
public record ProductResponse(
    int Id,
    string? Name,
    decimal Price,
    string? Description,
    int Stock,
    bool IsActive,
    DateTime CreatedDate
);

/// <summary>
/// Request object for creating a new product.
/// </summary>
/// <param name="Name">The product name (required, max 200 characters).</param>
/// <param name="Price">The product price (must be >= 0).</param>
/// <param name="Description">The product description.</param>
/// <param name="Stock">The stock quantity (must be >= 0).</param>
/// <param name="IsActive">Whether the product is active.</param>
public record CreateProductRequest(
    string? Name,
    decimal Price,
    string? Description,
    int Stock,
    bool IsActive
);

/// <summary>
/// Request object for updating an existing product.
/// </summary>
/// <param name="Name">The product name (required, max 200 characters).</param>
/// <param name="Price">The product price (must be >= 0).</param>
/// <param name="Description">The product description.</param>
/// <param name="Stock">The stock quantity (must be >= 0).</param>
/// <param name="IsActive">Whether the product is active.</param>
public record UpdateProductRequest(
    string? Name,
    decimal Price,
    string? Description,
    int Stock,
    bool IsActive
);
