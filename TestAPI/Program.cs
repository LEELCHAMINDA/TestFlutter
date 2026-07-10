using FluentValidation;
using Serilog;
using TestAPI.Middleware;
using TestAPI.Models;
using TestAPI.Models.Dtos;
using TestAPI.Repositories;
using TestAPI.Validators;

var builder = WebApplication.CreateBuilder(args);

builder.Host.UseSerilog((context, config) =>
    config.ReadFrom.Configuration(context.Configuration)
          .WriteTo.Console()
          .WriteTo.File("logs/api-.log", rollingInterval: RollingInterval.Day));

var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>();
builder.Services.AddCors(options =>
{
    options.AddPolicy("ApiCorsPolicy", policy =>
    {
        if (allowedOrigins is { Length: > 0 })
            policy.WithOrigins(allowedOrigins);
        else
            policy.AllowAnyOrigin();
        policy.WithMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
              .WithHeaders("Content-Type", "Authorization");
    });
});

builder.Services.AddScoped<IProductRepository, ProductRepository>();
builder.Services.AddValidatorsFromAssemblyContaining<CreateProductRequestValidator>();

builder.Services.AddHealthChecks()
    .AddSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")!);

builder.Services.AddOpenApi();

var app = builder.Build();

app.UseMiddleware<ExceptionMiddleware>();
app.UseCors("ApiCorsPolicy");

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.MapHealthChecks("/health");

app.MapGet("/api/products", async (IProductRepository repo, CancellationToken ct) =>
{
    var products = await repo.GetAllProducts(ct);
    var response = products.Select(p => new ProductResponse(
        p.Id, p.Name, p.Price, p.Description, p.Stock, p.IsActive, p.CreatedDate));
    return Results.Ok(response);
});

app.MapGet("/api/products/{id}", async (int id, IProductRepository repo, CancellationToken ct) =>
{
    var product = await repo.GetProductById(id, ct);
    return product is not null
        ? Results.Ok(new ProductResponse(product.Id, product.Name, product.Price,
            product.Description, product.Stock, product.IsActive, product.CreatedDate))
        : Results.NotFound();
});

app.MapPost("/api/products", async (CreateProductRequest request,
    IProductRepository repo, IValidator<CreateProductRequest> validator, CancellationToken ct) =>
{
    var validationResult = await validator.ValidateAsync(request, ct);
    if (!validationResult.IsValid)
        return Results.ValidationProblem(validationResult.ToDictionary());

    var product = new Product
    {
        Name = request.Name,
        Price = request.Price,
        Description = request.Description,
        Stock = request.Stock,
        IsActive = request.IsActive
    };

    var newId = await repo.CreateProduct(product, ct);
    return Results.Created($"/api/products/{newId}", new { Id = newId });
});

app.MapPut("/api/products/{id}", async (int id, UpdateProductRequest request,
    IProductRepository repo, IValidator<UpdateProductRequest> validator, CancellationToken ct) =>
{
    var validationResult = await validator.ValidateAsync(request, ct);
    if (!validationResult.IsValid)
        return Results.ValidationProblem(validationResult.ToDictionary());

    var existing = await repo.GetProductById(id, ct);
    if (existing is null)
        return Results.NotFound();

    var product = new Product
    {
        Id = id,
        Name = request.Name,
        Price = request.Price,
        Description = request.Description,
        Stock = request.Stock,
        IsActive = request.IsActive
    };

    await repo.UpdateProduct(product, ct);
    return Results.NoContent();
});

app.MapDelete("/api/products/{id}", async (int id, IProductRepository repo, CancellationToken ct) =>
{
    var existing = await repo.GetProductById(id, ct);
    if (existing is null)
        return Results.NotFound();

    await repo.DeleteProduct(id, ct);
    return Results.NoContent();
});

app.Run();
