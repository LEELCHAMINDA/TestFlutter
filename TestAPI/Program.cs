using System.IO.Compression;
using System.Text.Json;
using System.Threading.RateLimiting;
using Asp.Versioning;
using FluentValidation;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.OutputCaching;
using Microsoft.AspNetCore.ResponseCompression;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.IdentityModel.Tokens;
using Serilog;
using TestAPI.Middleware;
using TestAPI.Models.Dtos;
using TestAPI.Repositories;
using TestAPI.Services;
using TestAPI.Validators;

var builder = WebApplication.CreateBuilder(args);

// ── Logging ──────────────────────────────────────────────────────────────
builder.Host.UseSerilog((context, config) =>
    config.ReadFrom.Configuration(context.Configuration)
          .WriteTo.Console()
          .WriteTo.File("logs/api-.log", rollingInterval: RollingInterval.Day));

// ── Authentication (JWT) ─────────────────────────────────────────────────
var jwtKey = builder.Configuration["Jwt:Key"] ?? Environment.GetEnvironmentVariable("JWT_KEY");
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? Environment.GetEnvironmentVariable("JWT_ISSUER");
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? Environment.GetEnvironmentVariable("JWT_AUDIENCE");

// Use default dev key if no key configured (development only)
var signingKey = !string.IsNullOrEmpty(jwtKey)
    ? jwtKey
    : builder.Environment.IsDevelopment()
        ? "dev-only-insecure-key-change-in-production-32chars!"
        : throw new InvalidOperationException("JWT key must be configured in production. Set Jwt:Key or JWT_KEY environment variable.");

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.RequireHttpsMetadata = !builder.Environment.IsDevelopment();
        options.SaveToken = true;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(
                System.Text.Encoding.UTF8.GetBytes(signingKey)),
            ValidateIssuer = !string.IsNullOrEmpty(jwtIssuer),
            ValidIssuer = jwtIssuer,
            ValidateAudience = !string.IsNullOrEmpty(jwtAudience),
            ValidAudience = jwtAudience,
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromMinutes(1)
        };
    });

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("ReadOnly", policy =>
        policy.RequireAuthenticatedUser());
    options.AddPolicy("ReadWrite", policy =>
        policy.RequireAuthenticatedUser());
});

// ── CORS ─────────────────────────────────────────────────────────────────
var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];

builder.Services.AddCors(options =>
{
    options.AddPolicy("ApiCorsPolicy", policy =>
    {
        if (builder.Environment.IsDevelopment())
        {
            policy.SetIsOriginAllowed(origin =>
                {
                    try { return new Uri(origin).Host == "localhost"; }
                    catch { return false; }
                })
                  .WithMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                  .WithHeaders("Content-Type", "Authorization")
                  .WithExposedHeaders("Content-Type", "X-Pagination")
                  .AllowCredentials()
                  .SetPreflightMaxAge(TimeSpan.FromMinutes(10));
        }
        else if (allowedOrigins.Length > 0)
        {
            policy.WithOrigins(allowedOrigins)
                  .WithMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                  .WithHeaders("Content-Type", "Authorization")
                  .WithExposedHeaders("Content-Type", "X-Pagination")
                  .SetPreflightMaxAge(TimeSpan.FromMinutes(10));
        }
        else
        {
            policy.SetIsOriginAllowed(_ => false)
                  .DisallowCredentials();
        }
    });
});

// ── API Versioning ───────────────────────────────────────────────────────
builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = true;
    options.ReportApiVersions = true;
    options.ApiVersionReader = ApiVersionReader.Combine(
        new UrlSegmentApiVersionReader(),
        new HeaderApiVersionReader("X-Api-Version"));
});

// ── Services ─────────────────────────────────────────────────────────────
builder.Services.AddSingleton<IProductMapper, ProductMapper>();
builder.Services.AddSingleton<IJwtTokenService, JwtTokenService>();
builder.Services.AddScoped<IAuthRepository, AuthRepository>();
builder.Services.AddScoped<IProductRepository, ProductRepository>();
builder.Services.AddScoped<IProductService, ProductService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddValidatorsFromAssemblyContaining<CreateProductRequestValidator>();

// ── Response Compression ──────────────────────────────────────────────────
builder.Services.AddResponseCompression(options =>
{
    options.EnableForHttps = true;
    options.Providers.Add<BrotliCompressionProvider>();
    options.Providers.Add<GzipCompressionProvider>();
    options.MimeTypes = ResponseCompressionDefaults.MimeTypes;
});
builder.Services.Configure<BrotliCompressionProviderOptions>(options =>
{
    options.Level = CompressionLevel.Optimal;
});
builder.Services.Configure<GzipCompressionProviderOptions>(options =>
{
    options.Level = CompressionLevel.Optimal;
});

// ── Health Checks ────────────────────────────────────────────────────────
var connectionString = Environment.GetEnvironmentVariable("DB_CONNECTION_STRING")
    ?? builder.Configuration.GetConnectionString("DefaultConnection");

if (!string.IsNullOrEmpty(connectionString))
{
    builder.Services.AddHealthChecks()
        .AddSqlServer(
            connectionString,
            healthQuery: "SELECT 1",
            name: "sqlserver",
            timeout: TimeSpan.FromSeconds(5),
            tags: ["db", "ready"]);
}

// ── Output Cache ─────────────────────────────────────────────────────────
builder.Services.AddOutputCache(options =>
{
    options.AddBasePolicy(policy => policy.Expire(TimeSpan.FromSeconds(30)));
    options.AddPolicy("ProductsCache", policy =>
        policy.Expire(TimeSpan.FromSeconds(30))
              .SetVaryByQuery("pageNumber", "pageSize", "term")
              .SetVaryByHeader("Origin")
              .Tag("products"));
});

// ── Rate Limiting ────────────────────────────────────────────────────────
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

    options.AddFixedWindowLimiter("fixed", opt =>
    {
        opt.PermitLimit = 100;
        opt.Window = TimeSpan.FromMinutes(1);
        opt.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        opt.QueueLimit = 10;
    });

    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
        RateLimitPartition.GetTokenBucketLimiter(
            partitionKey: context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            factory: _ => new TokenBucketRateLimiterOptions
            {
                TokenLimit = 50,
                ReplenishmentPeriod = TimeSpan.FromSeconds(10),
                TokensPerPeriod = 50,
                AutoReplenishment = true,
                QueueLimit = 0
            }));
});

// ── OpenAPI ──────────────────────────────────────────────────────────────
builder.Services.AddOpenApi();

// ── Build App ────────────────────────────────────────────────────────────
var app = builder.Build();

// ── Middleware Pipeline (order matters!) ──────────────────────────────────
app.UseMiddleware<ExceptionMiddleware>();

if (!app.Environment.IsDevelopment())
{
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseResponseCompression();
app.UseCors("ApiCorsPolicy");
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();
app.UseMiddleware<SecurityHeadersMiddleware>();
app.UseOutputCache();

app.MapOpenApi();
app.MapHealthChecks("/health", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";
        var result = new
        {
            status = report.Status.ToString(),
            checks = report.Entries.Select(e => new
            {
                name = e.Key,
                status = e.Value.Status.ToString(),
                duration = e.Value.Duration.TotalMilliseconds,
                description = e.Value.Description
            }),
            totalDuration = report.TotalDuration.TotalMilliseconds
        };
        await context.Response.WriteAsync(JsonSerializer.Serialize(result));
    }
});

// ── Auth Endpoints ───────────────────────────────────────────────────────
var auth = app.MapGroup("/api/v{version:apiVersion}/auth");

auth.MapPost("/login", async (
    LoginRequest request,
    IAuthService authService,
    IValidator<LoginRequest> validator,
    CancellationToken ct) =>
{
    var validationResult = await validator.ValidateAsync(request, ct);
    if (!validationResult.IsValid)
        return Results.ValidationProblem(validationResult.ToDictionary());

    var (response, error) = await authService.LoginAsync(request, ct);
    if (error != null)
        return Results.Json(new { message = error }, statusCode: error == "Account is inactive" ? 403 : 401);

    return Results.Ok(response);
})
.AllowAnonymous()
.WithName("Login");

auth.MapPost("/register", async (
    RegisterRequest request,
    IAuthService authService,
    IValidator<RegisterRequest> validator,
    CancellationToken ct) =>
{
    var validationResult = await validator.ValidateAsync(request, ct);
    if (!validationResult.IsValid)
        return Results.ValidationProblem(validationResult.ToDictionary());

    var (response, error) = await authService.RegisterAsync(request, ct);
    if (error != null)
        return Results.Conflict(new { message = error });

    return Results.Created($"/api/auth/users/{response!.User.Id}", response);
})
.AllowAnonymous()
.WithName("Register");

auth.MapGet("/me", async (
    HttpContext context,
    IAuthService authService) =>
{
    var userResponse = await authService.GetCurrentUserAsync(context.User);
    return userResponse is not null
        ? Results.Ok(userResponse)
        : Results.Unauthorized();
})
.RequireAuthorization()
.WithName("GetCurrentUser");

// ── Endpoints (Versioned) ────────────────────────────────────────────────
var products = app.MapGroup("/api/v{version:apiVersion}/products");

products.MapGet("/", async (
    int pageNumber,
    int pageSize,
    IProductService productService,
    CancellationToken ct) =>
{
    var result = await productService.GetProductsPagedAsync(pageNumber, pageSize, ct);
    return Results.Ok(result);
})
.CacheOutput("ProductsCache")
.AllowAnonymous()
.WithName("GetProducts");

products.MapGet("/{id:int}", async (
    int id,
    IProductService productService) =>
{
    var result = await productService.GetProductByIdAsync(id);
    return result is not null
        ? Results.Ok(result)
        : Results.NotFound();
})
.AllowAnonymous()
.WithName("GetProductById");

products.MapGet("/search", async (
    string term,
    IProductService productService,
    CancellationToken ct) =>
{
    var result = await productService.SearchProductsAsync(term, ct);
    return Results.Ok(result);
})
.AllowAnonymous()
.WithName("SearchProducts");

products.MapPost("/", async (
    CreateProductRequest request,
    IProductService productService,
    IValidator<CreateProductRequest> validator,
    CancellationToken ct) =>
{
    var validationResult = await validator.ValidateAsync(request, ct);
    if (!validationResult.IsValid)
        return Results.ValidationProblem(validationResult.ToDictionary());

    var result = await productService.CreateProductAsync(request, ct);
    return Results.Created($"/api/products/{result.Id}", result);
})
.AllowAnonymous()
.RequireRateLimiting("fixed")
.WithName("CreateProduct");

products.MapPut("/{id:int}", async (
    int id,
    UpdateProductRequest request,
    IProductService productService,
    IValidator<UpdateProductRequest> validator,
    CancellationToken ct) =>
{
    var validationResult = await validator.ValidateAsync(request, ct);
    if (!validationResult.IsValid)
        return Results.ValidationProblem(validationResult.ToDictionary());

    var updated = await productService.UpdateProductAsync(id, request, ct);
    return updated ? Results.NoContent() : Results.NotFound();
})
.AllowAnonymous()
.RequireRateLimiting("fixed")
.WithName("UpdateProduct");

products.MapDelete("/{id:int}", async (
    int id,
    IProductService productService) =>
{
    var deleted = await productService.DeleteProductAsync(id);
    return deleted ? Results.NoContent() : Results.NotFound();
})
.AllowAnonymous()
.RequireRateLimiting("fixed")
.WithName("DeleteProduct");

app.Run();
