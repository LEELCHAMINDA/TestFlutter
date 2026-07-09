using TestAPI.Models;
using TestAPI.Repositories;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader();
    });
});

builder.Services.AddScoped<ProductRepository>();

var app = builder.Build();

app.UseCors();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.MapGet("/api/products", async (ProductRepository repo) =>
{
    var products = await repo.GetAllProducts();
    return Results.Ok(products);
});

app.MapGet("/api/products/{id}", async (int id, ProductRepository repo) =>
{
    var product = await repo.GetProductById(id);
    return product is not null ? Results.Ok(product) : Results.NotFound();
});

app.MapPost("/api/products", async (Product product, ProductRepository repo) =>
{
    var result = await repo.CreateProduct(product);
    return Results.Created($"/api/products/{result}", new { Id = result });
});

app.MapPut("/api/products/{id}", async (int id, Product product, ProductRepository repo) =>
{
    product.Id = id;
    await repo.UpdateProduct(product);
    return Results.NoContent();
});

app.MapDelete("/api/products/{id}", async (int id, ProductRepository repo) =>
{
    await repo.DeleteProduct(id);
    return Results.NoContent();
});

app.Run();
