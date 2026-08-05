using System.Security.Cryptography;
using System.Text;

namespace TestAPI.Repositories;

/// <summary>
/// Interface for user authentication operations.
/// </summary>
public interface IAuthRepository
{
    /// <summary>
    /// Gets a user by username or email.
    /// </summary>
    /// <param name="usernameOrEmail">The username or email.</param>
    /// <returns>The user if found; otherwise, null.</returns>
    Task<Models.User?> GetUserByUsernameOrEmailAsync(string usernameOrEmail);

    /// <summary>
    /// Gets a user by ID.
    /// </summary>
    /// <param name="id">The user identifier.</param>
    /// <returns>The user if found; otherwise, null.</returns>
    Task<Models.User?> GetUserByIdAsync(int id);

    /// <summary>
    /// Creates a new user.
    /// </summary>
    /// <param name="user">The user to create.</param>
    /// <returns>The created user with ID populated.</returns>
    Task<Models.User> CreateUserAsync(Models.User user);

    /// <summary>
    /// Updates the last login date for a user.
    /// </summary>
    /// <param name="userId">The user identifier.</param>
    Task UpdateLastLoginAsync(int userId);

    /// <summary>
    /// Checks if a username already exists.
    /// </summary>
    /// <param name="username">The username to check.</param>
    /// <returns>True if the username exists; otherwise, false.</returns>
    Task<bool> UsernameExistsAsync(string username);

    /// <summary>
    /// Checks if an email already exists.
    /// </summary>
    /// <param name="email">The email to check.</param>
    /// <returns>True if the email exists; otherwise, false.</returns>
    Task<bool> EmailExistsAsync(string email);
}

/// <summary>
/// In-memory user repository for development.
/// Replace with database implementation for production.
/// </summary>
public class AuthRepository : IAuthRepository
{
    private readonly List<Models.User> _users = [];
    private int _nextId = 1;

    /// <summary>
    /// Initializes a new instance of the <see cref="AuthRepository"/> class.
    /// Creates a default admin user for development.
    /// </summary>
    public AuthRepository()
    {
        // Seed a default admin user for development
        _users.Add(new Models.User
        {
            Id = _nextId++,
            Username = "admin",
            Email = "admin@example.com",
            PasswordHash = HashPassword("Admin123!"),
            FullName = "Administrator",
            IsActive = true,
            CreatedDate = DateTime.UtcNow
        });
    }

    /// <inheritdoc/>
    public Task<Models.User?> GetUserByUsernameOrEmailAsync(string usernameOrEmail)
    {
        var user = _users.FirstOrDefault(u =>
            u.Username.Equals(usernameOrEmail, StringComparison.OrdinalIgnoreCase) ||
            u.Email.Equals(usernameOrEmail, StringComparison.OrdinalIgnoreCase));
        return Task.FromResult(user);
    }

    /// <inheritdoc/>
    public Task<Models.User?> GetUserByIdAsync(int id)
    {
        var user = _users.FirstOrDefault(u => u.Id == id);
        return Task.FromResult(user);
    }

    /// <inheritdoc/>
    public Task<Models.User> CreateUserAsync(Models.User user)
    {
        user.Id = _nextId++;
        user.CreatedDate = DateTime.UtcNow;
        _users.Add(user);
        return Task.FromResult(user);
    }

    /// <inheritdoc/>
    public Task UpdateLastLoginAsync(int userId)
    {
        var user = _users.FirstOrDefault(u => u.Id == userId);
        if (user != null)
        {
            user.LastLoginDate = DateTime.UtcNow;
        }
        return Task.CompletedTask;
    }

    /// <inheritdoc/>
    public Task<bool> UsernameExistsAsync(string username)
    {
        var exists = _users.Any(u => u.Username.Equals(username, StringComparison.OrdinalIgnoreCase));
        return Task.FromResult(exists);
    }

    /// <inheritdoc/>
    public Task<bool> EmailExistsAsync(string email)
    {
        var exists = _users.Any(u => u.Email.Equals(email, StringComparison.OrdinalIgnoreCase));
        return Task.FromResult(exists);
    }

    /// <summary>
    /// Hashes a password using SHA256 with salt.
    /// </summary>
    /// <param name="password">The password to hash.</param>
    /// <returns>The hashed password.</returns>
    public static string HashPassword(string password)
    {
        using var sha256 = SHA256.Create();
        var saltedPassword = $"TestAPI_Salt_{password}_2024";
        var bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(saltedPassword));
        return Convert.ToBase64String(bytes);
    }

    /// <summary>
    /// Verifies a password against a hash.
    /// </summary>
    /// <param name="password">The password to verify.</param>
    /// <param name="hash">The hash to verify against.</param>
    /// <returns>True if the password matches; otherwise, false.</returns>
    public static bool VerifyPassword(string password, string hash)
    {
        return HashPassword(password) == hash;
    }
}
