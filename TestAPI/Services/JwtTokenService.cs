using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.IdentityModel.Tokens;

namespace TestAPI.Services;

/// <summary>
/// Interface for JWT token operations.
/// </summary>
public interface IJwtTokenService
{
    /// <summary>
    /// Generates a JWT access token for a user.
    /// </summary>
    /// <param name="userId">The user identifier.</param>
    /// <param name="username">The username.</param>
    /// <param name="email">The email address.</param>
    /// <param name="roles">The user roles.</param>
    /// <returns>The JWT token string.</returns>
    string GenerateAccessToken(int userId, string username, string email, IEnumerable<string>? roles = null);

    /// <summary>
    /// Generates a refresh token.
    /// </summary>
    /// <returns>The refresh token string.</returns>
    string GenerateRefreshToken();

    /// <summary>
    /// Gets the token expiration time.
    /// </summary>
    DateTime GetTokenExpiration();
}

/// <summary>
/// Implementation of JWT token operations.
/// </summary>
public class JwtTokenService : IJwtTokenService
{
    private readonly IConfiguration _configuration;
    private readonly string _secretKey;
    private readonly string _issuer;
    private readonly string _audience;
    private readonly int _expiresInMinutes;

    /// <summary>
    /// Initializes a new instance of the <see cref="JwtTokenService"/> class.
    /// </summary>
    /// <param name="configuration">The configuration instance.</param>
    public JwtTokenService(IConfiguration configuration)
    {
        _configuration = configuration;
        var jwtKey = configuration["Jwt:Key"] ?? Environment.GetEnvironmentVariable("JWT_KEY");

        // Use dev key if not configured (development only)
        _secretKey = !string.IsNullOrWhiteSpace(jwtKey)
            ? jwtKey
            : "dev-only-insecure-key-change-in-production-32chars!";

        _issuer = configuration["Jwt:Issuer"] ?? Environment.GetEnvironmentVariable("JWT_ISSUER") ?? "TestAPI";
        _audience = configuration["Jwt:Audience"] ?? Environment.GetEnvironmentVariable("JWT_AUDIENCE") ?? "TestAPI";
        _expiresInMinutes = configuration.GetValue<int>("Jwt:ExpiresInMinutes", 60);
    }

    /// <inheritdoc/>
    public string GenerateAccessToken(int userId, string username, string email, IEnumerable<string>? roles = null)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_secretKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, userId.ToString()),
            new(ClaimTypes.Name, username),
            new(ClaimTypes.Email, email),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        if (roles != null)
        {
            foreach (var role in roles)
            {
                claims.Add(new Claim(ClaimTypes.Role, role));
            }
        }

        var token = new JwtSecurityToken(
            issuer: _issuer,
            audience: _audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(_expiresInMinutes),
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    /// <inheritdoc/>
    public string GenerateRefreshToken()
    {
        var randomBytes = new byte[64];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomBytes);
        return Convert.ToBase64String(randomBytes);
    }

    /// <inheritdoc/>
    public DateTime GetTokenExpiration()
    {
        return DateTime.UtcNow.AddMinutes(_expiresInMinutes);
    }
}
