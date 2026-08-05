using Dapper;
using Microsoft.Data.SqlClient;
using TestAPI.Models;

namespace TestAPI.Repositories;

/// <summary>
/// Repository for managing Product data access operations using stored procedures.
/// </summary>
public class ProductRepository : IProductRepository
{
    private readonly IConfiguration _configuration;
    private readonly int _commandTimeout;

    /// <summary>
    /// Initializes a new instance of the <see cref="ProductRepository"/> class.
    /// </summary>
    /// <param name="configuration">The configuration instance for accessing connection strings and settings.</param>
    public ProductRepository(IConfiguration configuration)
    {
        _configuration = configuration;
        _commandTimeout = configuration.GetValue<int>("Database:CommandTimeout", 30);
    }

    /// <summary>
    /// Creates a new database connection using the configured connection string.
    /// Connection pooling is handled by ADO.NET based on the connection string settings.
    /// </summary>
    /// <returns>An open <see cref="SqlConnection"/> instance.</returns>
    private SqlConnection CreateConnection()
    {
        var connectionString = Environment.GetEnvironmentVariable("DB_CONNECTION_STRING")
            ?? _configuration.GetConnectionString("DefaultConnection");
        return new SqlConnection(connectionString);
    }

    /// <summary>
    /// Retrieves all products from the database.
    /// </summary>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>A collection of all products.</returns>
    public async Task<IEnumerable<Product>> GetAllProducts(CancellationToken cancellationToken = default)
    {
        using var connection = CreateConnection();
        return await connection.QueryAsync<Product>(
            "[usp_GetAllProducts]",
            commandType: System.Data.CommandType.StoredProcedure,
            commandTimeout: _commandTimeout);
    }

    /// <summary>
    /// Retrieves a single product by its identifier.
    /// </summary>
    /// <param name="id">The product identifier.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The product if found; otherwise, null.</returns>
    public async Task<Product?> GetProductById(int id, CancellationToken cancellationToken = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", id);
        return await connection.QueryFirstOrDefaultAsync<Product>(
            "[usp_GetProductById]",
            parameters,
            commandType: System.Data.CommandType.StoredProcedure,
            commandTimeout: _commandTimeout);
    }

    /// <summary>
    /// Searches for products matching the specified search term.
    /// </summary>
    /// <param name="searchTerm">The search term to filter products.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>A collection of matching products.</returns>
    public async Task<IEnumerable<Product>> SearchProducts(string searchTerm, CancellationToken cancellationToken = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@SearchTerm", searchTerm);
        return await connection.QueryAsync<Product>(
            "[usp_SearchProducts]",
            parameters,
            commandType: System.Data.CommandType.StoredProcedure,
            commandTimeout: _commandTimeout);
    }

    /// <summary>
    /// Creates a new product in the database.
    /// </summary>
    /// <param name="product">The product to create.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The identifier of the newly created product.</returns>
    public async Task<int> CreateProduct(Product product, CancellationToken cancellationToken = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Name", product.Name);
        parameters.Add("@Price", product.Price);
        parameters.Add("@Description", product.Description);
        parameters.Add("@Stock", product.Stock);
        parameters.Add("@NewId", dbType: System.Data.DbType.Int32, direction: System.Data.ParameterDirection.Output);
        await connection.ExecuteAsync(
            "[usp_CreateProduct]",
            parameters,
            commandType: System.Data.CommandType.StoredProcedure,
            commandTimeout: _commandTimeout);
        return parameters.Get<int>("@NewId");
    }

    /// <summary>
    /// Updates an existing product in the database.
    /// </summary>
    /// <param name="product">The product with updated values.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The number of rows affected.</returns>
    public async Task<int> UpdateProduct(Product product, CancellationToken cancellationToken = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", product.Id);
        parameters.Add("@Name", product.Name);
        parameters.Add("@Price", product.Price);
        parameters.Add("@Description", product.Description);
        parameters.Add("@Stock", product.Stock);
        parameters.Add("@IsActive", product.IsActive);
        return await connection.ExecuteScalarAsync<int>(
            "[usp_UpdateProduct]",
            parameters,
            commandType: System.Data.CommandType.StoredProcedure,
            commandTimeout: _commandTimeout);
    }

    /// <summary>
    /// Deletes a product from the database.
    /// </summary>
    /// <param name="id">The identifier of the product to delete.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The number of rows affected.</returns>
    public async Task<int> DeleteProduct(int id, CancellationToken cancellationToken = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", id);
        return await connection.ExecuteScalarAsync<int>(
            "[usp_DeleteProduct]",
            parameters,
            commandType: System.Data.CommandType.StoredProcedure,
            commandTimeout: _commandTimeout);
    }
}
