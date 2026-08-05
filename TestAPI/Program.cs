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
using TestAPI.Models;
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
        if (allowedOrigins.Length > 0)
        {
            policy.WithOrigins(allowedOrigins)
                  .WithMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                  .WithHeaders("Content-Type", "Authorization")
                  .WithExposedHeaders("Content-Type", "X-Pagination")
                  .SetPreflightMaxAge(TimeSpan.FromMinutes(10));
        }
        else
        {
            // No origins configured — deny all cross-origin requests by not allowing anything
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
    IAuthRepository authRepo,
    IJwtTokenService jwtService,
    IValidator<LoginRequest> validator,
    CancellationToken ct) =>
{
    var validationResult = await validator.ValidateAsync(request, ct);
    if (!validationResult.IsValid)
        return Results.ValidationProblem(validationResult.ToDictionary());

    var user = await authRepo.GetUserByUsernameOrEmailAsync(request.Username);
    if (user == null || !AuthRepository.VerifyPassword(request.Password, user.PasswordHash))
        return Results.Json(
            new { message = "Invalid username or password" },
            statusCode: 401);

    if (!user.IsActive)
        return Results.Json(
            new { message = "Account is inactive" },
            statusCode: 403);

    await authRepo.UpdateLastLoginAsync(user.Id);

    var token = jwtService.GenerateAccessToken(user.Id, user.Username, user.Email);
    var expiresAt = jwtService.GetTokenExpiration();

    return Results.Ok(new AuthResponse(
        Token: token,
        ExpiresAt: expiresAt,
        User: new UserResponse(
            Id: user.Id,
            Username: user.Username,
            Email: user.Email,
            FullName: user.FullName,
            IsActive: user.IsActive,
            CreatedDate: user.CreatedDate)));
})
.AllowAnonymous()
.WithName("Login");

auth.MapPost("/register", async (
    RegisterRequest request,
    IAuthRepository authRepo,
    IJwtTokenService jwtService,
    IValidator<RegisterRequest> validator,
    CancellationToken ct) =>
{
    var validationResult = await validator.ValidateAsync(request, ct);
    if (!validationResult.IsValid)
        return Results.ValidationProblem(validationResult.ToDictionary());

    if (await authRepo.UsernameExistsAsync(request.Username))
        return Results.Conflict(new { message = "Username already exists." });

    if (await authRepo.EmailExistsAsync(request.Email))
        return Results.Conflict(new { message = "Email already exists." });

    var user = new User
    {
        Username = request.Username,
        Email = request.Email,
        PasswordHash = AuthRepository.HashPassword(request.Password),
        FullName = request.FullName,
        IsActive = true
    };

    var createdUser = await authRepo.CreateUserAsync(user);

    var token = jwtService.GenerateAccessToken(createdUser.Id, createdUser.Username, createdUser.Email);
    var expiresAt = jwtService.GetTokenExpiration();

    return Results.Created($"/api/auth/users/{createdUser.Id}", new AuthResponse(
        Token: token,
        ExpiresAt: expiresAt,
        User: new UserResponse(
            Id: createdUser.Id,
            Username: createdUser.Username,
            Email: createdUser.Email,
            FullName: createdUser.FullName,
            IsActive: createdUser.IsActive,
            CreatedDate: createdUser.CreatedDate)));
})
.AllowAnonymous()
.WithName("Register");

auth.MapGet("/me", async (
    HttpContext context,
    IAuthRepository authRepo) =>
{
    var userId = context.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
    if (userId == null || !int.TryParse(userId, out var parsedUserId))
        return Results.Unauthorized();

    var user = await authRepo.GetUserByIdAsync(parsedUserId);
    if (user == null)
        return Results.NotFound();

    return Results.Ok(new UserResponse(
        Id: user.Id,
        Username: user.Username,
        Email: user.Email,
        FullName: user.FullName,
        IsActive: user.IsActive,
        CreatedDate: user.CreatedDate));
})
.RequireAuthorization()
.WithName("GetCurrentUser");

// ── Endpoints (Versioned) ────────────────────────────────────────────────
var products = app.MapGroup("/api/v{version:apiVersion}/products");

products.MapGet("/", async (
    int pageNumber,
    int pageSize,
    IProductRepository repo,
    CancellationToken ct) =>
{
    pageNumber = Math.Max(1, pageNumber);
    pageSize = Math.Clamp(pageSize, 1, 100);

    var (items, totalCount) = await repo.GetProductsPaged(pageNumber, pageSize, ct);
    var paged = items
        .Select(p => new ProductResponse(p.Id, p.Name, p.Price, p.Description, p.Stock, p.IsActive, p.CreatedDate))
        .ToList();

    return Results.Ok(new PagedResponse<ProductResponse>
    {
        Items = paged,
        PageNumber = pageNumber,
        PageSize = pageSize,
        TotalCount = totalCount,
        TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
    });
})
.CacheOutput("ProductsCache")
.AllowAnonymous()
.WithName("GetProducts");

products.MapGet("/{id:int}", async (
    int id,
    IProductMapper mapper,
    IProductRepository repo,
    CancellationToken ct) =>
{
    var product = await repo.GetProductById(id, ct);
    return product is not null
        ? Results.Ok(mapper.ToResponse(product))
        : Results.NotFound();
})
.AllowAnonymous()
.WithName("GetProductById");

products.MapGet("/search", async (
    string term,
    IProductMapper mapper,
    IProductRepository repo,
    CancellationToken ct) =>
{
    var searchResults = await repo.SearchProducts(term, ct);
    var response = searchResults.Select(p => mapper.ToResponse(p)).ToList();
    return Results.Ok(response);
})
.AllowAnonymous()
.WithName("SearchProducts");

products.MapPost("/", async (
    CreateProductRequest request,
    IProductMapper mapper,
    IProductRepository repo,
    IValidator<CreateProductRequest> validator,
    CancellationToken ct) =>
{
    var validationResult = await validator.ValidateAsync(request, ct);
    if (!validationResult.IsValid)
        return Results.ValidationProblem(validationResult.ToDictionary());

    var product = mapper.ToDomain(request);
    var newId = await repo.CreateProduct(product, ct);
    var created = await repo.GetProductById(newId, ct);
    return Results.Created($"/api/products/{newId}", mapper.ToResponse(created!));
})
.AllowAnonymous()
.RequireRateLimiting("fixed")
.WithName("CreateProduct");

products.MapPut("/{id:int}", async (
    int id,
    UpdateProductRequest request,
    IProductMapper mapper,
    IProductRepository repo,
    IValidator<UpdateProductRequest> validator,
    CancellationToken ct) =>
{
    var validationResult = await validator.ValidateAsync(request, ct);
    if (!validationResult.IsValid)
        return Results.ValidationProblem(validationResult.ToDictionary());

    var existing = await repo.GetProductById(id, ct);
    if (existing is null)
        return Results.NotFound();

    var product = mapper.ToDomain(request, id);
    await repo.UpdateProduct(product, ct);
    return Results.NoContent();
})
.AllowAnonymous()
.RequireRateLimiting("fixed")
.WithName("UpdateProduct");

products.MapDelete("/{id:int}", async (
    int id,
    IProductRepository repo,
    CancellationToken ct) =>
{
    var affected = await repo.DeleteProduct(id, ct);
    return affected == 0 ? Results.NotFound() : Results.NoContent();
})
.AllowAnonymous()
.RequireRateLimiting("fixed")
.WithName("DeleteProduct");

app.Run();
