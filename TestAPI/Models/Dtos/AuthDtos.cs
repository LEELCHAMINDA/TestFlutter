namespace TestAPI.Models.Dtos;

/// <summary>
/// Request object for user login.
/// </summary>
/// <param name="Username">The username or email.</param>
/// <param name="Password">The password.</param>
public record LoginRequest(
    string Username,
    string Password
);

/// <summary>
/// Request object for user registration.
/// </summary>
/// <param name="Username">The username (required, 3-50 characters).</param>
/// <param name="Email">The email address (required, valid format).</param>
/// <param name="Password">The password (required, min 8 characters).</param>
/// <param name="FullName">The full name (optional).</param>
public record RegisterRequest(
    string Username,
    string Email,
    string Password,
    string? FullName
);

/// <summary>
/// Response object for successful authentication.
/// </summary>
/// <param name="Token">The JWT access token.</param>
/// <param name="RefreshToken">The refresh token.</param>
/// <param name="ExpiresAt">When the token expires.</param>
/// <param name="User">The user information.</param>
public record AuthResponse(
    string Token,
    string RefreshToken,
    DateTime ExpiresAt,
    UserResponse User
);

/// <summary>
/// Response object for user information.
/// </summary>
/// <param name="Id">The user identifier.</param>
/// <param name="Username">The username.</param>
/// <param name="Email">The email address.</param>
/// <param name="FullName">The full name.</param>
/// <param name="IsActive">Whether the user is active.</param>
/// <param name="CreatedDate">When the user was created.</param>
public record UserResponse(
    int Id,
    string Username,
    string Email,
    string? FullName,
    bool IsActive,
    DateTime CreatedDate
);
