using TestAPI.Models;
using TestAPI.Models.Dtos;
using TestAPI.Repositories;
using TestAPI.Services;

namespace TestAPI.Services;

/// <summary>
/// Interface for product business logic operations.
/// </summary>
public interface IProductService
{
    /// <summary>
    /// Gets a paginated list of products.
    /// </summary>
    Task<PagedResponse<ProductResponse>> GetProductsPagedAsync(int pageNumber, int pageSize, CancellationToken ct = default);

    /// <summary>
    /// Gets a product by ID.
    /// </summary>
    Task<ProductResponse?> GetProductByIdAsync(int id, CancellationToken ct = default);

    /// <summary>
    /// Searches for products.
    /// </summary>
    Task<List<ProductResponse>> SearchProductsAsync(string term, CancellationToken ct = default);

    /// <summary>
    /// Creates a new product.
    /// </summary>
    Task<ProductResponse> CreateProductAsync(CreateProductRequest request, CancellationToken ct = default);

    /// <summary>
    /// Updates an existing product.
    /// </summary>
    Task<bool> UpdateProductAsync(int id, UpdateProductRequest request, CancellationToken ct = default);

    /// <summary>
    /// Deletes a product.
    /// </summary>
    Task<bool> DeleteProductAsync(int id, CancellationToken ct = default);
}

/// <summary>
/// Business logic service for product operations.
/// </summary>
public class ProductService : IProductService
{
    private readonly IProductRepository _repo;
    private readonly IProductMapper _mapper;

    public ProductService(IProductRepository repo, IProductMapper mapper)
    {
        _repo = repo;
        _mapper = mapper;
    }

    /// <inheritdoc/>
    public async Task<PagedResponse<ProductResponse>> GetProductsPagedAsync(int pageNumber, int pageSize, CancellationToken ct = default)
    {
        pageNumber = Math.Max(1, pageNumber);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var (items, totalCount) = await _repo.GetProductsPaged(pageNumber, pageSize, ct);
        var paged = items
            .Select(p => _mapper.ToResponse(p))
            .ToList();

        return new PagedResponse<ProductResponse>
        {
            Items = paged,
            PageNumber = pageNumber,
            PageSize = pageSize,
            TotalCount = totalCount,
            TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
        };
    }

    /// <inheritdoc/>
    public async Task<ProductResponse?> GetProductByIdAsync(int id, CancellationToken ct = default)
    {
        var product = await _repo.GetProductById(id, ct);
        return product is not null ? _mapper.ToResponse(product) : null;
    }

    /// <inheritdoc/>
    public async Task<List<ProductResponse>> SearchProductsAsync(string term, CancellationToken ct = default)
    {
        var searchResults = await _repo.SearchProducts(term, ct);
        return searchResults.Select(p => _mapper.ToResponse(p)).ToList();
    }

    /// <inheritdoc/>
    public async Task<ProductResponse> CreateProductAsync(CreateProductRequest request, CancellationToken ct = default)
    {
        var product = _mapper.ToDomain(request);
        var newId = await _repo.CreateProduct(product, ct);
        var created = await _repo.GetProductById(newId, ct);
        return _mapper.ToResponse(created!);
    }

    /// <inheritdoc/>
    public async Task<bool> UpdateProductAsync(int id, UpdateProductRequest request, CancellationToken ct = default)
    {
        var existing = await _repo.GetProductById(id, ct);
        if (existing is null) return false;

        var product = _mapper.ToDomain(request, id);
        await _repo.UpdateProduct(product, ct);
        return true;
    }

    /// <inheritdoc/>
    public async Task<bool> DeleteProductAsync(int id, CancellationToken ct = default)
    {
        var affected = await _repo.DeleteProduct(id, ct);
        return affected > 0;
    }
}
