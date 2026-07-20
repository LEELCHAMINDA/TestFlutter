using System.IO.Compression;
using FluentValidation;
using Microsoft.AspNetCore.OutputCaching;
using Microsoft.AspNetCore.ResponseCompression;
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
            policy.SetIsOriginAllowed(_ => true).AllowAnyHeader().AllowAnyMethod();
        policy.WithMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
              .WithHeaders("Content-Type", "Authorization");
        policy.WithExposedHeaders("Content-Type");
        policy.SetPreflightMaxAge(TimeSpan.FromMinutes(10));
    });
});

builder.Services.AddScoped<IProductRepository, ProductRepository>();
builder.Services.AddValidatorsFromAssemblyContaining<CreateProductRequestValidator>();

builder.Services.AddResponseCompression(options =>
{
    options.EnableForHttps = true;
    options.Providers.Add<BrotliCompressionProvider>();
    options.Providers.Add<GzipCompressionProvider>();
    options.MimeTypes = ResponseCompressionDefaults.MimeTypes;
});
builder.Services.Configure<BrotliCompressionProviderOptions>(options =>
{
    options.Level = CompressionLevel.Fastest;
});
builder.Services.Configure<GzipCompressionProviderOptions>(options =>
{
    options.Level = CompressionLevel.Fastest;
});

builder.Services.AddHealthChecks()
    .AddSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")!);

builder.Services.AddOutputCache(options =>
{
    options.AddBasePolicy(policy => policy.Expire(TimeSpan.FromSeconds(30)));
    options.AddPolicy("ProductsCache", policy =>
        policy.Expire(TimeSpan.FromSeconds(30))
              .SetVaryByQuery("pageNumber", "pageSize", "term")
              .SetVaryByHeader("Origin")
              .Tag("products"));
});

builder.Services.AddOpenApi();

var app = builder.Build();

app.UseResponseCompression();
app.UseCors("ApiCorsPolicy");
app.UseOutputCache();
app.UseMiddleware<ExceptionMiddleware>();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.MapHealthChecks("/health");

app.MapGet("/api/products", async (IProductRepository repo, CancellationToken ct) =>
{
    var products = await repo.GetAllProducts(ct);
    var response = products.Select(p => ToResponse(p));
    return Results.Ok(response);
}).CacheOutput("ProductsCache");

app.MapGet("/api/products/{id}", async (int id, IProductRepository repo, CancellationToken ct) =>
{
    var product = await repo.GetProductById(id, ct);
    return product is not null
        ? Results.Ok(ToResponse(product))
        : Results.NotFound();
}).CacheOutput("ProductsCache");

app.MapGet("/api/products/search", async (string term, IProductRepository repo, CancellationToken ct) =>
{
    var products = await repo.SearchProducts(term, ct);
    var response = products.Select(p => ToResponse(p));
    return Results.Ok(response);
}).CacheOutput("ProductsCache");

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

    var product = new Product
    {
        Id = id,
        Name = request.Name,
        Price = request.Price,
        Description = request.Description,
        Stock = request.Stock,
        IsActive = request.IsActive
    };

    var affected = await repo.UpdateProduct(product, ct);
    if (affected == 0)
        return Results.NotFound();

    return Results.NoContent();
});

app.MapDelete("/api/products/{id}", async (int id, IProductRepository repo, CancellationToken ct) =>
{
    var affected = await repo.DeleteProduct(id, ct);
    if (affected == 0)
        return Results.NotFound();

    return Results.NoContent();
});

static ProductResponse ToResponse(Product p) =>
    new(p.Id, p.Name, p.Price, p.Description, p.Stock, p.IsActive, p.CreatedDate);

app.Run();
