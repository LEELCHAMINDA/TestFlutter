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
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>A collection of all products.</returns>
    Task<IEnumerable<Product>> GetAllProducts(CancellationToken cancellationToken = default);

    /// <summary>
    /// Retrieves a single product by its identifier.
    /// </summary>
    /// <param name="id">The product identifier.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The product if found; otherwise, null.</returns>
    Task<Product?> GetProductById(int id, CancellationToken cancellationToken = default);

    /// <summary>
    /// Searches for products matching the specified search term.
    /// </summary>
    /// <param name="searchTerm">The search term to filter products.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>A collection of matching products.</returns>
    Task<IEnumerable<Product>> SearchProducts(string searchTerm, CancellationToken cancellationToken = default);

    /// <summary>
    /// Creates a new product in the database.
    /// </summary>
    /// <param name="product">The product to create.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The identifier of the newly created product.</returns>
    Task<int> CreateProduct(Product product, CancellationToken cancellationToken = default);

    /// <summary>
    /// Updates an existing product in the database.
    /// </summary>
    /// <param name="product">The product with updated values.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The number of rows affected.</returns>
    Task<int> UpdateProduct(Product product, CancellationToken cancellationToken = default);

    /// <summary>
    /// Deletes a product from the database.
    /// </summary>
    /// <param name="id">The identifier of the product to delete.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The number of rows affected.</returns>
    Task<int> DeleteProduct(int id, CancellationToken cancellationToken = default);
}
