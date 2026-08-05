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
    public ProductRepository(IConfiguration configuration)
    {
        _configuration = configuration;
        _commandTimeout = configuration.GetValue<int>("Database:CommandTimeout", 30);
    }

    private SqlConnection CreateConnection()
    {
        var connectionString = Environment.GetEnvironmentVariable("DB_CONNECTION_STRING")
            ?? _configuration.GetConnectionString("DefaultConnection");
        return new SqlConnection(connectionString);
    }

    /// <inheritdoc/>
    public async Task<IEnumerable<Product>> GetAllProducts(CancellationToken cancellationToken = default)
    {
        using var connection = CreateConnection();
        return await connection.QueryAsync<Product>(
            "[usp_GetAllProducts]",
            commandType: System.Data.CommandType.StoredProcedure,
            commandTimeout: _commandTimeout);
    }

    /// <inheritdoc/>
    public async Task<(IEnumerable<Product> Items, int TotalCount)> GetProductsPaged(int pageNumber, int pageSize, CancellationToken cancellationToken = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@PageNumber", pageNumber);
        parameters.Add("@PageSize", pageSize);
        parameters.Add("@TotalCount", dbType: System.Data.DbType.Int32, direction: System.Data.ParameterDirection.Output);

        var items = await connection.QueryAsync<Product>(
            "[usp_GetProductsPaged]",
            parameters,
            commandType: System.Data.CommandType.StoredProcedure,
            commandTimeout: _commandTimeout);

        var totalCount = parameters.Get<int>("@TotalCount");
        return (items, totalCount);
    }

    /// <inheritdoc/>
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

    /// <inheritdoc/>
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

    /// <inheritdoc/>
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

    /// <inheritdoc/>
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

    /// <inheritdoc/>
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
