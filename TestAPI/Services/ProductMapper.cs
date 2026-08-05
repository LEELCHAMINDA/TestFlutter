using TestAPI.Models;
using TestAPI.Models.Dtos;

namespace TestAPI.Services
{
    /// <summary>
    /// Defines the contract for mapping between Product entities and DTOs.
    /// </summary>
    public interface IProductMapper
    {
        /// <summary>
        /// Maps a Product entity to a ProductResponse DTO.
        /// </summary>
        /// <param name="product">The product entity to map.</param>
        /// <returns>The mapped ProductResponse.</returns>
        ProductResponse ToResponse(Product product);

        /// <summary>
        /// Maps a CreateProductRequest to a Product entity.
        /// </summary>
        /// <param name="request">The create request.</param>
        /// <returns>The mapped Product entity.</returns>
        Product ToDomain(CreateProductRequest request);

        /// <summary>
        /// Maps an UpdateProductRequest to a Product entity.
        /// </summary>
        /// <param name="request">The update request.</param>
        /// <param name="id">The product identifier.</param>
        /// <returns>The mapped Product entity.</returns>
        Product ToDomain(UpdateProductRequest request, int id);
    }

    /// <summary>
    /// Maps between Product entities and DTOs.
    /// </summary>
    public class ProductMapper : IProductMapper
    {
        /// <inheritdoc/>
        public ProductResponse ToResponse(Product product)
        {
            return new ProductResponse(
                product.Id,
                product.Name,
                product.Price,
                product.Description,
                product.Stock,
                product.IsActive,
                product.CreatedDate
            );
        }

        /// <inheritdoc/>
        public Product ToDomain(CreateProductRequest request)
        {
            return new Product
            {
                Name = request.Name,
                Price = request.Price,
                Description = request.Description,
                Stock = request.Stock,
                IsActive = request.IsActive,
                CreatedDate = DateTime.UtcNow
            };
        }

        /// <inheritdoc/>
        public Product ToDomain(UpdateProductRequest request, int id)
        {
            return new Product
            {
                Id = id,
                Name = request.Name,
                Price = request.Price,
                Description = request.Description,
                Stock = request.Stock,
                IsActive = request.IsActive
            };
        }
    }
}
