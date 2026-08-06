using System.Security.Claims;
using TestAPI.Models;
using TestAPI.Models.Dtos;
using TestAPI.Repositories;

namespace TestAPI.Services;

/// <summary>
/// Interface for authentication business logic operations.
/// </summary>
public interface IAuthService
{
    /// <summary>
    /// Authenticates a user and returns an auth response.
    /// </summary>
    Task<(AuthResponse Response, string? Error)> LoginAsync(LoginRequest request, CancellationToken ct = default);

    /// <summary>
    /// Registers a new user.
    /// </summary>
    Task<(AuthResponse? Response, string? Error)> RegisterAsync(RegisterRequest request, CancellationToken ct = default);

    /// <summary>
    /// Gets the current user from claims.
    /// </summary>
    Task<UserResponse?> GetCurrentUserAsync(ClaimsPrincipal user, CancellationToken ct = default);
}

/// <summary>
/// Business logic service for authentication operations.
/// </summary>
public class AuthService : IAuthService
{
    private readonly IAuthRepository _authRepo;
    private readonly IJwtTokenService _jwtService;

    public AuthService(IAuthRepository authRepo, IJwtTokenService jwtService)
    {
        _authRepo = authRepo;
        _jwtService = jwtService;
    }

    /// <inheritdoc/>
    public async Task<(AuthResponse Response, string? Error)> LoginAsync(LoginRequest request, CancellationToken ct = default)
    {
        var user = await _authRepo.GetUserByUsernameOrEmailAsync(request.Username);
        if (user == null || !AuthRepository.VerifyPassword(request.Password, user.PasswordHash))
            return (null!, "Invalid username or password");

        if (!user.IsActive)
            return (null!, "Account is inactive");

        await _authRepo.UpdateLastLoginAsync(user.Id);

        var token = _jwtService.GenerateAccessToken(user.Id, user.Username, user.Email);
        var expiresAt = _jwtService.GetTokenExpiration();

        var response = new AuthResponse(
            Token: token,
            ExpiresAt: expiresAt,
            User: new UserResponse(
                Id: user.Id,
                Username: user.Username,
                Email: user.Email,
                FullName: user.FullName,
                IsActive: user.IsActive,
                CreatedDate: user.CreatedDate));

        return (response, null);
    }

    /// <inheritdoc/>
    public async Task<(AuthResponse? Response, string? Error)> RegisterAsync(RegisterRequest request, CancellationToken ct = default)
    {
        if (await _authRepo.UsernameExistsAsync(request.Username))
            return (null, "Username already exists.");

        if (await _authRepo.EmailExistsAsync(request.Email))
            return (null, "Email already exists.");

        var user = new User
        {
            Username = request.Username,
            Email = request.Email,
            PasswordHash = AuthRepository.HashPassword(request.Password),
            FullName = request.FullName,
            IsActive = true
        };

        var createdUser = await _authRepo.CreateUserAsync(user);

        var token = _jwtService.GenerateAccessToken(createdUser.Id, createdUser.Username, createdUser.Email);
        var expiresAt = _jwtService.GetTokenExpiration();

        var response = new AuthResponse(
            Token: token,
            ExpiresAt: expiresAt,
            User: new UserResponse(
                Id: createdUser.Id,
                Username: createdUser.Username,
                Email: createdUser.Email,
                FullName: createdUser.FullName,
                IsActive: createdUser.IsActive,
                CreatedDate: createdUser.CreatedDate));

        return (response, null);
    }

    /// <inheritdoc/>
    public async Task<UserResponse?> GetCurrentUserAsync(ClaimsPrincipal principal, CancellationToken ct = default)
    {
        var userId = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null || !int.TryParse(userId, out var parsedUserId))
            return null;

        var user = await _authRepo.GetUserByIdAsync(parsedUserId);
        if (user == null) return null;

        return new UserResponse(
            Id: user.Id,
            Username: user.Username,
            Email: user.Email,
            FullName: user.FullName,
            IsActive: user.IsActive,
            CreatedDate: user.CreatedDate);
    }
}
