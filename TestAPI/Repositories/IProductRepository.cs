using TestAPI.Models;

namespace TestAPI.Repositories;

public interface IProductRepository
{
    Task<IEnumerable<int>> GetAllProductIds(CancellationToken cancellationToken = default);
    Task<Product?> GetProductById(int id, CancellationToken cancellationToken = default);
    Task<IEnumerable<Product>> SearchProducts(string searchTerm, CancellationToken cancellationToken = default);
    Task<int> CreateProduct(Product product, CancellationToken cancellationToken = default);
    Task<int> UpdateProduct(Product product, CancellationToken cancellationToken = default);
    Task<int> DeleteProduct(int id, CancellationToken cancellationToken = default);
}
