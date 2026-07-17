using Dapper;
using Microsoft.Data.SqlClient;
using TestAPI.Models;

namespace TestAPI.Repositories;

public class ProductRepository : IProductRepository
{
    private readonly IConfiguration _configuration;

    public ProductRepository(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    private SqlConnection CreateConnection()
    {
        return new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
    }

    public async Task<IEnumerable<Product>> GetAllProducts(CancellationToken cancellationToken = default)
    {
        using var connection = CreateConnection();
        return await connection.QueryAsync<Product>(
            "[usp_GetAllProducts]",
            commandType: System.Data.CommandType.StoredProcedure,
            commandTimeout: 30);
    }

    public async Task<Product?> GetProductById(int id, CancellationToken cancellationToken = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", id);
        return await connection.QueryFirstOrDefaultAsync<Product>(
            "[usp_GetProductById]",
            parameters,
            commandType: System.Data.CommandType.StoredProcedure,
            commandTimeout: 30);
    }

    public async Task<IEnumerable<Product>> SearchProducts(string searchTerm, CancellationToken cancellationToken = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@SearchTerm", searchTerm);
        return await connection.QueryAsync<Product>(
            "[usp_SearchProducts]",
            parameters,
            commandType: System.Data.CommandType.StoredProcedure,
            commandTimeout: 30);
    }

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
            commandTimeout: 30);
        return parameters.Get<int>("@NewId");
    }

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
            commandTimeout: 30);
    }

    public async Task<int> DeleteProduct(int id, CancellationToken cancellationToken = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", id);
        return await connection.ExecuteScalarAsync<int>(
            "[usp_DeleteProduct]",
            parameters,
            commandType: System.Data.CommandType.StoredProcedure,
            commandTimeout: 30);
    }
}
