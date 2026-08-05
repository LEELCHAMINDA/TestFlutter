namespace TestAPI.Models.Dtos;

/// <summary>
/// Request object for user login.
/// </summary>
public record LoginRequest(
    string Username,
    string Password
);

/// <summary>
/// Request object for user registration.
/// </summary>
public record RegisterRequest(
    string Username,
    string Email,
    string Password,
    string? FullName
);

/// <summary>
/// Response object for successful authentication.
/// </summary>
public record AuthResponse(
    string Token,
    DateTime ExpiresAt,
    UserResponse User
);

/// <summary>
/// Response object for user information.
/// </summary>
public record UserResponse(
    int Id,
    string Username,
    string Email,
    string? FullName,
    bool IsActive,
    DateTime CreatedDate
);
