using TestAPI.Models;

namespace TestAPI.Repositories;

/// <summary>
/// Defines the contract for Product data access operations.
/// </summary>
public interface IProductRepository
{
    /// <summary>
    /// Retrieves all products from the database.
    /// </summary>
    Task<IEnumerable<Product>> GetAllProducts(CancellationToken cancellationToken = default);

    /// <summary>
    /// Retrieves a page of products from the database.
    /// </summary>
    /// <param name="pageNumber">The page number (1-based).</param>
    /// <param name="pageSize">The number of items per page.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>A tuple of products and total count.</returns>
    Task<(IEnumerable<Product> Items, int TotalCount)> GetProductsPaged(int pageNumber, int pageSize, CancellationToken cancellationToken = default);

    /// <summary>
    /// Retrieves a single product by its identifier.
    /// </summary>
    Task<Product?> GetProductById(int id, CancellationToken cancellationToken = default);

    /// <summary>
    /// Searches for products matching the specified search term.
    /// </summary>
    Task<IEnumerable<Product>> SearchProducts(string searchTerm, CancellationToken cancellationToken = default);

    /// <summary>
    /// Creates a new product in the database.
    /// </summary>
    Task<int> CreateProduct(Product product, CancellationToken cancellationToken = default);

    /// <summary>
    /// Updates an existing product in the database.
    /// </summary>
    Task<int> UpdateProduct(Product product, CancellationToken cancellationToken = default);

    /// <summary>
    /// Deletes a product from the database.
    /// </summary>
    Task<int> DeleteProduct(int id, CancellationToken cancellationToken = default);
}
